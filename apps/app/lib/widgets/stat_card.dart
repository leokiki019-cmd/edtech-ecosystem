import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';
import 'animated_number.dart';

class StatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 18),
            AnimatedNumber(
              value: value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: kTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
