import 'package:edtech_app/models/course.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:edtech_app/widgets/stat_card.dart';
import 'package:flutter/material.dart';

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
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Attendance saved successfully'),
        backgroundColor: kSuccess,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(kSpaceMd),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
      ),
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
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Attendance'),
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
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedCourseId,
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
                          const SizedBox(width: kSpaceSm),
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
                      const SizedBox(height: kSpaceMd),
                      SizedBox(
                        width: double.infinity,
                        height: kSpaceMd + 24,
                        child: ElevatedButton.icon(
                          onPressed: _studentsWithAttendance.isEmpty ? null : _saveAttendance,
                          icon: const Icon(Icons.save_rounded),
                          label: const Text('Save Attendance'),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_studentsWithAttendance.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: kSpaceLg),
                    child: Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: 'Present',
                            value: _studentsWithAttendance.where((s) => s['status'] == 'present').length,
                            icon: Icons.check_circle_rounded,
                            color: kSuccess,
                          ),
                        ),
                        const SizedBox(width: kSpaceSm),
                        Expanded(
                          child: StatCard(
                            title: 'Absent',
                            value: _studentsWithAttendance.where((s) => s['status'] == 'absent').length,
                            icon: Icons.cancel_rounded,
                            color: kError,
                          ),
                        ),
                        const SizedBox(width: kSpaceSm),
                        Expanded(
                          child: StatCard(
                            title: 'Late',
                            value: _studentsWithAttendance.where((s) => s['status'] == 'late').length,
                            icon: Icons.access_time_rounded,
                            color: kWarning,
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(kSpaceLg),
                    itemCount: _studentsWithAttendance.length,
                    itemBuilder: (context, index) {
                      final s = _studentsWithAttendance[index];
                      final status = s['status'] as String? ?? 'absent';
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
                              backgroundColor: _statusColor(status).withValues(alpha: 0.15),
                              child: Text(
                                (s['displayName'] ?? '?').toString().substring(0, 1).toUpperCase(),
                                style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold, fontSize: 14),
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
                                  'Roll: ${s['rollNumber'] ?? s['id']}',
                                  style: const TextStyle(fontSize: 12, color: kTextBody),
                                ),
                                if ((s['notes'] as String?)?.isNotEmpty == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: kSpaceXs),
                                    child: Text(
                                      s['notes'],
                                      style: const TextStyle(fontSize: 11, color: kTextSecondary),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Wrap(
                              spacing: kSpaceXs,
                              children: [
                                ...['present', 'absent', 'late', 'excused'].map((st) => Container(
                                  decoration: BoxDecoration(
                                    color: status == st ? _statusColor(st) : Colors.transparent,
                                    border: Border.all(color: status == st ? _statusColor(st) : kDivider),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20),
                                      onTap: () {
                                        setState(() {
                                          s['status'] = st;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        child: Text(
                                          st.substring(0, 1).toUpperCase(),
                                          style: TextStyle(
                                            color: status == st ? Colors.white : kTextSecondary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )),
                                if ((s['notes'] as String?)?.isNotEmpty == true)
                                  IconButton(
                                    icon: const Icon(Icons.note, size: 18, color: kPrimary),
                                    onPressed: () => _editNotes(s),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_saving)
                  const Padding(padding: EdgeInsets.all(kSpaceLg), child: Center(child: CircularProgressIndicator())),
              ],
            ),
    );
  }

  void _editNotes(Map<String, dynamic> student) {
    final controller = TextEditingController(text: student['notes'] ?? '');
    showDialog(
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
                'Add Notes',
                style: context.h4.copyWith(
                  fontWeight: FontWeight.w900,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: kSpaceMd),
              TextField(controller: controller, maxLines: 3),
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
                      onPressed: () {
                        setState(() {
                          student['notes'] = controller.text.trim();
                        });
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('Save'),
                    ),
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
