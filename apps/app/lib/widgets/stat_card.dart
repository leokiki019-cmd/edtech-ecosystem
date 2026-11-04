import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';
import 'animated_number.dart';
import 'bounce_tap.dart';

/// A playful stat tile: pastel gradient wash, squishy tap, gradient icon
/// bubble and a soft decorative blob peeking from the corner.
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
    return BounceTap(
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, tintOf(color, 0.10)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: tintOf(color, 0.18)),
          borderRadius: BorderRadius.circular(kRadiusMd),
          boxShadow: [cardShadow(color)],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tintOf(color, 0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: kSpaceMd, horizontal: kSpaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(kSpaceSm),
                    decoration: iconBubble(color),
                    child: Icon(icon, color: Colors.white, size: 21),
                  ),
                  const SizedBox(height: kSpaceMd),
                  AnimatedNumber(
                    value: value,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: shadeOf(color, 0.4),
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: kSpaceSm),
                  Text(
                    title,
                    style: context.caption.copyWith(
                      color: kTextSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
