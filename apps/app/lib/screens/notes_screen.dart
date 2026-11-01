import 'package:edtech_app/models/course.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:edtech_app/widgets/stat_card.dart';
import 'package:flutter/material.dart';

/// Teacher notes screen: create and view notes by book name + course code.
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Course> _courses = [];
  List<Map<String, dynamic>> _notes = [];
  String? _selectedCourseId;
  String _filterCourseCode = '';
  bool _loading = true;
  bool _creating = false;

  final TextEditingController _bookNameCtrl = TextEditingController();
  final TextEditingController _courseCodeCtrl = TextEditingController();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _contentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final api = ApiService();
    final courses = await api.getCourses();
    final notes = await api.getTeacherNotes();
    setState(() {
      _courses = courses;
      _notes = notes.map((n) => n.toJson()).toList();
      _loading = false;
    });
  }

  Future<void> _createNote() async {
    if (_titleCtrl.text.isEmpty || _courseCodeCtrl.text.isEmpty) return;
    setState(() => _creating = true);
    final api = ApiService();
    await api.createTeacherNote(
      courseId: _selectedCourseId ?? '',
      bookName: _bookNameCtrl.text.trim(),
      courseCode: _courseCodeCtrl.text.trim(),
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
    );
    _bookNameCtrl.clear();
    _courseCodeCtrl.clear();
    _titleCtrl.clear();
    _contentCtrl.clear();
    setState(() => _creating = false);
    await _loadData();
  }

  Future<void> _deleteNote(String id) async {
    final api = ApiService();
    await api.deleteTeacherNote(id);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teacher Notes'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
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
                      Expanded(
                        child: StatCard(
                          title: 'Total Notes',
                          value: _notes.length,
                          icon: Icons.note,
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
                // Filter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCourseId,
                          decoration: const InputDecoration(labelText: 'Filter by Course'),
                          items: [
                            const DropdownMenuItem(value: '', child: Text('All Courses')),
                            ..._courses.map((c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text('${c.code} - ${c.title}'),
                                )),
                          ],
                          onChanged: (v) => setState(() => _selectedCourseId = v == '' ? null : v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: _filterCourseCode),
                          decoration: const InputDecoration(labelText: 'Course Code (e.g. CIT-301)'),
                          onChanged: (v) => _filterCourseCode = v,
                          onSubmitted: (_) => _loadData(),
                        ),
                      ),
                    ],
                  ),
                ),
                // Notes list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notes.length,
                    itemBuilder: (context, index) {
                      final n = _notes[index];
                      // Apply filters
                      if (_selectedCourseId != null && n['courseId'] != _selectedCourseId) return const SizedBox.shrink();
                      if (_filterCourseCode.isNotEmpty &&
                          (n['courseCode'] as String?)?.toLowerCase().contains(_filterCourseCode.toLowerCase()) != true)
                        return const SizedBox.shrink();
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: kPrimary.withOpacity(0.2),
                            child: Text(n['courseCode']?.toString().substring(0, 3).toUpperCase() ?? '?',
                                style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(n['title'] ?? 'Untitled',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Book: ${n['bookName'] ?? ''}', style: const TextStyle(fontSize: 12)),
                              Text('Code: ${n['courseCode'] ?? ''}',
                                  style: const TextStyle(fontSize: 12, color: kTextSecondary)),
                              Text('${n['createdAt'] ?? ''}',
                                  style: const TextStyle(fontSize: 10, color: kTextSecondary)),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: kError),
                            onPressed: () => _deleteNote(n['id']),
                          ),
                          onTap: () => _viewNote(n),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _showCreateDialog() {
    _bookNameCtrl.clear();
    _courseCodeCtrl.clear();
    _titleCtrl.clear();
    _contentCtrl.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create Note'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCourseId,
                decoration: const InputDecoration(labelText: 'Course'),
                items: [
                  const DropdownMenuItem(value: '', child: Text('Select Course')),
                  ..._courses.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.code} - ${c.title}'),
                      )),
                ],
                onChanged: (v) => setState(() => _selectedCourseId = v == '' ? null : v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bookNameCtrl,
                decoration: const InputDecoration(labelText: 'Book Name (e.g. Interaction Design)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _courseCodeCtrl,
                decoration: const InputDecoration(labelText: 'Course Code (e.g. CIT-301)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Note Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentCtrl,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: _creating ? null : _createNote,
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _viewNote(Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(note['title'] ?? 'Note'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Book: ${note['bookName'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Course Code: ${note['courseCode'] ?? ''}',
                  style: const TextStyle(color: kTextSecondary)),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text(note['content'] ?? '', style: const TextStyle(fontSize: 14, height: 1.5)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
        ],
      ),
    );
  }
}
