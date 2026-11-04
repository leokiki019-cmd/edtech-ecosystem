import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:edtech_app/widgets/stat_card.dart';
import 'package:flutter/material.dart';

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
    setState(() => _loading = true);
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
          width: 140,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kPrimary.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(kRadiusMd),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student['displayName'] ?? 'Student',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                student['rollNumber'] ?? student['id'],
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _studentChip(student, deptId, isDragging: true),
      ),
      child: _studentChip(student, deptId),
    );
  }

  Widget _studentChip(Map<String, dynamic> student, String deptId, {bool isDragging = false}) {
    return Container(
      margin: const EdgeInsets.all(kSpaceSm),
      padding: const EdgeInsets.all(kSpaceSm),
      decoration: BoxDecoration(
        color: isDragging ? Colors.grey.withValues(alpha: 0.3) : kSurface,
        borderRadius: BorderRadius.circular(kRadiusMd),
        border: Border.all(color: kDivider),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: kPrimary.withValues(alpha: 0.2),
                child: Text(
                  (student['displayName'] ?? '?').toString().substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: kSpaceSm),
              Expanded(
                child: Text(
                  student['displayName'] ?? 'Unknown',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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
            Text(
              student['rollNumber'],
              style: const TextStyle(fontSize: 11, color: kTextSecondary),
            ),
        ],
      ),
    );
  }

  Widget _buildDepartmentColumn(Map<String, dynamic> dept) {
    final deptId = dept['id'] as String;
    final students = _deptStudents[deptId] ?? [];
    return Expanded(
      child: DragTarget<Map<String, dynamic>>(
        onAcceptWithDetails: (details) {
          final student = details.data;
          _deptStudents.forEach((dId, studs) {
            studs.removeWhere((s) => s['id'] == student['id']);
          });
          _moveStudentToDepartment(student['id'], deptId);
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            decoration: BoxDecoration(
              color: (candidateData.isNotEmpty ? kPrimary : kSurface).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(kRadiusMd),
              border: Border.all(
                color: candidateData.isNotEmpty ? kPrimary : kDivider,
                width: candidateData.isNotEmpty ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(kSpaceMd),
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(kRadiusMd),
                      topRight: Radius.circular(kRadiusMd),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        dept['name'] ?? 'Department',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const SizedBox(height: kSpaceXs),
                      Text(
                        dept['code'] ?? '',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(kSpaceSm),
                    children: [
                      ...students.map((s) => _buildStudentChip(s, deptId)),
                      if (students.isEmpty)
                        const Center(
                          child: Text(
                            'Drag students here',
                            style: TextStyle(color: kTextSecondary, fontStyle: FontStyle.italic),
                          ),
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
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Department Management'),
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: kTextPrimary,
      ),
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
                        'Departments',
                        style: context.h3.copyWith(
                          fontWeight: FontWeight.w900,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: kSpaceXs),
                      Text(
                        'Drag students between departments to enroll them',
                        style: context.body2.copyWith(color: kTextSecondary),
                      ),
                      const SizedBox(height: kSpaceLg),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Departments',
                              value: _departments.length,
                              icon: Icons.business,
                              color: kPrimary,
                            ),
                          ),
                          const SizedBox(width: kSpaceSm),
                          Expanded(
                            child: StatCard(
                              title: 'Students',
                              value: _allStudents.length,
                              icon: Icons.people,
                              color: kAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: _departments.map((d) => _buildDepartmentColumn(d)).toList(),
                  ),
                ),
                if (_allStudents.isNotEmpty)
                  Container(
                    height: 130,
                    padding: const EdgeInsets.all(kSpaceLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Unassigned',
                          style: TextStyle(fontWeight: FontWeight.w800, color: kTextPrimary, fontSize: 14),
                        ),
                        const SizedBox(height: kSpaceSm),
                        SizedBox(
                          height: 80,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              ..._allStudents.where((s) {
                                return !_deptStudents.values.any((list) => list.any((x) => x['id'] == s['id']));
                              }).map((s) => _buildStudentChip(s, 'unassigned')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
