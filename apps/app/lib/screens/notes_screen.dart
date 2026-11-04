import 'package:edtech_app/models/course.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:edtech_app/widgets/bounce_tap.dart';
import 'package:edtech_app/widgets/stat_card.dart';
import 'package:flutter/material.dart';

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
    setState(() => _loading = true);
    final api = ApiService();
    final courses = await api.getCourses();
    final notes = await api.getTeacherNotes();
    if (!mounted) return;
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
                        'Teacher Notes',
                        style: context.h3.copyWith(
                          fontWeight: FontWeight.w900,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: kSpaceXs),
                      Text(
                        'Organise notes by book and course code',
                        style: context.body2.copyWith(color: kTextSecondary),
                      ),
                      const SizedBox(height: kSpaceLg),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              title: 'Total Notes',
                              value: _notes.length,
                              icon: Icons.note,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCourseId,
                              decoration: const InputDecoration(
                                labelText: 'Filter by Course',
                                hintText: 'All courses',
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: '',
                                  child: Text('All Courses'),
                                ),
                                ..._courses.map((c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text('${c.code} - ${c.title}'),
                                    )),
                              ],
                              onChanged: (v) => setState(() => _selectedCourseId = v == '' ? null : v),
                            ),
                          ),
                          const SizedBox(width: kSpaceSm),
                          SizedBox(
                            width: 200,
                            child: TextField(
                              controller: TextEditingController(text: _filterCourseCode),
                              decoration: const InputDecoration(
                                labelText: 'Course Code',
                                hintText: 'e.g. CIT-301',
                              ),
                              onChanged: (v) => _filterCourseCode = v,
                              onSubmitted: (_) => _loadData(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: kSpaceLg),
                if (_notes.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('📝', style: TextStyle(fontSize: 56)),
                          const SizedBox(height: kSpaceMd),
                          Text(
                            'No notes yet',
                            style: context.h4.copyWith(
                              fontWeight: FontWeight.w900,
                              color: kTextPrimary,
                            ),
                          ),
                          const SizedBox(height: kSpaceSm),
                          Text(
                            'Create your first note to get started.',
                            textAlign: TextAlign.center,
                            style: context.body2.copyWith(color: kTextSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(kSpaceLg),
                      itemCount: _notes.length,
                      itemBuilder: (context, index) {
                        final n = _notes[index];
                        if (_selectedCourseId != null && n['courseId'] != _selectedCourseId) return const SizedBox.shrink();
                        if (_filterCourseCode.isNotEmpty &&
                            (n['courseCode'] as String?)?.toLowerCase().contains(_filterCourseCode.toLowerCase()) != true)
                          return const SizedBox.shrink();
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
                                  n['courseCode']?.toString().substring(0, 3).toUpperCase() ?? '?',
                                  style: const TextStyle(color: kPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              title: Text(
                                n['title'] ?? 'Untitled',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: kTextPrimary),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: kSpaceXs),
                                  Text(
                                    'Book: ${n['bookName'] ?? ''}',
                                    style: const TextStyle(fontSize: 13, color: kTextBody),
                                  ),
                                  const SizedBox(height: kSpaceXs),
                                  Text(
                                    'Code: ${n['courseCode'] ?? ''}',
                                    style: const TextStyle(fontSize: 12, color: kTextSecondary),
                                  ),
                                  const SizedBox(height: kSpaceXs),
                                  Text(
                                    '${n['createdAt'] ?? ''}',
                                    style: const TextStyle(fontSize: 11, color: kTextSecondary),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: kError),
                                onPressed: () => _deleteNote(n['id']),
                              ),
                              onTap: () => _viewNote(n),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
            floatingActionButton: BounceTap(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: candyGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: kPrimary.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(child: Icon(Icons.add_rounded, color: Colors.white, size: 28)),
        ),
        onTap: _showCreateDialog,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showCreateDialog() {
    _bookNameCtrl.clear();
    _courseCodeCtrl.clear();
    _titleCtrl.clear();
    _contentCtrl.clear();
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
                'Create Note',
                style: context.h4.copyWith(
                  fontWeight: FontWeight.w900,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: kSpaceLg),
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
              const SizedBox(height: kSpaceMd),
              TextField(
                controller: _bookNameCtrl,
                decoration: const InputDecoration(labelText: 'Book Name (e.g. Interaction Design)'),
              ),
              const SizedBox(height: kSpaceMd),
              TextField(
                controller: _courseCodeCtrl,
                decoration: const InputDecoration(labelText: 'Course Code (e.g. CIT-301)'),
              ),
              const SizedBox(height: kSpaceMd),
              TextField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Note Title'),
              ),
              const SizedBox(height: kSpaceMd),
              TextField(
                controller: _contentCtrl,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 4,
              ),
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
                      onPressed: _creating ? null : _createNote,
                      child: const Text('Create'),
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

  void _viewNote(Map<String, dynamic> note) {
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
                note['title'] ?? 'Note',
                style: context.h4.copyWith(
                  fontWeight: FontWeight.w900,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: kSpaceMd),
              Text(
                'Book: ${note['bookName'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: kSpaceXs),
              Text(
                'Course Code: ${note['courseCode'] ?? ''}',
                style: const TextStyle(color: kTextSecondary),
              ),
              const SizedBox(height: kSpaceMd),
              const Divider(),
              const SizedBox(height: kSpaceMd),
              Text(
                note['content'] ?? '',
                style: const TextStyle(fontSize: 14, height: 1.7, color: kTextBody),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
