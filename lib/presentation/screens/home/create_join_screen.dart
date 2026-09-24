import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/di/providers.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/utils/extensions.dart';
import '../../viewmodels/home_viewmodel.dart';
import '../../widgets/animated_living_background.dart';
import '../../widgets/custom_button.dart';

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
      context.showErrorSnackBar('Enter your name');
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
      context.showErrorSnackBar('Name and room code required');
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
    final raw = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue;
    if (raw == null) return;
    final match = RegExp(r'join/([A-Z0-9]+)', caseSensitive: false)
        .firstMatch(raw);
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

    return Scaffold(
      body: AnimatedLivingBackground(
        child: SafeArea(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Text('Create / Join', style: AppTextStyles.heading2()),
                  ],
                ),
                TextField(
                  controller: _nameCtrl,
                  style: AppTextStyles.bodyLarge(),
                  decoration: const InputDecoration(
                    labelText: 'Your name',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                AppSpacing.gapVMd,
                TabBar(
                  controller: _tabs,
                  tabs: const [
                    Tab(text: 'CREATE ROOM'),
                    Tab(text: 'JOIN ROOM'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      Column(
                        children: [
                          AppSpacing.gapVLg,
                          Text(
                            'Exactly 4 players · Hotspot or Online',
                            style: AppTextStyles.bodyMedium(),
                          ),
                          AppSpacing.gapVLg,
                          CustomButton(
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
                            style: AppTextStyles.heading2(),
                            decoration: const InputDecoration(
                              labelText: 'Room code',
                              labelStyle: TextStyle(color: Colors.white70),
                            ),
                          ),
                          AppSpacing.gapVMd,
                          CustomButton(
                            label: 'JOIN ROOM',
                            onPressed: homeState.isLoading ? null : () => _join(),
                            isLoading: homeState.isLoading,
                          ),
                          AppSpacing.gapVMd,
                          CustomButton(
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
                    style: AppTextStyles.bodyMedium(color: Colors.redAccent),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
