import 'package:edtech_app/models/calendar_event.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';
import '../widgets/deadline_card.dart';
import '../widgets/hover_scale.dart';
import '../widgets/lively_card.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  List<CalendarEvent> _deadlines = [];
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
      final events = await ApiService.instance.getCalendar('u-student-1');
      if (!mounted) return;
      setState(() {
        _deadlines = List<CalendarEvent>.from(events)
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt))
          ..take(5);
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
          const _GreetingCard(),
          const SizedBox(height: 24),
          _StatRow(),
          const SizedBox(height: 24),
          Text(
            'Upcoming deadlines',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: kTextPrimary,
                ),
          ),
          const SizedBox(height: 16),
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
          else if (_deadlines.isEmpty)
            const Center(child: Text('No upcoming deadlines', style: TextStyle(color: kTextSecondary)))
          else
            ..._deadlines.map((event) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: DeadlineCard(event: event),
                )),
        ],
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard();

  @override
  Widget build(BuildContext context) {
    return LivelyCard(
      gradient: livelyGradient(kPrimary, kPrimaryDark),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Good morning,',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Alex Rivera',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Fall 2026 · CS 301 Human-Computer Interaction',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.star, color: Colors.white, size: 32),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Upcoming deadlines',
            value: 3,
            icon: Icons.schedule,
            color: kPrimary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'Current effort',
            value: 84,
            icon: Icons.insights,
            color: kSuccess,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: 'Courses',
            value: 1,
            icon: Icons.school,
            color: kAccentDark,
          ),
        ),
      ],
    );
  }
}
