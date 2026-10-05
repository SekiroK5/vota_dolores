import 'dart:math' as math;

import 'package:flutter/material.dart';

class ConfettiPainter extends CustomPainter {
  final double progress;

  ConfettiPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final pieces = List.generate(60, (index) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.4;
      final dx = (random.nextDouble() - 0.5) * 80;
      final dy = random.nextDouble() * 200 + 80;
      final width = 5 + random.nextDouble() * 8;
      final height = 12 + random.nextDouble() * 16;
      final color = Color((random.nextDouble() * 0xFFFFFF).toInt()).withValues(alpha: 0.9);
      return {
        'x': x,
        'y': y,
        'dx': dx,
        'dy': dy,
        'width': width,
        'height': height,
        'color': color,
      };
    });

    for (final piece in pieces) {
      final paint = Paint()..color = piece['color'] as Color;
      final x = (piece['x'] as double) + ((piece['dx'] as double) * progress);
      final y = (piece['y'] as double) + ((piece['dy'] as double) * progress);
      final rect = Rect.fromLTWH(
        x,
        y,
        piece['width'] as double,
        piece['height'] as double,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
