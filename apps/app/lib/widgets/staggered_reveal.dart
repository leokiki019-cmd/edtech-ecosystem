import 'package:flutter/material.dart';

/// Wraps a list of children so each item springs in one-by-one with a
/// playful stagger. Re-runs the animation whenever [childCount] changes.
class StaggeredReveal extends StatelessWidget {
  final int childCount;
  final IndexedWidgetBuilder itemBuilder;
  final Duration baseDelay;
  final double slideOffset;

  const StaggeredReveal({
    super.key,
    required this.childCount,
    required this.itemBuilder,
    this.baseDelay = const Duration(milliseconds: 60),
    this.slideOffset = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(childCount, (index) {
        return _StaggeredItem(
          delay: baseDelay * index,
          slideOffset: slideOffset,
          child: itemBuilder(context, index),
        );
      }),
    );
  }
}

class _StaggeredItem extends StatefulWidget {
  final Duration delay;
  final double slideOffset;
  final Widget child;

  const _StaggeredItem({
    required this.delay,
    required this.slideOffset,
    required this.child,
  });

  @override
  State<_StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<_StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );

  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: Offset(0, widget.slideOffset / 100),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
