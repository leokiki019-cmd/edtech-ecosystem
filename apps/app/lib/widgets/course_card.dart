import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';
import 'hover_scale.dart';

/// A course tile with a candy gradient header band, subject emoji badge
/// and squishy press physics.
class CourseCard extends StatefulWidget {
  final String code;
  final String title;
  final String teacher;
  final int students;
  final int assignments;
  final Color color;

  const CourseCard({
    super.key,
    required this.code,
    required this.title,
    required this.teacher,
    required this.students,
    required this.assignments,
    required this.color,
  });

  @override
  State<CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<CourseCard>
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

  void _press() => _controller.animateTo(0.96,
      duration: const Duration(milliseconds: 80), curve: Curves.easeOut);
  void _release() => _controller.animateTo(1.0,
      duration: const Duration(milliseconds: 500), curve: Curves.elasticOut);

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    return HoverScale(
      child: GestureDetector(
        onTapDown: (_) => _press(),
        onTapUp: (_) => _release(),
        onTapCancel: _release,
        child: ScaleTransition(
          scale: _controller,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: tintOf(color, 0.18)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Candy gradient header band with code chip + emoji badge.
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: livelyGradient(color, shadeOf(color, 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
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
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: kTextPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.person_rounded,
                              size: 16, color: kTextSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.teacher,
                              style: const TextStyle(
                                  color: kTextSecondary, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _StatPill(
                            icon: Icons.people_rounded,
                            value: '${widget.students}',
                            label: 'Students',
                            color: color,
                          ),
                          const SizedBox(width: 10),
                          _StatPill(
                            icon: Icons.assignment_rounded,
                            value: '${widget.assignments}',
                            label: 'Assignments',
                            color: color,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
        color: tintOf(color, 0.10),
        borderRadius: BorderRadius.circular(13),
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
                  fontWeight: FontWeight.w900,
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
