import 'package:edtech_app/models/effort_report.dart';
import 'package:edtech_app/services/api_service.dart';
import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';
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
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final report = await ApiService.instance.getIntegrityReport('a-001', 'u-student-1');
      if (!mounted) return;
      setState(() {
        _report = report;
        _loading = false;
        _error = null;
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
        const _PageHeader(
          title: 'Integrity',
          subtitle: 'Effort & authenticity monitoring',
        ),
        const SizedBox(height: 24),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_error != null)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: kError, size: 48),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: kTextSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: _load,
                  style: FilledButton.styleFrom(
                    foregroundColor: kPrimary,
                  ),
                  child: const Text('Try again'),
                ),
              ],
            ),
          )
        else if (_report == null)
          const Center(child: Text('Unable to load integrity report'))
        else ...[
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
      ],
    );
  }

}

class _PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _PageHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: kTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: kTextSecondary,
          ),
        ),
      ],
    );
  }
}
