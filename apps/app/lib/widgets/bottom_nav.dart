import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';

class BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const BottomNav({super.key, required this.selectedIndex, required this.onTap});

  static const _items = [
    {'icon': Icons.dashboard, 'label': 'Dashboard', 'color': kPrimary},
    {'icon': Icons.school, 'label': 'Courses', 'color': kAccentDark},
    {'icon': Icons.calendar_today, 'label': 'Calendar', 'color': kPink},
    {'icon': Icons.chat_bubble_outline, 'label': 'Chat', 'color': kOrange},
    {'icon': Icons.verified, 'label': 'Integrity', 'color': kSuccess},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: kSurface,
        border: Border(top: BorderSide(color: kBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(
          _items.length,
          (index) {
            final item = _items[index];
            final isSelected = selectedIndex == index;
            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  color: isSelected
                      ? (item['color'] as Color).withOpacity(0.10)
                      : Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        scale: isSelected ? 1.12 : 1.0,
                        child: Icon(
                          item['icon'] as IconData,
                          color: isSelected ? (item['color'] as Color) : kTextSecondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? (item['color'] as Color) : kTextSecondary,
                        ),
                        child: Text(item['label'] as String),
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
