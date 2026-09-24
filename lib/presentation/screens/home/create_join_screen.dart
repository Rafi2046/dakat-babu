import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/di/providers.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/extensions.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/cpdb/cpdb.dart';

/// Create / Join room with code + QR scanner.
class CreateJoinScreen extends ConsumerStatefulWidget {
  const CreateJoinScreen({super.key});

  @override
  ConsumerState<CreateJoinScreen> createState() => _CreateJoinScreenState();
}

class _CreateJoinScreenState extends ConsumerState<CreateJoinScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    final profile = ref.read(playerProfileStoreProvider);
    _nameCtrl.text = profile.playerName == 'Player' ? '' : profile.playerName;
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      AppToast.show(context, 'Enter your name', error: true);
      return;
    }
    await ref.read(playerProfileStoreProvider).setPlayerName(name);
    final room = await ref.read(homeViewModelProvider.notifier).createRoom(
          name,
          maxPlayers: AppConstants.maxPlayers,
          rolePreset: 'chor_police_dakat_babu',
        );
    if (room != null && mounted) {
      context.go(AppRoutes.lobbyPath(room.roomCode));
    }
  }

  Future<void> _join([String? code]) async {
    final name = _nameCtrl.text.trim();
    final roomCode = (code ?? _codeCtrl.text).cleanRoomCode;
    if (name.isEmpty || roomCode.isEmpty) {
      AppToast.show(context, 'Name and room code required', error: true);
      return;
    }
    await ref.read(playerProfileStoreProvider).setPlayerName(name);
    final player = await ref
        .read(homeViewModelProvider.notifier)
        .joinRoom(roomCode: roomCode, playerName: name);
    if (player != null && mounted) {
      context.go(AppRoutes.lobbyPath(roomCode));
    }
  }

  void _onQrDetect(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;
    final match =
        RegExp(r'join/([A-Z0-9]+)', caseSensitive: false).firstMatch(raw);
    final code = match?.group(1) ?? raw.cleanRoomCode;
    if (code.length >= 4) {
      setState(() => _scanning = false);
      _codeCtrl.text = code;
      _join(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);

    return AppShell(
      padding: EdgeInsets.zero,
      topBar: TopBar(
        title: 'Create / Join',
        onBack: () => context.pop(),
        showProfile: false,
      ),
      body: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Your name'),
            ),
            AppSpacing.gapVMd,
            TabBar(
              controller: _tabs,
              tabs: const [
                Tab(text: 'CREATE'),
                Tab(text: 'JOIN'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabs,
                children: [
                  Column(
                    children: [
                      AppSpacing.gapVLg,
                      const Text('Exactly 4 players · Hotspot or Online'),
                      AppSpacing.gapVLg,
                      GameButton(
                        label: 'CREATE ROOM',
                        onPressed: homeState.isLoading ? null : _create,
                        isLoading: homeState.isLoading,
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      AppSpacing.gapVLg,
                      TextField(
                        controller: _codeCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration:
                            const InputDecoration(labelText: 'Room code'),
                      ),
                      AppSpacing.gapVMd,
                      GameButton(
                        label: 'JOIN ROOM',
                        onPressed:
                            homeState.isLoading ? null : () => _join(),
                        isLoading: homeState.isLoading,
                      ),
                      AppSpacing.gapVMd,
                      GameButton(
                        label: _scanning ? 'CLOSE SCANNER' : 'SCAN QR',
                        onPressed: () =>
                            setState(() => _scanning = !_scanning),
                        variant: ButtonVariant.outlined,
                      ),
                      if (_scanning)
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: MobileScanner(onDetect: _onQrDetect),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (homeState.errorMessage != null)
              Text(
                homeState.errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
          ],
        ),
      ),
    );
  }
}
