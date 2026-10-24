import 'package:edtech_app/auth/auth_provider.dart';
import 'package:edtech_app/models/assignment.dart';
import 'package:edtech_app/models/effort_report.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/animated_number.dart';
import '../widgets/effort_gauge.dart';
import '../widgets/hover_scale.dart';
import '../widgets/lively_card.dart';
import '../widgets/stat_card.dart';

class IntegrityScreen extends StatefulWidget {
  const IntegrityScreen({super.key});

  @override
  State<IntegrityScreen> createState() => _IntegrityScreenState();
}

class _IntegrityScreenState extends State<IntegrityScreen> {
  IntegrityReport? _report;
  Assignment? _assignment;
  bool _loading = true;
  bool _hasTelemetry = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final userId = context.read<AuthProvider>().user?.id ?? 'u-student-1';

    try {
      // Use the student's first course and its first open assignment as the
      // integrity focus until assignment selection exists in the app.
      final courses = await ApiService.instance.getCourses();
      if (courses.isEmpty) {
        throw Exception('No courses available for your account');
      }

      final assignments =
          await ApiService.instance.getAssignments(courses.first.id);
      final openAssignments =
          assignments.where((item) => item.status != 'draft').toList();
      if (openAssignments.isEmpty) {
        throw Exception('No open assignments to review');
      }

      final assignment = openAssignments.first;
      final report =
          await ApiService.instance.getIntegrityReportOrNull(assignment.id, userId);

      if (!mounted) return;
      setState(() {
        _assignment = assignment;
        _report = report;
        _hasTelemetry = report != null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildHeader(context),
        const SizedBox(height: 24),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          _ErrorState(
            error: _error!,
            onRetry: _load,
          )
        else if (!_hasTelemetry)
          _EmptyState(assignmentTitle: _assignment?.title ?? 'this assignment')
        else
          _buildReportSection(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Integrity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: kTextPrimary,
                ),
              ),
              if (_assignment != null)
                Text(
                  _assignment!.title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: kTextSecondary,
                  ),
                ),
            ],
          ),
        ),
        Tooltip(
          message: 'Refresh report',
          child: IconButton(
            icon: const Icon(Icons.refresh, color: kTextSecondary, size: 20),
            onPressed: () {
              _load();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing integrity report'),
                  backgroundColor: kPrimary,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportSection() {
    return Column(
      children: [
        LivelyCard(
          gradient: livelyGradient(kPrimary, kPrimaryDark),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                EffortGauge(score: _report!.effortScore.score),
                const SizedBox(height: 16),
                AnimatedNumber(
                  value: _report!.effortScore.score,
                  style: const TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _report!.flags.isNotEmpty
                      ? _report!.flags.join(', ').replaceAll('_', ' ')
                      : 'Organic drafting detected',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: HoverScale(
                child: StatCard(
                  title: 'Keystrokes',
                  value: _report!.effortScore.keystrokes,
                  icon: Icons.keyboard,
                  color: kPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HoverScale(
                child: StatCard(
                  title: 'Pastes',
                  value: _report!.effortScore.pastes,
                  icon: Icons.content_paste,
                  color: kWarning,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: HoverScale(
                child: StatCard(
                  title: 'AI switches',
                  value: _report!.effortScore.aiTabSwitches,
                  icon: Icons.tab,
                  color: kError,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        LivelyCard(
          gradient: livelyGradient(kSurface, const Color(0xFFF5F7FA)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Privacy note',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: kTextPrimary,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Only typing cadence, paste volume and tab activity are recorded. '
                  'Keystroke content and password fields are never captured.',
                  style: TextStyle(
                    color: kTextSecondary,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String assignmentTitle;

  const _EmptyState({required this.assignmentTitle});

  @override
  Widget build(BuildContext context) {
    return LivelyCard(
      gradient: livelyGradient(kSurface, const Color(0xFFF5F7FA)),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.edit_note, color: kPrimary, size: 56),
            const SizedBox(height: 16),
            Text(
              'No writing sessions yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your effort score for "$assignmentTitle" will appear once '
              'you draft with the Integrity Lens browser extension enabled.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextSecondary,
                height: 1.6,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: kError, size: 48),
          const SizedBox(height: 12),
          Text(
            error,
            style: const TextStyle(color: kTextSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              foregroundColor: kPrimary,
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
