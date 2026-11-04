import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';

/// A floating, rounded pill navigation bar. The active tab gets a candy
/// gradient pill that springs in behind the icon.
class BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const BottomNav({super.key, required this.selectedIndex, required this.onTap});

  static const _items = [
    // Top row (primary)
    {'icon': Icons.dashboard_rounded, 'label': 'Home'},
    {'icon': Icons.school_rounded, 'label': 'Courses'},
    {'icon': Icons.calendar_month_rounded, 'label': 'Calendar'},
    {'icon': Icons.chat_bubble_rounded, 'label': 'Chat'},
    {'icon': Icons.verified_rounded, 'label': 'Integrity'},
    // Bottom row (secondary)
    {'icon': Icons.people_rounded, 'label': 'Students'},
    {'icon': Icons.business_rounded, 'label': 'Departments'},
    {'icon': Icons.check_circle_rounded, 'label': 'Attendance'},
    {'icon': Icons.note_rounded, 'label': 'Notes'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      height: 88,
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final color = kTabColors[index % kTabColors.length];
            final isSelected = selectedIndex == index;
            // Two-row layout: first 5 in top, rest in bottom.
            final inTopRow = index < 5;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _NavTab(
                  icon: item['icon'] as IconData,
                  label: item['label'] as String,
                  color: color,
                  isSelected: isSelected,
                  inTopRow: inTopRow,
                  onTap: () => onTap(index),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final bool inTopRow;
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.inTopRow = true,
  });  Widget _label() {
    return Text(
      label,
      style: TextStyle(
        fontSize: inTopRow ? 9.0 : 8.0,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? color : kTextSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gradient pill that springs in behind the active icon.
          AnimatedContainer(
            duration: const Duration(milliseconds: 340),
            curve: Curves.easeOutBack,
            width: isSelected ? 44 : 0,
            height: 28,
            decoration: BoxDecoration(
              gradient: livelyGradient(color, shadeOf(color, 0.18)),
              borderRadius: BorderRadius.circular(14),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 280),
                curve: Curves.elasticOut,
                scale: isSelected ? 1.12 : 1.0,
                child: Icon(
                  icon,
                  size: inTopRow ? 18 : 17,
                  color: isSelected ? Colors.white : kTextSecondary,
                ),
              ),
            ),
          ),
          SizedBox(height: inTopRow ? 2.0 : 6.0),
          _label(),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}
