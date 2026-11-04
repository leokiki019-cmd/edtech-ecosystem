import 'package:edtech_app/auth/auth_provider.dart';
import 'package:edtech_app/models/assignment.dart';
import 'package:edtech_app/models/effort_report.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:edtech_app/widgets/animated_number.dart';
import 'package:edtech_app/widgets/bounce_tap.dart';
import 'package:edtech_app/widgets/confetti_burst.dart';
import 'package:edtech_app/widgets/effort_gauge.dart';
import 'package:edtech_app/widgets/floating_shapes.dart';
import 'package:edtech_app/widgets/lively_card.dart';
import 'package:edtech_app/widgets/skeleton_loader.dart';
import 'package:edtech_app/widgets/staggered_reveal.dart';
import 'package:edtech_app/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    return Scaffold(
      backgroundColor: kBackground,
      body: ListView(
        padding: const EdgeInsets.all(kSpaceLg),
        children: [
          _buildHeader(context),
          const SizedBox(height: kSpaceXl),
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
      ),
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
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: kTextPrimary,
                ),
              ),
              const SizedBox(height: kSpaceXs),
              if (_assignment != null)
                Text(
                  _assignment!.title,
                  style: context.body2.copyWith(
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
                SnackBar(
                  content: const Text('Refreshing integrity report'),
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

  Widget _buildReportSection() {
    return StaggeredReveal(
      childCount: 1,
      itemBuilder: (context, _) => Column(
        children: [
          LivelyCard(
            gradient: candyGradient,
            child: FloatingShapes(
              child: Padding(
                padding: const EdgeInsets.all(kSpaceXl),
                child: Column(
                  children: [
                    EffortGauge(score: _report!.effortScore.score),
                    const SizedBox(height: kSpaceMd),
                    AnimatedNumber(
                      value: _report!.effortScore.score,
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: kSpaceSm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(30),
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
          const SizedBox(height: kSpaceXl),
          Row(
            children: [
              Expanded(
                child: BounceTap(
                  child: StatCard(
                    title: 'Keystrokes',
                    value: _report!.effortScore.keystrokes,
                    icon: Icons.keyboard_rounded,
                    color: kPrimary,
                  ),
                ),
              ),
              const SizedBox(width: kSpaceSm),
              Expanded(
                child: BounceTap(
                  child: StatCard(
                    title: 'Pastes',
                    value: _report!.effortScore.pastes,
                    icon: Icons.content_paste_rounded,
                    color: kWarning,
                  ),
                ),
              ),
              const SizedBox(width: kSpaceSm),
              Expanded(
                child: BounceTap(
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
          const SizedBox(height: kSpaceXl),
          LivelyCard(
            gradient: livelyGradient(kSurface, const Color(0xFFF5F7FA)),
            child: const Padding(
              padding: EdgeInsets.all(kSpaceMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy note',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: kTextPrimary,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: kSpaceSm),
                  Text(
                    'Only typing cadence, paste volume and tab activity are recorded. '
                    'Keystroke content and password fields are never captured.',
                    style: TextStyle(
                      color: kTextSecondary,
                      height: 1.7,
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
          height: 340,
          decoration: BoxDecoration(
            gradient: candyGradient,
            borderRadius: BorderRadius.circular(kRadiusMd),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
        const SizedBox(height: kSpaceMd),
        const Row(
          children: [
            Expanded(child: SkeletonBox(height: 110, borderRadius: BorderRadius.all(Radius.circular(18)))),
            SizedBox(width: kSpaceSm),
            Expanded(child: SkeletonBox(height: 110, borderRadius: BorderRadius.all(Radius.circular(18)))),
            SizedBox(width: kSpaceSm),
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
        padding: const EdgeInsets.all(kSpaceXxl),
        child: Column(
          children: [
            const Text('✍️', style: TextStyle(fontSize: 56)),
            const SizedBox(height: kSpaceMd),
            const Text(
              'No writing sessions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: kSpaceSm),
            Text(
              'Your effort score for "$assignmentTitle" will appear once '
              'you draft with the Integrity Lens browser extension enabled.',
              textAlign: TextAlign.center,
              style: context.body2.copyWith(
                color: kTextSecondary,
                height: 1.7,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: kSpaceLg),
            BounceTap(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: tintOf(kPrimary, 0.1),
                  borderRadius: BorderRadius.circular(kRadiusMd),
                ),
                child: const Text(
                  'Learn how it works →',
                  style: TextStyle(
                    color: kPrimary,
                    fontWeight: FontWeight.w800,
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
