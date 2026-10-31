import 'package:flutter/material.dart';

/// Wraps any tappable child with a springy press effect.
/// Scales down slightly on tap and springs back with a satisfying bounce.
class BounceTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final bool enableHaptics;

  const BounceTap({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.94,
    this.enableHaptics = true,
  });

  @override
  State<BounceTap> createState() => _BounceTapState();
}

class _BounceTapState extends State<BounceTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1.0,
    duration: const Duration(milliseconds: 300),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _controller.animateTo(
      widget.pressedScale,
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
    );
  }

  void _onTapUp(TapUpDetails _) {
    _springBack();
  }

  void _onTapCancel() {
    _springBack();
  }

  void _springBack() {
    _controller.animateTo(
      1.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _controller,
        child: widget.child,
      ),
    );
  }
}
