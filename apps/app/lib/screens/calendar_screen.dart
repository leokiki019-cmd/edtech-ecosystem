import 'package:edtech_app/models/calendar_event.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';
import '../widgets/deadline_card.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/staggered_reveal.dart';

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
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      value: 1.0,
    );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final events = await ApiService.instance.getCalendar(null);
      if (!mounted) return;
      setState(() {
        _events = List<CalendarEvent>.from(events)
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
        _loading = false;
      });
      _fade.forward(from: 0);
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
      child: RefreshIndicator(
        onRefresh: _load,
        color: kPrimary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            if (_loading)
              const Column(
                children: [SkeletonCard(), SkeletonCard(), SkeletonCard()],
              )
            else if (_error != null)
              _ErrorState(error: _error!, onRetry: _load)
            else if (_events.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: kBorder),
                ),
                child: const Column(
                  children: [
                    Text('🗓️', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 12),
                    Text(
                      'Nothing scheduled',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextPrimary),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Your calendar is wide open!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kTextSecondary, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              StaggeredReveal(
                childCount: _events.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: DeadlineCard(event: _events[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Calendar 📅',
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
            icon: const Icon(Icons.refresh_rounded, color: kTextSecondary, size: 20),
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

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😵', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          Text(
            error,
            style: const TextStyle(color: kTextSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try again'),
            style: FilledButton.styleFrom(foregroundColor: kPrimary),
          ),
        ],
      ),
    );
  }
}
