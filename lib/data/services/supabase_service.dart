import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';

/// Low-level wrapper around the Supabase SDK providing database queries,
/// realtime subscriptions, and safe in-memory fallback for local development.
class SupabaseService {
  SupabaseClient? _client;
  bool _isConfigured = false;

  /// Whether Supabase credentials have been configured with a valid cloud URL.
  bool get isConfigured => _isConfigured;

  /// Current authenticated user ID (null if not logged in).
  String? get currentUserId => _client?.auth.currentUser?.id;

  /// Underlying [SupabaseClient] instance.
  SupabaseClient get client {
    if (_client == null) {
      throw const AppException('Supabase client has not been initialized');
    }
    return _client!;
  }

  /// Returns the current anonymous user ID, or signs in anonymously if needed.
  Future<String> getOrSignInAnonymousUserId() async {
    if (!_isConfigured || _client == null) {
      return 'anon_${DateTime.now().millisecondsSinceEpoch}';
    }

    var user = _client!.auth.currentUser;
    if (user == null) {
      try {
        final res = await _client!.auth.signInAnonymously();
        user = res.user;
        debugPrint('✅ [SupabaseService] Signed in anonymously as ${user?.id}');
      } catch (e) {
        debugPrint('⚠️ [SupabaseService] Anonymous sign-in attempt: $e');
      }
    }
    return user?.id ?? 'anon_${DateTime.now().millisecondsSinceEpoch}';
  }

  // --- In-Memory Mock Fallback for local testing without credentials ---
  final Map<String, Map<String, dynamic>> _mockRooms = {};
  final Map<String, List<Map<String, dynamic>>> _mockPlayers = {};
  final Map<String, Map<String, dynamic>> _mockRounds = {};
  final _roomStreamControllers = <String, StreamController<Map<String, dynamic>?> >{};
  final _playerStreamControllers = <String, StreamController<List<Map<String, dynamic>>> >{};
  final _roundStreamControllers = <String, StreamController<Map<String, dynamic>?> >{};

  /// Initializes the Supabase client connection.
  Future<void> initialize({
    String? url,
    String? anonKey,
  }) async {
    final effectiveUrl = AppConstants.cleanSupabaseUrl;
    final effectiveKey = anonKey ?? AppConstants.supabaseAnonKey;
    final isPlaceholder = effectiveUrl.contains('placeholder') || effectiveKey.contains('placeholder');

    if (isPlaceholder) {
      debugPrint(
        '⚠️ [SupabaseService] Running with placeholder credentials. '
        'Using in-memory realtime mock mode.',
      );
      _isConfigured = false;
      return;
    }

    try {
      await Supabase.initialize(
        url: effectiveUrl,
        // ignore: deprecated_member_use
        anonKey: effectiveKey,
        debug: kDebugMode,
      );
      _client = Supabase.instance.client;
      _isConfigured = true;
      debugPrint('✅ [SupabaseService] Connected successfully to $effectiveUrl');

      // Attempt anonymous sign-in if no active session
      if (_client?.auth.currentUser == null) {
        try {
          await _client!.auth.signInAnonymously();
          debugPrint('✅ [SupabaseService] Anonymous session active: ${_client!.auth.currentUser?.id}');
        } catch (authError) {
          debugPrint('ℹ️ [SupabaseService] Anonymous auth note: $authError');
        }
      }
    } catch (e, stack) {
      debugPrint('❌ [SupabaseService] Failed to initialize Supabase: $e\n$stack');
      _isConfigured = false;
    }
  }

  // --- Realtime Streams ---

  /// Streams realtime updates for a specific room.
  Stream<Map<String, dynamic>?> streamRoom(String roomCode) {
    if (!_isConfigured || _client == null) {
      _roomStreamControllers.putIfAbsent(
        roomCode,
        () => StreamController<Map<String, dynamic>?>.broadcast(),
      );
      // Emit current mock state immediately
      Timer.run(() {
        if (!_roomStreamControllers[roomCode]!.isClosed) {
          _roomStreamControllers[roomCode]!.add(_mockRooms[roomCode]);
        }
      });
      return _roomStreamControllers[roomCode]!.stream;
    }

    try {
      return _client!
          .from(AppConstants.roomsTable)
          .stream(primaryKey: ['id'])
          .eq('room_code', roomCode)
          .map((data) => data.isNotEmpty ? data.first : null);
    } catch (e) {
      throw ServerFailure('Failed to subscribe to room updates: $e');
    }
  }

  /// Streams the list of players currently joined in a room.
  Stream<List<Map<String, dynamic>>> streamPlayers(String roomCode) {
    if (!_isConfigured || _client == null) {
      _playerStreamControllers.putIfAbsent(
        roomCode,
        () => StreamController<List<Map<String, dynamic>>>.broadcast(),
      );
      Timer.run(() {
        if (!_playerStreamControllers[roomCode]!.isClosed) {
          _playerStreamControllers[roomCode]!.add(_mockPlayers[roomCode] ?? []);
        }
      });
      return _playerStreamControllers[roomCode]!.stream;
    }

    try {
      return _client!
          .from(AppConstants.playersTable)
          .stream(primaryKey: ['id'])
          .eq('room_code', roomCode)
          .order('created_at', ascending: true);
    } catch (e) {
      throw ServerFailure('Failed to subscribe to players updates: $e');
    }
  }

  /// Streams the current round for a room.
  Stream<Map<String, dynamic>?> streamCurrentRound(String roomCode) {
    if (!_isConfigured || _client == null) {
      _roundStreamControllers.putIfAbsent(
        roomCode,
        () => StreamController<Map<String, dynamic>?>.broadcast(),
      );
      Timer.run(() {
        if (!_roundStreamControllers[roomCode]!.isClosed) {
          _roundStreamControllers[roomCode]!.add(_mockRounds[roomCode]);
        }
      });
      return _roundStreamControllers[roomCode]!.stream;
    }

    try {
      return _client!
          .from(AppConstants.roundsTable)
          .stream(primaryKey: ['id'])
          .eq('room_code', roomCode)
          .order('round_number', ascending: false)
          .limit(1)
          .map((data) => data.isNotEmpty ? data.first : null);
    } catch (e) {
      throw ServerFailure('Failed to subscribe to round updates: $e');
    }
  }

  // --- CRUD Operations ---

  /// Inserts a row into the specified [table].
  Future<Map<String, dynamic>> insert(String table, Map<String, dynamic> values) async {
    if (!_isConfigured || _client == null) {
      return _mockInsert(table, values);
    }

    try {
      final response = await _client!.from(table).insert(values).select().single();
      return response;
    } catch (e) {
      throw ServerFailure('Insert failed on table $table: $e');
    }
  }

  /// Updates rows in [table] matching the given [matchField] and [matchValue].
  Future<void> update(
    String table, {
    required String matchField,
    required dynamic matchValue,
    required Map<String, dynamic> values,
  }) async {
    if (!_isConfigured || _client == null) {
      _mockUpdate(table, matchField: matchField, matchValue: matchValue, values: values);
      return;
    }

    try {
      await _client!.from(table).update(values).eq(matchField, matchValue);
    } catch (e) {
      throw ServerFailure('Update failed on table $table: $e');
    }
  }

  /// Fetches a single row from [table] by a column match.
  Future<Map<String, dynamic>?> fetchSingle(
    String table, {
    required String matchField,
    required dynamic matchValue,
  }) async {
    if (!_isConfigured || _client == null) {
      return _mockFetchSingle(table, matchField: matchField, matchValue: matchValue);
    }

    try {
      final response = await _client!
          .from(table)
          .select()
          .eq(matchField, matchValue)
          .maybeSingle();
      return response;
    } catch (e) {
      throw ServerFailure('Query failed on table $table: $e');
    }
  }

  /// Fetches multiple rows from [table] by a column match.
  Future<List<Map<String, dynamic>>> fetchList(
    String table, {
    required String matchField,
    required dynamic matchValue,
  }) async {
    if (!_isConfigured || _client == null) {
      return _mockFetchList(table, matchField: matchField, matchValue: matchValue);
    }

    try {
      final response = await _client!.from(table).select().eq(matchField, matchValue);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw ServerFailure('List query failed on table $table: $e');
    }
  }

  /// Deletes rows from [table] matching the given [matchField] and [matchValue].
  Future<void> delete(
    String table, {
    required String matchField,
    required dynamic matchValue,
  }) async {
    if (!_isConfigured || _client == null) {
      _mockDelete(table, matchField: matchField, matchValue: matchValue);
      return;
    }

    try {
      await _client!.from(table).delete().eq(matchField, matchValue);
    } catch (e) {
      throw ServerFailure('Delete failed on table $table: $e');
    }
  }

  // --- Private Mock Implementation Helpers ---
  Map<String, dynamic> _mockInsert(String table, Map<String, dynamic> values) {
    final record = Map<String, dynamic>.from(values);
    final roomCode = record['room_code'] as String? ?? '';

    if (table == AppConstants.roomsTable) {
      _mockRooms[roomCode] = record;
      _roomStreamControllers[roomCode]?.add(record);
    } else if (table == AppConstants.playersTable) {
      final players = _mockPlayers.putIfAbsent(roomCode, () => []);
      players.add(record);
      _playerStreamControllers[roomCode]?.add(List.from(players));
    } else if (table == AppConstants.roundsTable) {
      _mockRounds[roomCode] = record;
      _roundStreamControllers[roomCode]?.add(record);
    }
    return record;
  }

  void _mockUpdate(
    String table, {
    required String matchField,
    required dynamic matchValue,
    required Map<String, dynamic> values,
  }) {
    if (table == AppConstants.roomsTable) {
      for (final roomCode in _mockRooms.keys) {
        if (_mockRooms[roomCode]?[matchField] == matchValue) {
          _mockRooms[roomCode]!.addAll(values);
          _roomStreamControllers[roomCode]?.add(_mockRooms[roomCode]);
        }
      }
    } else if (table == AppConstants.playersTable) {
      for (final roomCode in _mockPlayers.keys) {
        final players = _mockPlayers[roomCode] ?? [];
        for (var i = 0; i < players.length; i++) {
          if (players[i][matchField] == matchValue) {
            players[i].addAll(values);
          }
        }
        _playerStreamControllers[roomCode]?.add(List.from(players));
      }
    } else if (table == AppConstants.roundsTable) {
      for (final roomCode in _mockRounds.keys) {
        if (_mockRounds[roomCode]?[matchField] == matchValue) {
          _mockRounds[roomCode]!.addAll(values);
          _roundStreamControllers[roomCode]?.add(_mockRounds[roomCode]);
        }
      }
    }
  }

  Map<String, dynamic>? _mockFetchSingle(
    String table, {
    required String matchField,
    required dynamic matchValue,
  }) {
    if (table == AppConstants.roomsTable) {
      for (final room in _mockRooms.values) {
        if (room[matchField] == matchValue) return room;
      }
    } else if (table == AppConstants.roundsTable) {
      for (final round in _mockRounds.values) {
        if (round[matchField] == matchValue) return round;
      }
    } else if (table == AppConstants.playersTable) {
      for (final players in _mockPlayers.values) {
        for (final p in players) {
          if (p[matchField] == matchValue) return p;
        }
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _mockFetchList(
    String table, {
    required String matchField,
    required dynamic matchValue,
  }) {
    if (table == AppConstants.playersTable) {
      final list = <Map<String, dynamic>>[];
      for (final players in _mockPlayers.values) {
        for (final p in players) {
          if (p[matchField] == matchValue) list.add(p);
        }
      }
      return list;
    }
    return [];
  }

  void _mockDelete(
    String table, {
    required String matchField,
    required dynamic matchValue,
  }) {
    if (table == AppConstants.roomsTable) {
      for (final roomCode in List<String>.from(_mockRooms.keys)) {
        if (_mockRooms[roomCode]?[matchField] == matchValue) {
          _mockRooms.remove(roomCode);
          _roomStreamControllers[roomCode]?.add(null);
        }
      }
    } else if (table == AppConstants.playersTable) {
      for (final roomCode in _mockPlayers.keys) {
        final players = _mockPlayers[roomCode] ?? [];
        players.removeWhere((p) => p[matchField] == matchValue);
        _playerStreamControllers[roomCode]?.add(List.from(players));
      }
    } else if (table == AppConstants.roundsTable) {
      for (final roomCode in List<String>.from(_mockRounds.keys)) {
        if (_mockRounds[roomCode]?[matchField] == matchValue) {
          _mockRounds.remove(roomCode);
          _roundStreamControllers[roomCode]?.add(null);
        }
      }
    }
  }
}
