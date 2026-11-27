import 'package:flutter/material.dart';

import 'theme.dart';

/// Plain calm background. Decoration is kept out on purpose; the content carries the design.
class WaterBackground extends StatelessWidget {
  final Widget child;
  const WaterBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: AppColors.bg, child: child);
  }
}
