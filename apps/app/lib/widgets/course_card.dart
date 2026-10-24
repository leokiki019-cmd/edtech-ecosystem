import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';
import 'hover_scale.dart';

class CourseCard extends StatelessWidget {
  final String code;
  final String title;
  final String teacher;
  final int students;
  final int assignments;
  final Color color;

  const CourseCard({
    super.key,
    required this.code,
    required this.title,
    required this.teacher,
    required this.students,
    required this.assignments,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return HoverScale(
      child: Container(
        decoration: BoxDecoration(
          color: kCard,
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: kBorder, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: kTextSecondary),
                  const SizedBox(width: 6),
                  Text(
                    teacher,
                    style: const TextStyle(color: kTextSecondary, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _Stat(
                    icon: Icons.people_outline,
                    value: '$students',
                    label: 'Students',
                  ),
                  const SizedBox(width: 16),
                  _Stat(
                    icon: Icons.assignment_outlined,
                    value: '$assignments',
                    label: 'Assignments',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: kPrimary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: kTextPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: kTextSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
