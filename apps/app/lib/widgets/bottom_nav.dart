import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';

/// A floating, rounded pill navigation bar. The active tab gets a candy
/// gradient pill that springs in behind the icon.
class BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const BottomNav({super.key, required this.selectedIndex, required this.onTap});

  static const _items = [
    {'icon': Icons.dashboard_rounded, 'label': 'Home'},
    {'icon': Icons.school_rounded, 'label': 'Courses'},
    {'icon': Icons.calendar_month_rounded, 'label': 'Calendar'},
    {'icon': Icons.chat_bubble_rounded, 'label': 'Chat'},
    {'icon': Icons.verified_rounded, 'label': 'Integrity'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      height: 66,
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withValues(alpha: 0.10),
            blurRadius: 30,
            offset: const Offset(0, 10),
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
            return Expanded(
              child: _NavTab(
                icon: item['icon'] as IconData,
                label: item['label'] as String,
                color: color,
                isSelected: isSelected,
                onTap: () => onTap(index),
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
  final VoidCallback onTap;

  const _NavTab({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 6),
          // Gradient pill that springs in behind the active icon.
          AnimatedContainer(
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutBack,
            width: isSelected ? 56 : 0,
            height: 32,
            decoration: BoxDecoration(
              gradient: livelyGradient(color, shadeOf(color, 0.2)),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 320),
                curve: Curves.elasticOut,
                scale: isSelected ? 1.15 : 1.0,
                child: Icon(
                  icon,
                  size: 21,
                  color: isSelected ? Colors.white : kTextSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? color : kTextSecondary,
            ),
            child: Text(label),
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}
