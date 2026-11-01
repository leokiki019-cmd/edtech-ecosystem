import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:edtech_app/widgets/stat_card.dart';
import 'package:flutter/material.dart';

/// Admin screen: drag-and-drop students between departments.
class DepartmentManagementScreen extends StatefulWidget {
  const DepartmentManagementScreen({super.key});

  @override
  State<DepartmentManagementScreen> createState() => _DepartmentManagementScreenState();
}

class _DepartmentManagementScreenState extends State<DepartmentManagementScreen> {
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _allStudents = [];
  Map<String, List<Map<String, dynamic>>> _deptStudents = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final api = ApiService();
    final departments = await api.getDepartments();
    final students = await api.getStudents();
    final deptStudents = <String, List<Map<String, dynamic>>>{};

    for (final dept in departments) {
      final enrolled = await api.getStudentsByDepartment(dept['id']);
      deptStudents[dept['id']] = enrolled;
    }

    setState(() {
      _departments = departments;
      _allStudents = students;
      _deptStudents = deptStudents;
      _loading = false;
    });
  }

  Future<void> _moveStudentToDepartment(String studentId, String departmentId) async {
    final api = ApiService();
    await api.enrollStudentInDepartment(studentId: studentId, departmentId: departmentId);
    await _loadData();
  }

  Future<void> _removeStudentFromDepartment(String studentId, String departmentId) async {
    final api = ApiService();
    await api.unenrollStudentFromDepartment(studentId: studentId, departmentId: departmentId);
    await _loadData();
  }

  Widget _buildStudentChip(Map<String, dynamic> student, String deptId) {
    return Draggable<Map<String, dynamic>>(
      data: student,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(student['displayName'] ?? 'Student',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(student['rollNumber'] ?? student['id'],
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _studentChip(student, deptId, isDragging: true),
      ),
      child: _studentChip(student, deptId),
    );
  }

  Widget _studentChip(Map<String, dynamic> student, String deptId, {bool isDragging = false}) {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDragging ? Colors.grey.withOpacity(0.3) : kSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorder),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: kPrimary.withOpacity(0.2),
                child: Text(
                  (student['displayName'] ?? '?').toString().substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  student['displayName'] ?? 'Unknown',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: kError),
                onPressed: () => _removeStudentFromDepartment(student['id'], deptId),
              ),
            ],
          ),
          if (student['rollNumber'] != null)
            Text(student['rollNumber'],
                style: const TextStyle(fontSize: 10, color: kTextSecondary)),
        ],
      ),
    );
  }

  Widget _buildDepartmentColumn(Map<String, dynamic> dept) {
    final deptId = dept['id'] as String;
    final students = _deptStudents[deptId] ?? [];
    return Expanded(
      child: DragTarget<Map<String, dynamic>>(
        onAccept: (student) {
          // Remove from previous department
          _deptStudents.forEach((dId, studs) {
            studs.removeWhere((s) => s['id'] == student['id']);
          });
          _moveStudentToDepartment(student['id'], deptId);
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            decoration: BoxDecoration(
              color: (candidateData.isNotEmpty ? kPrimary : kSurface).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: candidateData.isNotEmpty ? kPrimary : kBorder,
                width: candidateData.isNotEmpty ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                  ),
                  child: Column(
                    children: [
                      Text(dept['name'] ?? 'Department',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(dept['code'] ?? '',
                          style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(8),
                    children: [
                      ...students.map((s) => _buildStudentChip(s, deptId)),
                      if (students.isEmpty)
                        const Center(
                          child: Text('Drag students here',
                              style: TextStyle(color: kTextSecondary, fontStyle: FontStyle.italic)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Department Management'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(child: StatCard(title: 'Departments', value: _departments.length, icon: Icons.business, color: kPrimary)),
                      const SizedBox(width: 12),
                      Expanded(child: StatCard(title: 'Students', value: _allStudents.length, icon: Icons.people, color: kAccent)),
                    ],
                  ),
                ),
                // Instructions
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Drag students between departments to enroll them.',
                      style: TextStyle(fontStyle: FontStyle.italic, color: kTextSecondary)),
                ),
                const SizedBox(height: 8),
                // Department columns with drag-and-drop
                Expanded(
                  child: Row(
                    children: _departments.map((d) => _buildDepartmentColumn(d)).toList(),
                  ),
                ),
                // Unassigned students at bottom
                if (_allStudents.isNotEmpty)
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(16),
                      children: [
                        const Text('Unassigned:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        ..._allStudents.where((s) {
                          return !_deptStudents.values.any((list) => list.any((x) => x['id'] == s['id']));
                        }).map((s) => _buildStudentChip(s, 'unassigned')),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
