import 'package:edtech_app/models/course.dart';
import 'package:edtech_app/models/department.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:edtech_app/widgets/animated_number.dart';
import 'package:edtech_app/widgets/stat_card.dart';
import 'package:flutter/material.dart';

/// Admin screen to manage students: add, edit, delete, enroll in departments.
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
    final api = ApiService();
    await api.deleteStudent(id);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Management'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats cards
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Total Students',
                          value: _students.length,
                          icon: Icons.people,
                          color: kPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
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
                ),
                // Add student form
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Add New Student',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(labelText: 'Full Name'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _emailCtrl,
                                decoration: const InputDecoration(labelText: 'Email'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _phoneCtrl,
                                decoration: const InputDecoration(labelText: 'Contact Phone'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _rollCtrl,
                                decoration: const InputDecoration(labelText: 'Roll Number'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _selectedCourseId,
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
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _nameCtrl.text.isNotEmpty
                                ? _addStudent
                                : null,
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add Student'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Student list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final s = _students[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(child: Text(s['displayName']?.toString().substring(0, 1).toUpperCase() ?? '?')),
                          title: Text(s['displayName'] ?? 'Unknown'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['email'] ?? ''),
                              Text('Phone: ${s['phone'] ?? ''}', style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: kError),
                            onPressed: () => _deleteStudent(s['id']),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
