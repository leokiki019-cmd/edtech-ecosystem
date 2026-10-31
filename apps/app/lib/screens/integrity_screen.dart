import 'package:edtech_app/auth/auth_provider.dart';
import 'package:edtech_app/models/assignment.dart';
import 'package:edtech_app/models/effort_report.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/animated_number.dart';
import '../widgets/bounce_tap.dart';
import '../widgets/confetti_burst.dart';
import '../widgets/effort_gauge.dart';
import '../widgets/floating_shapes.dart';
import '../widgets/hover_scale.dart';
import '../widgets/lively_card.dart';
import '../widgets/skeleton_loader.dart';
import '../widgets/staggered_reveal.dart';
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
  final _confettiKey = GlobalKey<ConfettiBurstState>();

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

      // Celebrate a strong score.
      if (report != null && report.effortScore.score >= 75) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _confettiKey.currentState?.celebrate();
        });
      }
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
        ConfettiBurst(
          key: _confettiKey,
          child: _loading
              ? const _ReportSkeleton()
              : _error != null
                  ? _ErrorState(error: _error!, onRetry: _load)
                  : !_hasTelemetry
                      ? _EmptyState(assignmentTitle: _assignment?.title ?? 'this assignment')
                      : _buildReportSection(),
        ),
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
                'Integrity 🛡️',
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
            icon: const Icon(Icons.refresh_rounded, color: kTextSecondary, size: 20),
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
    return StaggeredReveal(
      childCount: 1,
      itemBuilder: (context, _) => Column(
        children: [
          LivelyCard(
            gradient: candyGradient,
            child: FloatingShapes(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    EffortGauge(score: _report!.effortScore.score),
                    const SizedBox(height: 16),
                    AnimatedNumber(
                      value: _report!.effortScore.score,
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _report!.flags.isNotEmpty
                            ? _report!.flags.join(', ').replaceAll('_', ' ')
                            : 'Organic drafting detected ✨',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
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
                    icon: Icons.keyboard_rounded,
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
                    icon: Icons.content_paste_rounded,
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
                    icon: Icons.tab_rounded,
                    color: kError,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LivelyCard(
            gradient: livelyGradient(kSurface, const Color(0xFFF5F7FA)),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔒 Privacy note',
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
      ),
    );
  }
}

class _ReportSkeleton extends StatelessWidget {
  const _ReportSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 320,
          decoration: BoxDecoration(
            gradient: candyGradient,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        const SizedBox(height: 24),
        const Row(
          children: [
            Expanded(child: SkeletonBox(height: 110, borderRadius: BorderRadius.all(Radius.circular(18)))),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 110, borderRadius: BorderRadius.all(Radius.circular(18)))),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 110, borderRadius: BorderRadius.all(Radius.circular(18)))),
          ],
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
            const Text('✍️', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            const Text(
              'No writing sessions yet',
              style: TextStyle(
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
            const SizedBox(height: 20),
            BounceTap(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: tintOf(kPrimary, 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Learn how it works →',
                  style: TextStyle(
                    color: kPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
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

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😵', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          Text(
            error,
            style: const TextStyle(color: kTextSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
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

