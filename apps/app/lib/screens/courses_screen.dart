import 'package:edtech_app/models/course.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';
import '../widgets/course_card.dart';
import '../widgets/responsive_grid.dart';
import '../screens/integrity_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<Course> _courses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final courses = await ApiService.instance.getCourses();
      if (!mounted) return;
      setState(() {
        _courses = courses;
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
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _PageHeader(
          title: 'My Courses',
          subtitle: 'Enrolled classes & assignments',
          onRefresh: _load,
        ),
        const SizedBox(height: 24),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline, color: kError, size: 48),
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: _load,
                  style: FilledButton.styleFrom(foregroundColor: kPrimary),
                  child: const Text('Try again'),
                ),
              ],
            ),
          )
        else
          ResponsiveGrid(
            items: [
              for (final course in _courses)
                CourseCard(
                  code: course.code,
                  title: course.title,
                  teacher: course.teacherName ?? 'Unassigned',
                  students: course.studentCount,
                  assignments: course.openAssignmentCount ?? 0,
                  color: kPrimary,
                ),
            ],
          ),
        const SizedBox(height: 32),
        const _PageHeader(title: 'Quick actions', subtitle: 'Get started'),
        const SizedBox(height: 16),
        ResponsiveGrid(
          items: [
            _ActionChip(
              label: 'Submit assignment',
              icon: Icons.upload_file,
              color: kPrimary,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Assignment submission feature coming soon'),
                    backgroundColor: kPrimary,
                  ),
                );
              },
            ),
            _ActionChip(
              label: 'View integrity report',
              icon: Icons.verified,
              color: kPrimary,
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => IntegrityScreen(),
                ));
              },
            ),
          ],
        ),
      ],
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: kTextPrimary,
              ),
            ),
            const Spacer(),
            Tooltip(
              message: 'Refresh courses',
              child: IconButton(
                icon: const Icon(Icons.refresh, color: kTextSecondary, size: 20),
                onPressed: onRefresh == null
                    ? null
                    : () {
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
          style: const TextStyle(
            fontSize: 13,
            color: kTextSecondary,
          ),
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
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: kCard,
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 12,
            ),
          ],
        ),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kPrimary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, color: kTextPrimary),
          ),
          trailing: const Icon(Icons.chevron_right, color: kBorder, size: 18),
        ),
      ),
    );
  }
}