import 'package:edtech_app/theme.dart';
import 'package:flutter/material.dart';

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> items;

  const ResponsiveGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final crossAxisCount = isMobile ? 1 : 3;
        final childAspectRatio = isMobile ? 2.6 : 1.9;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: kSpaceMd,
            mainAxisSpacing: kSpaceMd,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => items[index],
        );
      },
    );
  }
}
