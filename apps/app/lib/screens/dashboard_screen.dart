import 'package:edtech_app/auth/auth_provider.dart';
import 'package:edtech_app/models/calendar_event.dart';
import 'package:edtech_app/models/course.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:edtech_app/widgets/bounce_tap.dart';
import 'package:edtech_app/widgets/deadline_card.dart';
import 'package:edtech_app/widgets/floating_shapes.dart';
import 'package:edtech_app/widgets/lively_card.dart';
import 'package:edtech_app/widgets/responsive_grid.dart';
import 'package:edtech_app/widgets/skeleton_loader.dart';
import 'package:edtech_app/widgets/staggered_reveal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
          padding: const EdgeInsets.all(kSpaceLg),
          children: [
            const _GreetingCard(),
            const SizedBox(height: kSpaceXl),
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
            const SizedBox(height: kSpaceXl),
            Row(
              children: [
                Text(
                  'Upcoming deadlines',
                  style: context.h4.copyWith(
                    fontWeight: FontWeight.w800,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(width: kSpaceXs),
                const Icon(Icons.waving_hand_rounded, size: 18, color: kAccent),
              ],
            ),
            const SizedBox(height: kSpaceMd),
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
                  padding: const EdgeInsets.only(bottom: kSpaceMd),
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
    return FloatingShapes(
      child: LivelyCard(
        gradient: candyGradient,
        child: Padding(
          padding: const EdgeInsets.all(kSpaceXl),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_greeting()} ${_emoji()}',
                      style: context.body2.copyWith(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: kSpaceXs),
                    Text(
                      user?.displayName ?? 'Student',
                      style: context.h4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 30,
                      ),
                    ),
                    const SizedBox(height: kSpaceSm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        user?.courseIds.isNotEmpty == true ? 'Fall 2026' : 'Welcome',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: kSpaceMd),
              BounceTap(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(kRadiusMd),
                  ),
                  child: const Center(child: Text('🎓', style: TextStyle(fontSize: 38))),
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
        padding: const EdgeInsets.all(kSpaceMd),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, tintOf(color, 0.08)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: tintOf(color, 0.18)),
          borderRadius: BorderRadius.circular(kRadiusMd),
          boxShadow: [cardShadow(color)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(kSpaceSm),
              decoration: iconBubble(color),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: kSpaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.caption.copyWith(
                      color: kTextSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: kSpaceXs),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: value.toDouble()),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => Text(
                      v.round().toString(),
                      style: context.h5.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 34,
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
          padding: const EdgeInsets.all(kSpaceMd),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(kRadiusMd),
          ),
          child: const Row(
            children: [
              SkeletonBox(width: 52, height: 52, borderRadius: BorderRadius.all(Radius.circular(16))),
              SizedBox(width: kSpaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 120, height: 14),
                    SizedBox(height: kSpaceXs),
                    SkeletonBox(width: 56, height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(kSpaceMd),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(kRadiusMd),
          ),
          child: const Row(
            children: [
              SkeletonBox(width: 52, height: 52, borderRadius: BorderRadius.all(Radius.circular(16))),
              SizedBox(width: kSpaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 100, height: 14),
                    SizedBox(height: kSpaceXs),
                    SkeletonBox(width: 48, height: 30),
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
      padding: const EdgeInsets.all(kSpaceXl),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(kRadiusMd),
        border: Border.all(color: kDivider),
      ),
      child: Column(
        children: [
          const Text('🎈', style: TextStyle(fontSize: 56)),
          const SizedBox(height: kSpaceMd),
          Text(
            'All clear!',
            style: context.h5.copyWith(
              fontWeight: FontWeight.w900,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: kSpaceSm),
          Text(
            'No upcoming deadlines. Enjoy the free time!',
            textAlign: TextAlign.center,
            style: context.body2.copyWith(
              color: kTextSecondary,
              fontSize: 14,
              height: 1.7,
            ),
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
          const Text('😵', style: TextStyle(fontSize: 52)),
          const SizedBox(height: kSpaceMd),
          Text(
            error,
            style: context.body2.copyWith(
              color: kTextSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kSpaceLg),
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
