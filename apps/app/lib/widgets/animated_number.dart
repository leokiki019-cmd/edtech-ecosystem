import 'package:flutter/material.dart';

class AnimatedNumber extends StatelessWidget {
  final int value;
  final TextStyle style;
  final Duration duration;

  const AnimatedNumber({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, _) {
        return Text(
          animatedValue.round().toString(),
          style: style,
        );
      },
    );
  }
}
