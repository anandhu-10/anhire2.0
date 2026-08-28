import 'package:flutter/material.dart';

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.minItemWidth = 150.0,
    this.spacing = 12.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        if (totalWidth <= 0) return const SizedBox.shrink();

        final effectiveMinItemWidth = (minItemWidth > totalWidth) ? totalWidth : minItemWidth;

        int crossAxisCount = (totalWidth / effectiveMinItemWidth).floor();
        if (crossAxisCount < 1) crossAxisCount = 1;
        if (crossAxisCount > children.length) crossAxisCount = children.length;

        final itemWidth = (totalWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;
        final finalWidth = itemWidth > totalWidth ? totalWidth : (itemWidth < 0 ? 0.0 : itemWidth);

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children.map((child) {
            return SizedBox(
              width: finalWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}
