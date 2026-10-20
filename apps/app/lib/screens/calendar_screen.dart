import 'package:edtech_app/models/calendar_event.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';
import '../widgets/deadline_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  List<CalendarEvent> _events = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _load();
  }

  Future<void> _load() async {
    try {
      final events = await ApiService.instance.getCalendar(null);
      if (!mounted) return;
      setState(() {
        _events = List<CalendarEvent>.from(events)
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
        _loading = false;
        _error = null;
      });
      _fade.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _PageHeader(
            title: 'Calendar',
            subtitle: 'Classes, quizzes & deadlines',
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: kError, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: kTextSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: _load,
                    style: FilledButton.styleFrom(
                      foregroundColor: kPrimary,
                    ),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            )
          else if (_events.isEmpty)
            const Center(child: Text('No upcoming events', style: TextStyle(color: kTextSecondary)))
          else
            ..._events.map((event) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: DeadlineCard(event: event),
                )),
        ],
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _PageHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: kTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: kTextSecondary,
          ),
        ),
      ],
    );
  }
}
