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
  late final AnimationController _pulse;
  List<CalendarEvent> _events = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      value: 1.0,
    );
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
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
      _pulse.repeat(reverse: true);
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
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            _ErrorState(
              error: _error!,
              onRetry: _load,
            )
          else if (_events.isEmpty)
            const Center(
              child: Text(
                'No upcoming events',
                style: TextStyle(color: kTextSecondary, fontSize: 16),
              ),
            )
          else
            ..._events.map((event) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: DeadlineCard(event: event),
                )),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Calendar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: kTextPrimary,
            ),
          ),
        ),
        Tooltip(
          message: 'Refresh calendar',
          child: IconButton(
            icon: const Icon(Icons.refresh, color: kTextSecondary, size: 20),
            onPressed: () {
              _load();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing calendar'),
                  backgroundColor: kPrimary,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: kError, size: 48),
          const SizedBox(height: 12),
          Text(
            error,
            style: const TextStyle(color: kTextSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              foregroundColor: kPrimary,
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}