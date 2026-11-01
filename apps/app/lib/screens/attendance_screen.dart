import 'package:edtech_app/models/course.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:edtech_app/widgets/stat_card.dart';
import 'package:flutter/material.dart';

/// Teacher attendance screen: mark present/absent/late for students in a course.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<Course> _courses = [];
  String? _selectedCourseId;
  String _selectedDate = '';
  List<Map<String, dynamic>> _studentsWithAttendance = [];
  bool _loading = true;
  bool _saving = false;

  final Map<String, String> _statusColors = {
    'present': kSuccess.toString(),
    'absent': kError.toString(),
    'late': kWarning.toString(),
    'excused': kAccent.toString(),
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _loadData();
  }

  Future<void> _loadData() async {
    final api = ApiService();
    final courses = await api.getCourses();
    setState(() {
      _courses = courses;
      if (courses.isNotEmpty) {
        _selectedCourseId = courses.first.id;
      }
      _loading = false;
    });
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    if (_selectedCourseId == null) return;
    final api = ApiService();
    final records = await api.getCourseStudentsWithAttendance(
      courseId: _selectedCourseId!,
      date: _selectedDate,
    );
    setState(() {
      _studentsWithAttendance = records;
      _loading = false;
    });
  }

  Future<void> _saveAttendance() async {
    setState(() => _saving = true);
    final api = ApiService();
    final records = _studentsWithAttendance.map((s) => {
      'studentId': s['id'],
      'status': s['status'],
      'notes': s['notes'] ?? '',
    }).toList();
    await api.bulkMarkAttendance(
      courseId: _selectedCourseId!,
      date: _selectedDate,
      records: records,
    );
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Attendance saved successfully')),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present': return kSuccess;
      case 'absent': return kError;
      case 'late': return kWarning;
      case 'excused': return kAccent;
      default: return kTextSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Course selector + date
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCourseId,
                              decoration: const InputDecoration(labelText: 'Course'),
                              items: _courses.map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text('${c.code} - ${c.title}'),
                                  )).toList(),
                              onChanged: (v) {
                                setState(() {
                                  _selectedCourseId = v;
                                  _studentsWithAttendance = [];
                                });
                                _loadAttendance();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
                              controller: TextEditingController(text: _selectedDate),
                              onChanged: (v) {
                                _selectedDate = v;
                              },
                              onSubmitted: (_) => _loadAttendance(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: _studentsWithAttendance.isEmpty ? null : _saveAttendance,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Attendance'),
                        ),
                      ),
                    ],
                  ),
                ),
                // Stats
                if (_studentsWithAttendance.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Present',
                            value: _studentsWithAttendance.where((s) => s['status'] == 'present').length,
                            icon: Icons.check_circle,
                            color: kSuccess,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: StatCard(
                            title: 'Absent',
                            value: _studentsWithAttendance.where((s) => s['status'] == 'absent').length,
                            icon: Icons.cancel,
                            color: kError,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: StatCard(
                            title: 'Late',
                            value: _studentsWithAttendance.where((s) => s['status'] == 'late').length,
                            icon: Icons.access_time,
                            color: kWarning,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Student list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _studentsWithAttendance.length,
                    itemBuilder: (context, index) {
                      final s = _studentsWithAttendance[index];
                      final status = s['status'] as String? ?? 'absent';
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _statusColor(status).withOpacity(0.2),
                            child: Text(
                              (s['displayName'] ?? '?').toString().substring(0, 1).toUpperCase(),
                              style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(s['displayName'] ?? 'Unknown'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Roll: ${s['rollNumber'] ?? s['id']}'),
                              if ((s['notes'] as String?)?.isNotEmpty == true)
                                Text(s['notes'], style: const TextStyle(fontSize: 11, color: kTextSecondary)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...['present', 'absent', 'late', 'excused'].map((st) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    child: ChoiceChip(
                                      label: Text(st.substring(0, 1).toUpperCase(),
                                          style: TextStyle(color: status == st ? Colors.white : kTextSecondary)),
                                      selected: status == st,
                                      selectedColor: _statusColor(st),
                                      onSelected: (_) {
                                        setState(() {
                                          s['status'] = st;
                                        });
                                      },
                                    ),
                                  )),
                              if ((s['notes'] as String?)?.isNotEmpty == true)
                                IconButton(
                                  icon: const Icon(Icons.note, size: 18),
                                  onPressed: () => _editNotes(s),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_saving)
                  const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
              ],
            ),
    );
  }

  void _editNotes(Map<String, dynamic> student) {
    final controller = TextEditingController(text: student['notes'] ?? '');
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Notes'),
        content: TextField(controller: controller, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                student['notes'] = controller.text.trim();
              });
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
