import 'dart:async';

import 'package:edtech_app/models/college.dart';
import 'package:edtech_app/models/course.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';
import '../widgets/bounce_tap.dart';
import '../widgets/course_card.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/staggered_reveal.dart';
import '../screens/integrity_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<Course> _courses = [];
  College? _college;
  Timer? _liveTimer;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    // Real-time refresh: keep the college profile in sync with the API.
    _liveTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _refreshCollegeSilently(),
    );
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  /// Background poll that never flashes the loading state.
  Future<void> _refreshCollegeSilently() async {
    try {
      final college = await ApiService.instance.getCollege();
      if (!mounted) return;
      setState(() => _college = college);
    } catch (_) {
      // Keep showing the last good snapshot.
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.instance.getCourses(),
        ApiService.instance.getCollege(),
      ]);
      if (!mounted) return;
      setState(() {
        _courses = results[0] as List<Course>;
        _college = results[1] as College;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      color: kPrimary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          if (_college != null) ...[
            _CollegeBanner(college: _college!),
            const SizedBox(height: 24),
            const _PageHeader(
              title: 'Departments 🏛️',
              subtitle: 'Every programme offered at CTTC',
            ),
            const SizedBox(height: 16),
            ..._programmePanels(_college!),
            const SizedBox(height: 28),
          ],
          _PageHeader(
            title: 'My Courses 📚',
            subtitle: 'Enrolled classes & assignments',
            onRefresh: _load,
          ),
          const SizedBox(height: 24),
          if (_loading)
            const _CourseSkeletons()
          else if (_error != null)
            Center(
              child: Column(
                children: [
                  const Text('😵', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try again'),
                    style: FilledButton.styleFrom(foregroundColor: kPrimary),
                  ),
                ],
              ),
            )
          else if (_courses.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: kBorder),
              ),
              child: const Column(
                children: [
                  Text('🌱', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text(
                    'No courses yet',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextPrimary),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Courses you enroll in will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kTextSecondary, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            StaggeredReveal(
              childCount: _courses.length,
              itemBuilder: (context, index) {
                final course = _courses[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: CourseCard(
                    code: course.code,
                    title: course.title,
                    teacher: course.teacherName ?? 'Unassigned',
                    students: course.studentCount,
                    assignments: course.openAssignmentCount ?? 0,
                    color: kTabColors[1 % kTabColors.length],
                  ),
                );
              },
            ),
          const SizedBox(height: 32),
          const _PageHeader(title: 'Quick actions ⚡', subtitle: 'Jump right in'),
          const SizedBox(height: 16),
          ResponsiveGrid(
            items: [
              _ActionChip(
                label: 'Submit assignment',
                icon: Icons.upload_file_rounded,
                color: kPrimary,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Assignment submission feature coming soon 🚀'),
                      backgroundColor: kPrimary,
                    ),
                  );
                },
              ),
              _ActionChip(
                label: 'View integrity report',
                icon: Icons.verified_rounded,
                color: kSuccess,
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const IntegrityScreen(),
                  ));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CourseSkeletons extends StatelessWidget {
  const _CourseSkeletons();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [SkeletonCard(), SkeletonCard(), SkeletonCard()],
    );
  }
}

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onRefresh;
  const _PageHeader({required this.title, required this.subtitle, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: kTextPrimary,
                ),
              ),
            ),
            if (onRefresh != null)
              Tooltip(
                message: 'Refresh courses',
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: kTextSecondary, size: 20),
                  onPressed: () {
                    onRefresh!();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Refreshing courses'),
                        backgroundColor: kPrimary,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 13, color: kTextSecondary),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BounceTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tintOf(color, 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, color: kTextPrimary),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ),
      ),
    );
  }
}

class _CollegeBanner extends StatelessWidget {
  final College college;
  const _CollegeBanner({required this.college});

  @override
  Widget build(BuildContext context) {
    return BounceTap(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: candyGradient,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    college.shortName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Center(child: Text('🎓', style: TextStyle(fontSize: 24))),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              college.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${college.departmentCount} programmes · live from campus',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One section per flyer panel: "3 YEARS PROGRAMMES", "2 YEARS", "6 MONTHS"
/// and "2 YEARS PARAMEDICAL", each with its own grid of tiles.
List<Widget> _programmePanels(College college) {
  final panels = <Widget>[];
  var panelIndex = 0;
  college.departmentsByCategory.forEach((category, departments) {
    panels.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                gradient: livelyGradient(
                  kTabColors[panelIndex % kTabColors.length],
                  shadeOf(kTabColors[panelIndex % kTabColors.length], 0.25),
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: kTabColors[panelIndex % kTabColors.length]
                        .withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                category.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${departments.length}',
              style: const TextStyle(
                color: kTextSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
    panels.add(
      ResponsiveGrid(
        items: [
          for (var i = 0; i < departments.length; i++)
            _DepartmentTile(
              department: departments[i],
              color: kTabColors[(panelIndex + i) % kTabColors.length],
            ),
        ],
      ),
    );
    panels.add(const SizedBox(height: 20));
    panelIndex++;
  });
  return panels;
}

class _DepartmentTile extends StatelessWidget {
  final Department department;
  final Color color;
  const _DepartmentTile({required this.department, required this.color});

  @override
  Widget build(BuildContext context) {
    final isTwoYear = department.durationMonths <= 24;
    return BounceTap(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${department.name} (${department.code}) — ${department.durationLabel}',
            ),
            backgroundColor: color,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tintOf(color, 0.35)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: tintOf(color, 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  department.code,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    department.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isTwoYear ? Icons.timer_outlined : Icons.menu_book_rounded,
                        size: 13,
                        color: kTextSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        department.durationLabel,
                        style: const TextStyle(fontSize: 12, color: kTextSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isTwoYear ? tintOf(kSuccess, 0.18) : tintOf(color, 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                department.durationBadge,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: isTwoYear ? kSuccess : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
