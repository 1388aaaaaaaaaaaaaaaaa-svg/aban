import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Water-themed background: soft blue gradient, faint bubbles and waves at the bottom.
class WaterBackground extends StatelessWidget {
  final Widget child;
  const WaterBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFB8E0FF), Color(0xFFDDF0FF), Color(0xFFF2F9FF)],
              ),
            ),
          ),
        ),
        const Positioned.fill(child: CustomPaint(painter: _WaterPainter())),
        child,
      ],
    );
  }
}

class _WaterPainter extends CustomPainter {
  const _WaterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final bubble = Paint()..color = const Color(0x1A3AA0F0);
    for (var i = 0; i < 20; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final r = 5 + rnd.nextDouble() * 16;
      canvas.drawCircle(Offset(x, y), r, bubble);
    }

    void wave(double baseY, double amp, Color color) {
      final path = Path()..moveTo(0, baseY);
      for (double x = 0; x <= size.width; x += 2) {
        path.lineTo(x, baseY + amp * math.sin((x / size.width) * 2 * math.pi * 1.5));
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, Paint()..color = color);
    }

    wave(size.height * 0.84, 14, const Color(0x332A8DE6));
    wave(size.height * 0.90, 10, const Color(0x553AA0F0));
    wave(size.height * 0.95, 7, const Color(0x6686CFFF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
