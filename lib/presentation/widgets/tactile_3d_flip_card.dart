import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/extensions.dart';
import '../../domain/game/game_role.dart';

/// Premium tactile 3D Y-axis flip card for role reveal gameplay.
///
/// Revealed state can be driven by Riverpod via [revealedProvider], or kept
/// local when the provider is omitted. Callers never load audio assets here —
/// flips emit [AudioEvent.roleCardFlip] through [AudioManager].
class Tactile3DFlipCard extends ConsumerStatefulWidget {
  /// Role shown on the revealed face. Null keeps the front face placeholder.
  final GameRole? role;

  /// When set, revealed state is read/written through Riverpod.
  final StateProvider<bool>? revealedProvider;

  /// Controlled mode (used when [revealedProvider] is null).
  final bool? isRevealed;

  /// Called after a successful flip settles (controlled or provider mode).
  final ValueChanged<bool>? onRevealChanged;

  /// Optional custom back (unrevealed) face.
  final Widget? backFace;

  /// Optional custom front (revealed) face. Defaults to role art + label.
  final Widget? frontFace;

  final double width;
  final double height;
  final Duration duration;
  final bool playFlipSound;

  /// When false, the card ignores taps (parent drives [isRevealed]).
  final bool enableTap;

  const Tactile3DFlipCard({
    super.key,
    this.role,
    this.revealedProvider,
    this.isRevealed,
    this.onRevealChanged,
    this.backFace,
    this.frontFace,
    this.width = 220,
    this.height = 320,
    this.duration = const Duration(milliseconds: 400),
    this.playFlipSound = true,
    this.enableTap = true,
  });

  @override
  ConsumerState<Tactile3DFlipCard> createState() => _Tactile3DFlipCardState();
}

class _Tactile3DFlipCardState extends ConsumerState<Tactile3DFlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _flip;

  bool _isAnimating = false;
  bool _localRevealed = false;

  bool get _revealed {
    final provider = widget.revealedProvider;
    if (provider != null) return ref.watch(provider);
    return widget.isRevealed ?? _localRevealed;
  }

  @override
  void initState() {
    super.initState();
    _localRevealed = widget.isRevealed ?? false;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _flip = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    _controller.value = _revealed ? 1.0 : 0.0;

    _controller.addStatusListener(_onStatus);
  }

  @override
  void didUpdateWidget(covariant Tactile3DFlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    // Drive flip whenever controlled [isRevealed] changes — even mid-animation.
    if (widget.revealedProvider == null &&
        widget.isRevealed != null &&
        widget.isRevealed != oldWidget.isRevealed) {
      _syncTo(widget.isRevealed!);
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      HapticFeedback.heavyImpact();
      if (mounted) setState(() => _isAnimating = false);
    }
  }

  void _syncTo(bool revealed) {
    if (!mounted) return;
    if (revealed && widget.playFlipSound) {
      ref.read(audioManagerProvider).play(AudioEvent.roleCardFlip);
    }
    setState(() => _isAnimating = true);
    if (revealed) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  Future<void> _handleTap() async {
    if (!widget.enableTap) return;
    if (_isAnimating || _controller.isAnimating) return;

    setState(() => _isAnimating = true);
    HapticFeedback.lightImpact();

    if (widget.playFlipSound) {
      // Semantic event only — no asset paths in the widget.
      ref.read(audioManagerProvider).play(AudioEvent.roleCardFlip);
    }

    final next = !_revealed;
    final provider = widget.revealedProvider;
    if (provider != null) {
      ref.read(provider.notifier).state = next;
    } else if (widget.isRevealed == null) {
      setState(() => _localRevealed = next);
    }

    if (next) {
      await _controller.forward();
    } else {
      await _controller.reverse();
    }

    widget.onRevealChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    // Keep controller aligned when provider state changes externally.
    final revealed = _revealed;
    if (!_isAnimating &&
        !_controller.isAnimating &&
        ((revealed && _controller.value < 0.5) ||
            (!revealed && _controller.value > 0.5))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _isAnimating) return;
        _syncTo(revealed);
      });
    }

    final card = AnimatedBuilder(
      animation: _flip,
      builder: (context, _) {
        final t = _flip.value;
        final angle = t * math.pi;
        final showFront = angle <= (math.pi / 2);

        // Depth peaks at edge-on (t = 0.5) for stretch/contract shadow.
        final depth = math.sin(angle).clamp(0.0, 1.0);
        final shadowBlur = 10.0 + depth * 28.0;
        final shadowDy = 6.0 + depth * 22.0;
        final shadowSpread = depth * 6.0;
        final shadowAlpha = 0.35 + depth * 0.35;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: shadowAlpha),
                  blurRadius: shadowBlur,
                  spreadRadius: shadowSpread,
                  offset: Offset(0, shadowDy),
                ),
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12 * depth),
                  blurRadius: shadowBlur * 0.6,
                  offset: Offset(0, shadowDy * 0.4),
                ),
              ],
            ),
            child: showFront
                ? _face(child: widget.backFace ?? _defaultBack())
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _face(
                      child: widget.frontFace ?? _defaultFront(widget.role),
                    ),
                  ),
          ),
        );
      },
    );

    return SizedBox(
      width: widget.width,
      height: widget.height,
      // Only attach a GestureDetector when interactive — otherwise a parent
      // tap handler never fires (child wins the arena even if onTap no-ops).
      child: widget.enableTap
          ? GestureDetector(
              onTap: _handleTap,
              behavior: HitTestBehavior.opaque,
              child: card,
            )
          : card,
    );
  }

  Widget _face({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: child,
      ),
    );
  }

  /// Unrevealed embossed dark chit (raised tactile slab).
  Widget _defaultBack() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A3144),
            Color(0xFF151922),
            Color(0xFF0B0E14),
          ],
        ),
        border: Border.all(color: AppColors.glassBorder, width: 1.4),
        boxShadow: const [
          // Emboss highlight (top-left)
          BoxShadow(
            color: Color(0x33FFFFFF),
            blurRadius: 0,
            offset: Offset(-1.5, -1.5),
          ),
          // Emboss inset (bottom-right)
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 0,
            offset: Offset(2, 2),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.06),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.25),
                ],
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.help_outline_rounded,
                  size: 56,
                  color: AppColors.raja.withValues(alpha: 0.85),
                ),
                const SizedBox(height: 12),
                Text(
                  'গোপন চিরকুট',
                  style: AppTextStyles.heading3(color: AppColors.textLightPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  'ট্যাপ করে উল্টাও',
                  style: AppTextStyles.caption(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultFront(GameRole? role) {
    if (role == null) {
      return Container(
        color: AppColors.surfaceElevatedDark,
        alignment: Alignment.center,
        child: Text('?', style: AppTextStyles.heading1()),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: role.gradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24, width: 2),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'তোমার রোল',
            style: AppTextStyles.caption(color: Colors.white70),
          ),
          const Spacer(),
          Image.asset(
            role.standingAsset,
            height: widget.height * 0.42,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(
              Icons.person,
              size: widget.height * 0.28,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            role.label.toUpperCase(),
            style: AppTextStyles.heading1(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          Text(
            role.instructions,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
