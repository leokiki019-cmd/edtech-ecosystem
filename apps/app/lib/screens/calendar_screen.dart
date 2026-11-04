import 'package:edtech_app/auth/auth_provider.dart';
import 'package:edtech_app/models/calendar_event.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/deadline_card.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/staggered_reveal.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade;
  List<CalendarEvent> _events = [];
  List<Map<String, dynamic>> _departments = [];
  String? _selectedDepartmentId;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      value: 1.0,
    );
    _loadDepartments();
    _load();
  }

  Future<void> _loadDepartments() async {
    try {
      final departments = await ApiService.instance.getDepartments();
      if (!mounted) return;
      setState(() => _departments = departments);
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final events = await ApiService.instance.getCalendar(
        null,
        departmentId: _selectedDepartmentId,
      );
      if (!mounted) return;
      setState(() {
        _events = List<CalendarEvent>.from(events)
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
        _loading = false;
      });
      _fade.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _pickDepartment(String? value) async {
    setState(() => _selectedDepartmentId =
        (value == null || value.isEmpty) ? null : value);
    await _load();
  }

  Future<void> _showEventDialog({CalendarEvent? event}) async {
    final draft = await showDialog<_EventDraft>(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusXl)),
        child: _EventEditorDialog(
          event: event,
          departments: _departments,
          initialDepartmentId: _selectedDepartmentId,
        ),
      ),
    );
    if (draft == null || !mounted) return;

    setState(() => _saving = true);
    final api = ApiService.instance;
    try {
      if (draft.delete && event != null) {
        await api.deleteCalendarEvent(event.id);
      } else if (event == null) {
        await api.createCalendarEvent(
          title: draft.title,
          kind: draft.kind,
          startsAt: draft.startsAt,
          endsAt: draft.endsAt,
          departmentId: draft.departmentId,
        );
      } else {
        await api.updateCalendarEvent(
          id: event.id,
          title: draft.title,
          kind: draft.kind,
          startsAt: draft.startsAt,
          endsAt: draft.endsAt,
          departmentId: draft.departmentId,
        );
      }
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(draft.delete ? 'Event deleted' : 'Calendar updated'),
          backgroundColor: kPrimary,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(kSpaceMd),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save event: $e'),
          backgroundColor: kError,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(kSpaceMd),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().user?.role == 'admin';

    return FadeTransition(
      opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
      child: RefreshIndicator(
        onRefresh: _load,
        color: kPrimary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(kSpaceLg),
          children: [
            _buildHeader(isAdmin),
            const SizedBox(height: kSpaceMd),
            _buildDepartmentFilter(),
            if (isAdmin)
              Padding(
                padding: const EdgeInsets.only(top: kSpaceSm),
                child: Text(
                  _saving
                      ? 'Saving changes…'
                      : 'Admin: add events, or tap an event to edit or delete it.',
                  style: context.body2.copyWith(
                    fontSize: 12,
                    color: kTextSecondary,
                  ),
                ),
              ),
            const SizedBox(height: kSpaceLg),
            if (_loading)
              const Column(
                children: [SkeletonCard(), SkeletonCard(), SkeletonCard()],
              )
            else if (_error != null)
              _ErrorState(error: _error!, onRetry: _load)
            else if (_events.isEmpty)
              Container(
                padding: const EdgeInsets.all(kSpaceXxl),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(kRadiusMd),
                  border: Border.all(color: kDivider),
                ),
                child: Column(
                  children: [
                    const Text('🗓️', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: kSpaceMd),
                    Text(
                      'Nothing scheduled',
                      style: context.h4.copyWith(
                        fontWeight: FontWeight.w900,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: kSpaceSm),
                    Text(
                      'Your calendar is wide open!',
                      textAlign: TextAlign.center,
                      style: context.body2.copyWith(color: kTextSecondary, fontSize: 14, height: 1.7),
                    ),
                  ],
                ),
              )
            else
              StaggeredReveal(
                childCount: _events.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: kSpaceMd),
                  child: DeadlineCard(
                    event: _events[index],
                    onTap: isAdmin
                        ? () => _showEventDialog(event: _events[index])
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isAdmin) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Calendar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: kTextPrimary,
            ),
          ),
        ),
        if (isAdmin)
          Tooltip(
            message: 'Add calendar event',
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline, color: kPrimary),
              onPressed: _saving ? null : () => _showEventDialog(),
            ),
          ),
        Tooltip(
          message: 'Refresh calendar',
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: kTextSecondary, size: 20),
            onPressed: () {
              _load();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Refreshing calendar'),
                  backgroundColor: kPrimary,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(kSpaceMd),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusMd)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentFilter() {
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(kRadiusMd),
        border: Border.all(color: kDivider),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedDepartmentId ?? '',
        isDense: true,
        decoration: const InputDecoration(
          labelText: 'Department calendar',
          prefixIcon: Icon(Icons.business_rounded, size: 18),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: kSpaceMd, vertical: kSpaceMd),
        ),
        items: [
          const DropdownMenuItem(value: '', child: Text('All departments')),
          ..._departments.map(
            (department) => DropdownMenuItem(
              value: department['id']?.toString() ?? '',
              child: Text(
                '${department['code'] ?? ''} · ${department['name'] ?? ''}',
              ),
            ),
          ),
        ],
        onChanged: (value) => _pickDepartment(value),
      ),
    );
  }
}

class _EventDraft {
  const _EventDraft({
    required this.title,
    required this.kind,
    required this.startsAt,
    required this.endsAt,
    required this.departmentId,
    this.delete = false,
  });

  final String title;
  final String kind;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String? departmentId;
  final bool delete;
}

class _EventEditorDialog extends StatefulWidget {
  const _EventEditorDialog({
    required this.event,
    required this.departments,
    required this.initialDepartmentId,
  });

  final CalendarEvent? event;
  final List<Map<String, dynamic>> departments;
  final String? initialDepartmentId;

  @override
  State<_EventEditorDialog> createState() => _EventEditorDialogState();
}

class _EventEditorDialogState extends State<_EventEditorDialog> {
  late final TextEditingController _titleCtrl;
  late String _kind;
  String? _departmentId;
  late DateTime _startsAt;
  DateTime? _endsAt;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleCtrl = TextEditingController(text: event?.title ?? '');
    _kind = event?.kind ?? 'class';
    _departmentId = event?.departmentId ?? widget.initialDepartmentId;
    _startsAt = event?.startsAt ?? DateTime.now().add(const Duration(days: 1));
    _endsAt = event?.endsAt;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime value) {
    final date = '${value.year}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
    final time = '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    return DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? initial.hour,
      time?.minute ?? initial.minute,
    );
  }

  void _submit({bool delete = false}) {
    Navigator.pop(
      context,
      _EventDraft(
        title: _titleCtrl.text.trim().isEmpty
            ? 'Untitled event'
            : _titleCtrl.text.trim(),
        kind: _kind,
        startsAt: _startsAt,
        endsAt: _endsAt,
        departmentId: _departmentId,
        delete: delete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(kSpaceLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.event == null ? 'Add calendar event' : 'Edit event',
            style: context.h4.copyWith(
              fontWeight: FontWeight.w900,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: kSpaceXl),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Event title'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: kSpaceMd),
          DropdownButtonFormField<String>(
            initialValue: _kind,
            decoration: const InputDecoration(labelText: 'Event type'),
            items: const [
              DropdownMenuItem(value: 'class', child: Text('Class')),
              DropdownMenuItem(value: 'assignment', child: Text('Assignment')),
              DropdownMenuItem(value: 'quiz', child: Text('Quiz / exam')),
              DropdownMenuItem(
                value: 'institution',
                child: Text('Institution event'),
              ),
            ],
            onChanged: (value) => setState(() => _kind = value ?? 'class'),
          ),
          const SizedBox(height: kSpaceMd),
          DropdownButtonFormField<String>(
            initialValue: _departmentId ?? '',
            decoration: const InputDecoration(labelText: 'Department'),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text('Institution-wide'),
              ),
              ...widget.departments.map(
                (department) => DropdownMenuItem(
                  value: department['id']?.toString() ?? '',
                  child: Text(
                    '${department['code'] ?? ''} · '
                    '${department['name'] ?? ''}',
                  ),
                ),
              ),
            ],
            onChanged: (value) => setState(
              () => _departmentId =
                  (value == null || value.isEmpty) ? null : value,
            ),
          ),
          const SizedBox(height: kSpaceLg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.event_rounded, size: 18),
              label: Text('Starts: ${_fmt(_startsAt)}'),
              onPressed: () async {
                final picked = await _pickDateTime(_startsAt);
                if (picked != null) setState(() => _startsAt = picked);
              },
            ),
          ),
          const SizedBox(height: kSpaceSm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.schedule_rounded, size: 18),
                  label: Text(
                    _endsAt == null
                        ? 'Add end time (optional)'
                        : 'Ends: ${_fmt(_endsAt!)}',
                  ),
                  onPressed: () async {
                    final picked = await _pickDateTime(
                      _endsAt ??
                          _startsAt.add(const Duration(hours: 1)),
                    );
                    if (picked != null) setState(() => _endsAt = picked);
                  },
                ),
              ),
              if (_endsAt != null)
                IconButton(
                  tooltip: 'Clear end time',
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () => setState(() => _endsAt = null),
                ),
            ],
          ),
          const SizedBox(height: kSpaceXl),
          Row(
            children: [
              if (widget.event != null)
                Expanded(
                  child: TextButton(
                    onPressed: () => _submit(delete: true),
                    child: const Text('Delete', style: TextStyle(color: kError)),
                  ),
                ),
              if (widget.event != null)
                const SizedBox(width: kSpaceSm),
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: kSpaceSm),
              Expanded(
                child: FilledButton(
                  onPressed:
                      _titleCtrl.text.trim().isEmpty ? null : () => _submit(),
                  child: Text(widget.event == null ? 'Create' : 'Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😵', style: TextStyle(fontSize: 52)),
          const SizedBox(height: kSpaceMd),
          Text(
            error,
            style: context.body2.copyWith(color: kTextSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: kSpaceLg),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try again'),
            style: FilledButton.styleFrom(foregroundColor: kPrimary),
          ),
        ],
      ),
    );
  }
}
