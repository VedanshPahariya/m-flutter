import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

/// The rounded-square mark from the prototype, drawn in code so no image
/// asset is needed.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    final k = context.kora;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: k.accent,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: Container(
        width: size * 0.36,
        height: size * 0.36,
        decoration: BoxDecoration(
          color: k.raised,
          borderRadius: BorderRadius.circular(size * 0.1),
        ),
      ),
    );
  }
}
