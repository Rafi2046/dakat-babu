import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../core/constants/app_colors.dart';

/// Normalized tilt in roughly `-1…1` for each axis (device-dependent).
final lobbyAccelerometerProvider = StreamProvider.autoDispose<Offset>((ref) {
  final controller = StreamController<Offset>.broadcast();

  final sub = accelerometerEventStream(
    samplingPeriod: SensorInterval.uiInterval,
  ).listen(
    (event) {
      // Invert X so tilting right shifts content naturally.
      final nx = (-event.x / 6.0).clamp(-1.0, 1.0);
      final ny = (event.y / 6.0).clamp(-1.0, 1.0);
      if (!controller.isClosed) {
        controller.add(Offset(nx.toDouble(), ny.toDouble()));
      }
    },
    onError: (_) {
      // Emulators / desktop may lack sensors — stay centered.
      if (!controller.isClosed) controller.add(Offset.zero);
    },
    cancelOnError: false,
  );

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Immersive 2.5D lobby background. Wrap Home/Lobby UI with [child].
///
/// Tilting the device shifts three depth layers at different strengths.
/// Sensor noise is smoothed via short `easeOut` interpolation (not raw mapping).
class ParallaxLobbyBackground extends ConsumerStatefulWidget {
  final Widget child;

  /// Max translation in logical pixels for the foreground layer.
  final double maxOffset;

  /// Interpolation duration for tilt → motion.
  final Duration smoothDuration;

  const ParallaxLobbyBackground({
    super.key,
    required this.child,
    this.maxOffset = 18,
    this.smoothDuration = const Duration(milliseconds: 160),
  });

  @override
  ConsumerState<ParallaxLobbyBackground> createState() =>
      _ParallaxLobbyBackgroundState();
}

class _ParallaxLobbyBackgroundState
    extends ConsumerState<ParallaxLobbyBackground> {
  Offset _target = Offset.zero;
  Offset _from = Offset.zero;
  int _tweenGen = 0;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<Offset>>(lobbyAccelerometerProvider, (prev, next) {
      next.whenData((normalized) {
        final nextTarget = Offset(
          (normalized.dx * widget.maxOffset)
              .clamp(-widget.maxOffset, widget.maxOffset),
          (normalized.dy * widget.maxOffset)
              .clamp(-widget.maxOffset, widget.maxOffset),
        );
        if ((nextTarget - _target).distance < 0.35) return;
        if (!mounted) return;
        setState(() {
          _from = _target;
          _target = nextTarget;
          _tweenGen++;
        });
      });
    });

    // Desktop / web / missing sensor: keep layers static.
    if (kIsWeb) {
      return _stackFor(Offset.zero);
    }

    return TweenAnimationBuilder<Offset>(
      key: ValueKey(_tweenGen),
      tween: Tween<Offset>(begin: _from, end: _target),
      duration: widget.smoothDuration,
      curve: Curves.easeOut,
      builder: (context, offset, _) => _stackFor(offset),
    );
  }

  Widget _stackFor(Offset offset) {
    // Oversized layers so clamped motion never reveals empty edges.
    final pad = widget.maxOffset * 2.2;

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          // Unbounded / zero sizes crash LinearGradient shaders (NaN offsets).
          if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) {
            return ColoredBox(
              color: AppColors.backgroundDark,
              child: widget.child,
            );
          }

          final layerW = w + pad * 2;
          final layerH = h + pad * 2;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Deep background — subtle grid, barely moves.
              Transform.translate(
                offset: offset * 0.18,
                child: OverflowBox(
                  alignment: Alignment.center,
                  minWidth: layerW,
                  maxWidth: layerW,
                  minHeight: layerH,
                  maxHeight: layerH,
                  child: SizedBox(
                    width: layerW,
                    height: layerH,
                    child: const _DeepGridLayer(),
                  ),
                ),
              ),

              // Midground — Police blue / Chor crimson ambient glows.
              Transform.translate(
                offset: offset * 0.5,
                child: OverflowBox(
                  alignment: Alignment.center,
                  minWidth: layerW,
                  maxWidth: layerW,
                  minHeight: layerH,
                  maxHeight: layerH,
                  child: SizedBox(
                    width: layerW,
                    height: layerH,
                    child: const _MidGlowLayer(),
                  ),
                ),
              ),

              // Foreground — actual UI moves the most for depth.
              Transform.translate(
                offset: offset,
                child: widget.child,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DeepGridLayer extends StatelessWidget {
  const _DeepGridLayer();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppColors.darkBackgroundGradient,
      ),
      child: CustomPaint(
        painter: _GridPainter(
          color: AppColors.glassBorder.withValues(alpha: 0.35),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _MidGlowLayer extends StatelessWidget {
  const _MidGlowLayer();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: const Alignment(-0.85, -0.55),
            child: _blob(
              diameter: 280,
              color: AppColors.police.withValues(alpha: 0.28),
            ),
          ),
          Align(
            alignment: const Alignment(0.9, 0.35),
            child: _blob(
              diameter: 260,
              color: AppColors.chor.withValues(alpha: 0.22),
            ),
          ),
          Align(
            alignment: const Alignment(0.1, 0.85),
            child: _blob(
              diameter: 200,
              color: AppColors.primary.withValues(alpha: 0.18),
            ),
          ),
          Align(
            alignment: const Alignment(-0.2, -0.9),
            child: _blob(
              diameter: 160,
              color: AppColors.raja.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob({required double diameter, required Color color}) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  _GridPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      return;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const step = 42.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Soft vignette wash.
    final vignette = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.45),
        ],
        stops: const [0.45, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) =>
      oldDelegate.color != color;
}
