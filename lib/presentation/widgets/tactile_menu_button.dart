import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/home_text_styles.dart';

/// Premium embossed dark neumorphic menu button for Home / Mode Select.
///
/// Press depresses the slab (scale + flattened shadows), with light→heavy
/// haptics and [AudioEvent.buttonTap] via [AudioManager].
class TactileMenuButton extends ConsumerStatefulWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onTap;
  final Color? accentColor;
  final double height;
  final double borderRadius;
  final bool enabled;

  const TactileMenuButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.accentColor,
    this.height = 58,
    this.borderRadius = 18,
    this.enabled = true,
  });

  @override
  ConsumerState<TactileMenuButton> createState() => _TactileMenuButtonState();
}

class _TactileMenuButtonState extends ConsumerState<TactileMenuButton> {
  static const _animDuration = Duration(milliseconds: 120);

  bool _pressed = false;

  Color get _accent => widget.accentColor ?? AppColors.primary;

  void _setPressed(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.enabled) return;
    _setPressed(true);
    HapticFeedback.lightImpact();
  }

  void _onTapCancel() => _setPressed(false);

  Future<void> _onTapUp(TapUpDetails _) async {
    if (!widget.enabled) return;
    _setPressed(false);
    HapticFeedback.heavyImpact();
    await ref.read(audioManagerProvider).play(AudioEvent.buttonTap);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final pressed = _pressed;
    final base = AppColors.surfaceElevatedDark;
    final face = Color.lerp(base, _accent, pressed ? 0.12 : 0.06)!;

    return Opacity(
      opacity: widget.enabled ? 1 : 0.45,
      child: AnimatedScale(
        scale: pressed ? 0.95 : 1.0,
        duration: _animDuration,
        curve: Curves.easeOut,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.enabled ? _onTapDown : null,
          onTapUp: widget.enabled ? _onTapUp : null,
          onTapCancel: widget.enabled ? _onTapCancel : null,
          child: AnimatedContainer(
            duration: _animDuration,
            curve: Curves.easeOut,
            height: widget.height,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: face,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: pressed
                    ? _accent.withValues(alpha: 0.55)
                    : _accent.withValues(alpha: 0.28),
                width: pressed ? 1.6 : 1.2,
              ),
              boxShadow: pressed
                  ? [
                      // Flattened / inset look when depressed.
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: Offset.zero,
                      ),
                    ]
                  : [
                      // Raised neumorphism: dark bottom-right.
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.55),
                        blurRadius: 14,
                        offset: const Offset(4, 6),
                      ),
                      // Soft light highlight top-left.
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(-3, -3),
                      ),
                      // Accent edge glow.
                      BoxShadow(
                        color: _accent.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: pressed
                    ? [
                        face,
                        Color.lerp(face, Colors.black, 0.18)!,
                      ]
                    : [
                        Color.lerp(face, Colors.white, 0.06)!,
                        face,
                        Color.lerp(face, Colors.black, 0.12)!,
                      ],
              ),
            ),
            child: Row(
              children: [
                if (widget.icon != null) ...[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: pressed ? 0.28 : 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _accent.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Icon(widget.icon, color: _accent, size: 20),
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Text(
                    widget.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HomeTextStyles.title(
                      color: Color.lerp(
                        AppColors.textLightPrimary,
                        _accent,
                        0.35,
                      ),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: _accent.withValues(alpha: 0.85),
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
