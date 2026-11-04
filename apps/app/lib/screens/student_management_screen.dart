import 'package:edtech_app/models/course.dart';
import 'package:edtech_app/models/department.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:edtech_app/widgets/stat_card.dart';
import 'package:flutter/material.dart';

class StudentManagementScreen extends StatefulWidget {
  const StudentManagementScreen({super.key});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  List<Map<String, dynamic>> _students = [];
  List<Course> _courses = [];
  List<Department> _departments = [];
  bool _loading = true;
  String? _selectedCourseId;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _rollCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final api = ApiService();
    final courses = await api.getCourses();
    final students = await api.getStudents();
    setState(() {
      _courses = courses;
      _students = students;
      _loading = false;
    });
  }

  Future<void> _addStudent() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final api = ApiService();
    await api.createStudent(
      displayName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      courseId: _selectedCourseId,
    );
    _nameCtrl.clear();
    _emailCtrl.clear();
    _phoneCtrl.clear();
    _rollCtrl.clear();
    setState(() => _selectedCourseId = null);
    await _loadData();
  }

  Future<void> _deleteStudent(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
        title: const Text('Delete student?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: kError),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final api = ApiService();
    await api.deleteStudent(id);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(kSpaceLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Student Management',
                        style: context.h3.copyWith(
                          fontWeight: FontWeight.w900,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: kSpaceXs),
                      Text(
                        'Add, edit, and manage your student roster',
                        style: context.body2.copyWith(color: kTextSecondary),
                      ),
                      const SizedBox(height: kSpaceLg),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Total Students',
                              value: _students.length,
                              icon: Icons.people,
                              color: kPrimary,
                            ),
                          ),
                          const SizedBox(width: kSpaceSm),
                          Expanded(
                            child: StatCard(
                              title: 'Courses',
                              value: _courses.length,
                              icon: Icons.school,
                              color: kAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: kSpaceLg),
                  child: Card(
                    elevation: 0,
                    color: kSurface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
                    child: Padding(
                      padding: const EdgeInsets.all(kSpaceMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Add New Student',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: kTextPrimary),
                          ),
                          const SizedBox(height: kSpaceMd),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nameCtrl,
                                  decoration: const InputDecoration(labelText: 'Full Name'),
                                ),
                              ),
                              const SizedBox(width: kSpaceSm),
                              Expanded(
                                child: TextField(
                                  controller: _emailCtrl,
                                  decoration: const InputDecoration(labelText: 'Email'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: kSpaceMd),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _phoneCtrl,
                                  decoration: const InputDecoration(labelText: 'Contact Phone'),
                                ),
                              ),
                              const SizedBox(width: kSpaceSm),
                              Expanded(
                                child: TextField(
                                  controller: _rollCtrl,
                                  decoration: const InputDecoration(labelText: 'Roll Number'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: kSpaceMd),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCourseId,
                            decoration: const InputDecoration(labelText: 'Assign Course'),
                            items: [
                              const DropdownMenuItem(value: '', child: Text('None')),
                              ..._courses.map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text('${c.code} - ${c.title}'),
                                  )),
                            ],
                            onChanged: (v) => setState(() => _selectedCourseId = v == '' ? null : v),
                          ),
                          const SizedBox(height: kSpaceLg),
                          SizedBox(
                            width: double.infinity,
                            height: kSpaceMd + 24,
                            child: FilledButton.icon(
                              onPressed: _nameCtrl.text.isNotEmpty ? _addStudent : null,
                              icon: const Icon(Icons.person_add_rounded),
                              label: const Text('Add Student'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: kSpaceLg),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: kSpaceLg),
                  child: Row(
                    children: [
                      Text(
                        'Student Roster',
                        style: context.h4.copyWith(
                          fontWeight: FontWeight.w800,
                          color: kTextPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (_students.isNotEmpty)
                        Text(
                          '${_students.length} students',
                          style: context.caption.copyWith(color: kTextSecondary, fontWeight: FontWeight.w700),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(kSpaceLg),
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final s = _students[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: kSpaceMd),
                        child: Container(
                          decoration: BoxDecoration(
                            color: kCard,
                            borderRadius: BorderRadius.circular(kRadiusMd),
                            border: Border.all(color: kDivider),
                            boxShadow: [cardShadow(kTextSecondary)],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(kSpaceMd),
                            leading: CircleAvatar(
                              backgroundColor: kPrimary.withValues(alpha: 0.15),
                              child: Text(
                                s['displayName']?.toString().substring(0, 1).toUpperCase() ?? '?',
                                style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            title: Text(
                              s['displayName'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kTextPrimary),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: kSpaceXs),
                                Text(
                                  s['email'] ?? '',
                                  style: const TextStyle(fontSize: 13, color: kTextBody),
                                ),
                                const SizedBox(height: kSpaceXs),
                                Text(
                                  'Phone: ${s['phone'] ?? ''}',
                                  style: const TextStyle(fontSize: 12, color: kTextSecondary),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: kError),
                              onPressed: () => _deleteStudent(s['id']),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_students.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('👥', style: TextStyle(fontSize: 56)),
                          const SizedBox(height: kSpaceMd),
                          Text(
                            'No students yet',
                            style: context.h4.copyWith(
                              fontWeight: FontWeight.w900,
                              color: kTextPrimary,
                            ),
                          ),
                          const SizedBox(height: kSpaceSm),
                          Text(
                            'Add your first student above.',
                            textAlign: TextAlign.center,
                            style: context.body2.copyWith(color: kTextSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
