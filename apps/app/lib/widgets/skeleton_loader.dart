import 'package:flutter/material.dart';

/// A shimmering skeleton placeholder shown while content loads.
/// Feels much faster and more polished than a plain spinner.
class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
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
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [Color(0xFFE8E8E8), Color(0xFFF5F5F5), Color(0xFFE8E8E8)],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: widget.borderRadius,
            ),
          ),
        );
      },
    );
  }
}

/// A collection of skeleton boxes shaped like a card, for list loading states.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonBox(width: 56, height: 22, borderRadius: BorderRadius.all(Radius.circular(8))),
              const Spacer(),
              SkeletonBox(width: 20, height: 20, borderRadius: BorderRadius.circular(10)),
            ],
          ),
          const SizedBox(height: 16),
          const SkeletonBox(width: 200, height: 18),
          const SizedBox(height: 8),
          const SkeletonBox(width: 130, height: 12),
          const SizedBox(height: 16),
          const Row(
            children: [
              SkeletonBox(width: 70, height: 14),
              SizedBox(width: 16),
              SkeletonBox(width: 80, height: 14),
            ],
          ),
        ],
      ),
    );
  }
}
