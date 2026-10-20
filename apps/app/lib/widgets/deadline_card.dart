import 'package:edtech_app/models/calendar_event.dart';
import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';
import 'hover_scale.dart';

class DeadlineCard extends StatelessWidget {
  final CalendarEvent event;

  const DeadlineCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final kindColor = _kindColor(event.kind);
    return HoverScale(
      child: Container(
        decoration: BoxDecoration(
          color: kCard,
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: kindColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          title: Text(
            event.title,
            style: const TextStyle(fontWeight: FontWeight.w700, color: kTextPrimary),
          ),
          subtitle: Text(
            '${event.kind}  ·  ${event.courseId ?? 'Institution'}',
            style: const TextStyle(fontSize: 12, color: kTextSecondary),
          ),
          trailing: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${event.startsAt.month}/${event.startsAt.day}',
                style: const TextStyle(fontWeight: FontWeight.w800, color: kTextPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                '${event.startsAt.hour}:${event.startsAt.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 11, color: kTextSecondary),
              ),
            ],
          ),
        ),
      ),
    );
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
        return kOrange;
      default:
        return kTextSecondary;
    }
  }
}
