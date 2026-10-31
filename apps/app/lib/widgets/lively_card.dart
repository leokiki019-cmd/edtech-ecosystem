import 'package:flutter/material.dart';

class LivelyCard extends StatelessWidget {
  final LinearGradient gradient;
  final Widget child;

  const LivelyCard({super.key, required this.gradient, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}
