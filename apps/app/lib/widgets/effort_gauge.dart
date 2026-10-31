import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';

class EffortGauge extends StatelessWidget {
  final int score;

  const EffortGauge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: score / 100),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.elasticOut,
      builder: (context, progress, _) {
        final clamped = progress.clamp(0.0, 1.0);
        return SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Soft glow behind the ring.
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _color(score).withValues(alpha: 0.25),
                      blurRadius: 40,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 150,
                height: 150,
                child: CircularProgressIndicator(
                  value: clamped,
                  strokeWidth: 11,
                  backgroundColor: kBorder,
                  strokeCap: StrokeCap.round,
                  color: _color(score),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _emoji(),
                    style: const TextStyle(fontSize: 26),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '/ 100',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
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

  String _emoji() {
    if (score >= 85) return '🌟';
    if (score >= 75) return '😊';
    if (score >= 50) return '🙂';
    if (score >= 30) return '😐';
    return '😟';
  }
}
