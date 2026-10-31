import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Soft, floating decorative circles that drift slowly behind hero cards.
/// Gives the UI a playful, alive feel without being distracting.
class FloatingShapes extends StatefulWidget {
  final Widget child;
  final List<Color> colors;

  const FloatingShapes({
    super.key,
    required this.child,
    this.colors = const [
      Colors.white24,
      Colors.white12,
      Colors.white30,
    ],
  });

  @override
  State<FloatingShapes> createState() => _FloatingShapesState();
}

class _FloatingShapesState extends State<FloatingShapes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value * 2 * math.pi;
        return CustomPaint(
          painter: _ShapePainter(
            t: t,
            colors: widget.colors,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _ShapePainter extends CustomPainter {
  final double t;
  final List<Color> colors;

  _ShapePainter({required this.t, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Three soft circles drifting on different sine paths.
    final specs = <(double, double, double, double)>[
      (0.15, 0.2, 60.0, 0.8),   // cx%, cy%, radius, speed
      (0.75, 0.65, 80.0, 0.6),
      (0.5, 0.9, 45.0, 1.0),
    ];

    for (var i = 0; i < specs.length; i++) {
      final (cxPct, cyPct, radius, speed) = specs[i];
      paint.color = colors[i % colors.length];

      final cx = size.width * cxPct + math.sin(t * speed + i * 1.7) * 18;
      final cy = size.height * cyPct + math.cos(t * speed * 0.7 + i * 2.3) * 14;

      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ShapePainter oldDelegate) =>
      oldDelegate.t != t;
}
