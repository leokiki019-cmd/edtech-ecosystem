import 'package:edtech_app/models/calendar_event.dart';
import 'package:edtech_app/models/course.dart';
import 'package:edtech_app/auth/auth_provider.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/bounce_tap.dart';
import '../widgets/deadline_card.dart';
import '../widgets/floating_shapes.dart';
import '../widgets/lively_card.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/staggered_reveal.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
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
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
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
            const _GreetingCard(),
            const SizedBox(height: 24),
            if (_loading)
              const _StatSkeletons()
            else
              ResponsiveGrid(
                items: [
                  _StatCard(
                    title: 'Upcoming deadlines',
                    value: _deadlines.length,
                    icon: Icons.schedule_rounded,
                    color: kPrimary,
                  ),
                  _StatCard(
                    title: 'Courses',
                    value: _courseCount,
                    icon: Icons.school_rounded,
                    color: kBlue,
                  ),
                ],
              ),
            const SizedBox(height: 28),
            Row(
              children: [
                Text(
                  'Upcoming deadlines',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: kTextPrimary,
                      ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.waving_hand_rounded, size: 18, color: kAccent),
              ],
            ),
            const SizedBox(height: 16),
            if (_loading)
              const SkeletonCard()
            else if (_error != null)
              _ErrorState(error: _error!, onRetry: _load)
            else if (_deadlines.isEmpty)
              const _EmptyDeadlines()
            else
              StaggeredReveal(
                childCount: _deadlines.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: DeadlineCard(event: _deadlines[index]),
                ),
              ),
          ],
        ),
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

  String _emoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '🌅';
    if (hour < 18) return '☀️';
    return '🌙';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final term = user?.courseIds.isNotEmpty == true ? 'Fall 2026' : 'Welcome';
    return LivelyCard(
      gradient: candyGradient,
      child: FloatingShapes(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting()} ${_emoji()}',
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        term,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              BounceTap(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Center(child: Text('🎓', style: TextStyle(fontSize: 34))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return BounceTap(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, tintOf(color, 0.16)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: tintOf(color, 0.22)),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.20),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: livelyGradient(color, shadeOf(color, 0.15)),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
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
                      fontSize: 13,
                      color: kTextSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: value.toDouble()),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => Text(
                      v.round().toString(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: kTextPrimary,
                      ),
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

class _StatSkeletons extends StatelessWidget {
  const _StatSkeletons();

  @override
  Widget build(BuildContext context) {
    return ResponsiveGrid(
      items: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Row(
            children: [
              SkeletonBox(width: 52, height: 52, borderRadius: BorderRadius.all(Radius.circular(16))),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 110, height: 12),
                    SizedBox(height: 8),
                    SkeletonBox(width: 48, height: 26),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Row(
            children: [
              SkeletonBox(width: 52, height: 52, borderRadius: BorderRadius.all(Radius.circular(16))),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 80, height: 12),
                    SizedBox(height: 8),
                    SkeletonBox(width: 40, height: 26),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyDeadlines extends StatelessWidget {
  const _EmptyDeadlines();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kBorder),
      ),
      child: const Column(
        children: [
          Text('🎈', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text(
            'All clear!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: kTextPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'No upcoming deadlines. Enjoy the free time!',
            textAlign: TextAlign.center,
            style: TextStyle(color: kTextSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
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
