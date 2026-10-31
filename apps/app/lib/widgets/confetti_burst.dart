import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A lightweight confetti burst overlay. Show it once to celebrate a
/// positive result (e.g. a high integrity score). Purely decorative.
class ConfettiBurst extends StatefulWidget {
  final Widget child;

  const ConfettiBurst({super.key, required this.child});

  @override
  State<ConfettiBurst> createState() => ConfettiBurstState();
}

class ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  bool _active = false;

  void celebrate() {
    if (_active) return;
    setState(() => _active = true);
    _controller.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _active = false);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_active)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ConfettiPainter(progress: _controller.value),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  static final _random = math.Random(42);

  // Pre-generate particle specs once so they don't flicker between frames.
  static final List<({double x, double angle, double velocity, Color color, double size, double rotationSpeed})>
      _particles = List.generate(36, (i) {
    const palette = [
      Color(0xFFFF6A00),
      Color(0xFFFFB347),
      Color(0xFFEC4899),
      Color(0xFF34D399),
      Color(0xFFFBBF24),
      Color(0xFF60A5FA),
    ];
    return (
      x: _random.nextDouble(),
      angle: -math.pi / 2 + (_random.nextDouble() - 0.5) * math.pi * 1.4,
      velocity: 0.4 + _random.nextDouble() * 0.5,
      color: palette[i % palette.length],
      size: 5 + _random.nextDouble() * 7,
      rotationSpeed: (_random.nextDouble() - 0.5) * 12,
    );
  });

  _ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final p in _particles) {
      // Ease-out trajectory.
      final t = Curves.easeOut.transform(progress.clamp(0.0, 1.0));
      final travel = t * p.velocity * size.height * 0.9;
      final cx = size.width * p.x + math.cos(p.angle) * travel * 0.5;
      final cy = size.height * 0.35 + math.sin(p.angle) * travel;

      // Fade out near the end.
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      paint.color = p.color.withValues(alpha: opacity);

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(p.rotationSpeed * progress);

      // Small rounded rect "confetti" chip.
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55),
        const Radius.circular(2),
      );
      canvas.drawRRect(rrect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
