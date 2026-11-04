import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';

/// A polished course card with a gradient header band, emoji badge, and
/// compact stat pills. Elevated with soft shadow and springy press feedback.
class CourseCard extends StatefulWidget {
  final String code;
  final String title;
  final String teacher;
  final int students;
  final int assignments;

  const CourseCard({
    super.key,
    required this.code,
    required this.title,
    required this.teacher,
    required this.students,
    required this.assignments,
  });

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1.0,
    duration: const Duration(milliseconds: 280),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _press() => _controller.animateTo(
        0.95,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOutCubic,
      );
  void _release() => _controller.animateTo(
        1.0,
        duration: const Duration(milliseconds: 520),
        curve: Curves.elasticOut,
      );

  @override
  Widget build(BuildContext context) {
    final cardColor = widgetColor();
    return GestureDetector(
      onTapDown: (_) => _press(),
      onTapUp: (_) => _release(),
      onTapCancel: _release,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Candy gradient header band with code chip + emoji badge.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: livelyGradient(primaryGradientStart(), shadeOf(primaryGradientStart(), 0.2)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    // Code chip.
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.code,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Emoji badge.
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _emojiFor(widget.code),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Title.
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: kTextPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person_rounded, size: 16, color: kTextSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.teacher,
                      style: const TextStyle(color: kTextSecondary, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Stat pills row.
              Row(
                children: [
                  _StatPill(
                    icon: Icons.people_rounded,
                    value: '${widget.students}',
                    label: 'Students',
                    color: kPrimary,
                  ),
                  const SizedBox(width: 10),
                  _StatPill(
                    icon: Icons.assignment_rounded,
                    value: '${widget.assignments}',
                    label: 'Assignments',
                    color: kPrimary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color widgetColor() => kPrimary;

  Color primaryGradientStart() => kPrimary;

  /// Picks a friendly emoji based on the course code.
  static String _emojiFor(String code) {
    final c = code.toUpperCase();
    if (c.contains('CS') || c.contains('IT') || c.contains('SE')) return '💻';
    if (c.contains('MA') || c.contains('ST')) return '🧮';
    if (c.contains('EN') || c.contains('LI')) return '📖';
    if (c.contains('PH') ||
        c.contains('CH') ||
        c.contains('BI') ||
        c.contains('SC')) {
      return '🔬';
    }
    if (c.contains('HI') || c.contains('PO')) return '🏛️';
    if (c.contains('AR') || c.contains('MU')) return '🎨';
    return '📚';
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tintOf(color, 0.09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: kTextPrimary,
                  height: 1.1,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9.5,
                  color: kTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
