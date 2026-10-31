import 'package:edtech_app/models/calendar_event.dart';
import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';

/// A deadline tile with a pastel colour wash, gradient emoji bubble and a
/// friendly "in X days" pill. Springy on press.
class DeadlineCard extends StatefulWidget {
  final CalendarEvent event;

  const DeadlineCard({super.key, required this.event});

  @override
  State<DeadlineCard> createState() => _DeadlineCardState();
}

class _DeadlineCardState extends State<DeadlineCard>
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
    final kindColor = _kindColor(widget.event.kind);
    final emoji = _kindEmoji(widget.event.kind);
    final relative = _relative(widget.event.startsAt);

    return GestureDetector(
      onTapDown: (_) => _press(),
      onTapUp: (_) => _release(),
      onTapCancel: _release,
      child: ScaleTransition(
        scale: _controller,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [tintOf(kindColor, 0.16), tintOf(kindColor, 0.04)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            border: Border.all(color: tintOf(kindColor, 0.28)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: livelyGradient(kindColor, shadeOf(kindColor, 0.15)),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: kindColor.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
            ),
            title: Text(
              widget.event.title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: kTextPrimary),
            ),
            subtitle: Text(
              '${widget.event.kind}  ·  ${widget.event.courseId ?? 'Institution'}',
              style: const TextStyle(fontSize: 12, color: kTextSecondary),
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kindColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.event.startsAt.month}/${widget.event.startsAt.day}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  relative,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: kindColor,
                  ),
                ),
              ],
            ),
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
