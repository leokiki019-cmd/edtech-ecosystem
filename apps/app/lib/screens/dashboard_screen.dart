import 'package:edtech_app/models/calendar_event.dart';
import 'package:edtech_app/models/course.dart';
import 'package:edtech_app/auth/auth_provider.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/deadline_card.dart';
import '../widgets/lively_card.dart';
import '../widgets/responsive_grid.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  late final AnimationController _pulse;
  List<CalendarEvent> _deadlines = [];
  int _courseCount = 0;
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
      final userId = context.read<AuthProvider>().user?.id ?? 'u-student-1';
      final results = await Future.wait([
        ApiService.instance.getCalendar(userId),
        ApiService.instance.getCourses(),
      ]);
      final events = results[0] as List<CalendarEvent>;
      final courses = results[1] as List<Course>;
      final sorted = List<CalendarEvent>.from(events)
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
      if (!mounted) return;
      setState(() {
        _deadlines = sorted.length > 5 ? sorted.sublist(0, 5) : sorted;
        _courseCount = courses.length;
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
      opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),        child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _GreetingCard(),
          const SizedBox(height: 24),
          ResponsiveGrid(
            items: [
              _PulseStatCard(
                title: 'Upcoming deadlines',
                value: _deadlines.length.toString(),
                icon: Icons.schedule,
                color: kPrimary,
                pulseController: _pulse,
              ),
              _PulseStatCard(
                title: 'Courses',
                value: _courseCount.toString(),
                icon: Icons.school,
                color: kAccentDark,
                pulseController: _pulse,
              ),
            ],
          ),
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
            _ErrorState(
              error: _error!,
              onRetry: _load,
            )
          else if (_deadlines.isEmpty)
            const Center(
              child: Text(
                'No upcoming deadlines',
                style: TextStyle(color: kTextSecondary, fontSize: 16),
              ),
            )
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 18) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final term = user?.courseIds.isNotEmpty == true ? 'Fall 2026' : 'Welcome';
    return LivelyCard(
      gradient: linearGradient(kPrimary, kPrimaryDark),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.displayName ?? 'Student',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    term,
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

class _PulseStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final AnimationController? pulseController;

  const _PulseStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(begin: 0.97, end: 1.03).animate(CurvedAnimation(
      parent: pulseController!,
      curve: Curves.easeInOut,
    ));

    return AnimatedBuilder(
      animation: scale,
      builder: (context, child) => Transform.scale(scale: scale.value, child: child),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: kTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: kTextPrimary,
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