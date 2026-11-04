import 'package:edtech_app/models/calendar_event.dart';
import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';

/// A polished deadline tile with a gradient wash, emoji badge, and relative
/// timing pill. Soft shadows and springy press feedback.
class DeadlineCard extends StatefulWidget {
  final CalendarEvent event;
  final VoidCallback? onTap;

  const DeadlineCard({super.key, required this.event, this.onTap});

  @override
  State<DeadlineCard> createState() => _DeadlineCardState();
}

class _DeadlineCardState extends State<DeadlineCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1.0,
    duration: const Duration(milliseconds: 320),
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
        duration: const Duration(milliseconds: 550),
        curve: Curves.elasticOut,
      );

  @override
  Widget build(BuildContext context) {
    final kindColor = _kindColor(widget.event.kind);
    final emoji = _kindEmoji(widget.event.kind);
    final relative = _relative(widget.event.startsAt);

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _press(),
      onTapUp: (_) => _release(),
      onTapCancel: _release,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: kindColor.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              // Emoji badge with subtle shadow.
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tintOf(kindColor, 0.14),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: kindColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 16),
              // Content column.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: kTextPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.event.kind}  ·  ${widget.event.courseId ?? 'Institution'}',
                      style: const TextStyle(fontSize: 11, color: kTextSecondary),
                    ),
                  ],
                ),
              ),
              // Timing pill + emoji together on the right.
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: kindColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.event.startsAt.month}/${widget.event.startsAt.day}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    relative,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: kindColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _relative(DateTime start) {
    final days = start.difference(DateTime.now()).inDays;
    if (days < -1) return '${-days}d ago';
    if (days < 0) return 'yesterday';
    if (days == 0) return 'today!';
    if (days == 1) return 'tomorrow';
    return 'in $days days';
  }

  Color _kindColor(String kind) {
    switch (kind) {
      case 'assignment':
        return kPrimary;
      case 'quiz':
        return kWarning;
      case 'class':
        return kSuccess;
      case 'institution':
        return kPink;
      default:
        return kPurple;
    }
  }

  String _kindEmoji(String kind) {
    switch (kind) {
      case 'assignment':
        return '📝';
      case 'quiz':
        return '🧠';
      case 'class':
        return '🏫';
      case 'institution':
        return '🏛️';
      default:
        return '📅';
    }
  }
}
