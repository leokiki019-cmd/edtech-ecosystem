import 'dart:async';

import 'package:edtech_app/models/college.dart';
import 'package:edtech_app/models/course.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:edtech_app/widgets/bounce_tap.dart';
import 'package:edtech_app/widgets/course_card.dart';
import 'package:edtech_app/widgets/responsive_grid.dart';
import 'package:edtech_app/widgets/skeleton_loader.dart';
import 'package:edtech_app/widgets/staggered_reveal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:edtech_app/screens/integrity_screen.dart';

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

  Future<void> _refreshCollegeSilently() async {
    try {
      final college = await ApiService.instance.getCollege();
      if (!mounted) return;
      if (college != null) setState(() => _college = college);
    } catch (_) {}
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
        _college = results[1] as College? ?? College.demo;
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

  Future<void> _showSubmitAssignmentDialog(BuildContext context) async {
    if (_courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No courses available to submit to'),
          backgroundColor: kWarning,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(kSpaceMd),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
        ),
      );
      return;
    }
    String? selectedCourseId;
    final TextEditingController titleCtrl = TextEditingController();
    final TextEditingController briefCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusXl)),
        child: Padding(
          padding: const EdgeInsets.all(kSpaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Submit Assignment',
                style: context.h4.copyWith(
                  fontWeight: FontWeight.w900,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: kSpaceLg),
              DropdownButtonFormField<String>(
                hint: const Text('Select course'),
                value: selectedCourseId,
                items: _courses
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.code} - ${c.title}'),
                        ))
                    .toList(),
                onChanged: (v) => selectedCourseId = v,
              ),
              const SizedBox(height: kSpaceMd),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Assignment title'),
              ),
              const SizedBox(height: kSpaceMd),
              TextField(
                controller: briefCtrl,
                decoration: const InputDecoration(labelText: 'Brief / description'),
                maxLines: 2,
              ),
              const SizedBox(height: kSpaceXl),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: kSpaceSm),
                  Expanded(
                    child: FilledButton(
                      onPressed: selectedCourseId == null || titleCtrl.text.isEmpty
                          ? null
                          : () {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Assignment submitted successfully! ✅'),
                                  backgroundColor: kSuccess,
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(kSpaceMd),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
                                ),
                              );
                              titleCtrl.clear();
                              briefCtrl.clear();
                            },
                      child: const Text('Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    titleCtrl.dispose();
    briefCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      color: kPrimary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(kSpaceLg),
        children: [
          if (_college != null) ...[
            _CollegeBanner(college: _college!),
            const SizedBox(height: kSpaceXl),
            _PageHeader(
              title: 'Departments',
              subtitle: 'Every programme offered at CTTC',
            ),
            const SizedBox(height: kSpaceMd),
            ..._programmePanels(_college!),
            const SizedBox(height: kSpaceXxl),
          ],
          _PageHeader(
            title: 'My Courses',
            subtitle: 'Enrolled classes & assignments',
            onRefresh: _load,
          ),
          const SizedBox(height: kSpaceMd),
          if (_loading)
            const Column(
              children: [SkeletonCard(), SkeletonCard(), SkeletonCard()],
            )
          else if (_error != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('😵', style: TextStyle(fontSize: 52)),
                  const SizedBox(height: kSpaceMd),
                  Text(_error!, style: context.body2.copyWith(color: kTextSecondary, fontSize: 13)),
                  const SizedBox(height: kSpaceLg),
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
              padding: const EdgeInsets.all(kSpaceXxl),
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(kRadiusMd),
                border: Border.all(color: kDivider),
              ),
              child: Column(
                children: [
                  const Text('🌱', style: TextStyle(fontSize: 56)),
                  const SizedBox(height: kSpaceMd),
                  Text(
                    'No courses yet',
                    style: context.h4.copyWith(
                      fontWeight: FontWeight.w900,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: kSpaceSm),
                  Text(
                    'Courses you enroll in will appear here.',
                    textAlign: TextAlign.center,
                    style: context.body2.copyWith(color: kTextSecondary, fontSize: 14),
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
                  padding: const EdgeInsets.only(bottom: kSpaceMd),
                  child: CourseCard(
                    code: course.code,
                    title: course.title,
                    teacher: course.teacherName ?? 'Unassigned',
                    students: course.studentCount,
                    assignments: course.openAssignmentCount ?? 0,
                  ),
                );
              },
            ),
          const SizedBox(height: kSpaceXxl),
          const _PageHeader(title: 'Quick actions', subtitle: 'Jump right in'),
          const SizedBox(height: kSpaceMd),
          ResponsiveGrid(
            items: [
              _ActionChip(
                label: 'Submit assignment',
                icon: Icons.upload_file_rounded,
                color: kPrimary,
                onTap: () {
                  _showSubmitAssignmentDialog(context);
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
                style: context.h4.copyWith(
                  fontWeight: FontWeight.w900,
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
                      SnackBar(
                        content: const Text('Refreshing courses'),
                        backgroundColor: kPrimary,
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(kSpaceMd),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
        const SizedBox(height: kSpaceXs),
        Text(
          subtitle,
          style: context.body2.copyWith(fontSize: 13, color: kTextSecondary),
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
          borderRadius: BorderRadius.circular(kRadiusMd),
          boxShadow: [cardShadow(color)],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: kSpaceMd, vertical: kSpaceSm),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: tintOf(color, 0.12),
              borderRadius: BorderRadius.circular(kRadiusSm),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(
            label,
            style: context.body2.copyWith(fontWeight: FontWeight.w800, color: kTextPrimary, fontSize: 15),
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
      onTap: () => context.go('/departments'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(kSpaceXl),
        decoration: BoxDecoration(
          gradient: candyGradient,
          borderRadius: BorderRadius.circular(kRadiusXl),
          boxShadow: [
            BoxShadow(
              color: kPrimary.withValues(alpha: 0.30),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    college.shortName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(kRadiusMd),
                  ),
                  child: const Center(child: Text('🎓', style: TextStyle(fontSize: 30))),
                ),
              ],
            ),
            const SizedBox(height: kSpaceLg),
            Text(
              college.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
            const SizedBox(height: kSpaceXs),
            Text(
              '${college.departmentCount} programmes · live from campus',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<Widget> _programmePanels(College college) {
  final panels = <Widget>[];
  var panelIndex = 0;
  college.departmentsByCategory.forEach((category, departments) {
    panels.add(
      Padding(
        padding: const EdgeInsets.only(bottom: kSpaceSm, top: kSpaceXs),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: livelyGradient(
                  kTabColors[panelIndex % kTabColors.length],
                  shadeOf(kTabColors[panelIndex % kTabColors.length], 0.25),
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: kTabColors[panelIndex % kTabColors.length].withValues(alpha: 0.3),
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
            const SizedBox(width: kSpaceSm),
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
    panels.add(const SizedBox(height: kSpaceLg));
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
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(kSpaceMd),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(kSpaceMd),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(kRadiusMd),
          border: Border.all(color: tintOf(color, 0.30)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tintOf(color, 0.12),
                borderRadius: BorderRadius.circular(kRadiusSm),
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
            const SizedBox(width: kSpaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    department.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: kSpaceXs),
                  Row(
                    children: [
                      Icon(
                        isTwoYear ? Icons.timer_outlined : Icons.menu_book_rounded,
                        size: 13,
                        color: kTextSecondary,
                      ),
                      const SizedBox(width: kSpaceXs),
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isTwoYear ? tintOf(kSuccess, 0.15) : tintOf(color, 0.10),
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
