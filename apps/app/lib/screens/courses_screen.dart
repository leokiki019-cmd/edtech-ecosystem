import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';
import '../widgets/course_card.dart';
import '../widgets/hover_scale.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const _PageHeader(title: 'My Courses', subtitle: 'Enrolled classes & assignments'),
        const SizedBox(height: 24),
        HoverScale(
          child: CourseCard(
            code: 'CS 301',
            title: 'Human-Computer Interaction',
            teacher: 'Dr. Maya Chen',
            students: 3,
            assignments: 4,
            color: kPrimary,
          ),
        ),
        const SizedBox(height: 16),
        HoverScale(
          child: CourseCard(
            code: 'CS 210',
            title: 'Data Structures',
            teacher: 'Prof. Daniel Kim',
            students: 42,
            assignments: 6,
            color: kAccentDark,
          ),
        ),
        const SizedBox(height: 16),
        HoverScale(
          child: CourseCard(
            code: 'DES 150',
            title: 'Design Foundations',
            teacher: 'Prof. Elena Rossi',
            students: 28,
            assignments: 3,
            color: kPink,
          ),
        ),
        const SizedBox(height: 32),
        const _PageHeader(title: 'Quick actions', subtitle: 'Get started'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: HoverScale(
                child: _ActionChip(
                  label: 'Submit assignment',
                  icon: Icons.upload_file,
                  color: kPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HoverScale(
                child: _ActionChip(
                  label: 'View integrity report',
                  icon: Icons.verified,
                  color: kSuccess,
                ),
              ),
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

class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _ActionChip({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, color: kTextPrimary),
        ),
        trailing: const Icon(Icons.chevron_right, color: kBorder, size: 18),
      ),
    );
  }
}
