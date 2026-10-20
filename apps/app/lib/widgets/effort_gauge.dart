import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';

class EffortGauge extends StatelessWidget {
  final int score;

  const EffortGauge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: score / 100),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.elasticOut,
      builder: (context, progress, _) {
        return SizedBox(
          width: 150,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: progress,
                strokeWidth: 10,
                backgroundColor: kBorder,
                color: _color(score),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '/ 100',
                    style: const TextStyle(
                      fontSize: 12,
                      color: kTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _color(int score) {
    if (score >= 75) return kSuccess;
    if (score >= 50) return kWarning;
    return kError;
  }
}
