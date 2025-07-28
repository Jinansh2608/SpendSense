import 'package:flutter/material.dart';
import 'package:spendsense/constants/colors/colors.dart';
import 'package:vector_math/vector_math.dart';

class CustomArcPainter extends CustomPainter {
  final double start;
  final double end;
  final double width;
  final double blurWidth;

  CustomArcPainter({
    required this.start,
    required this.end,
    this.width = 16,
    this.blurWidth = 6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double maxDiameter = 320;
    final double diameter = size.shortestSide < maxDiameter
        ? size.shortestSide *2.68
        : maxDiameter;
    final double radius = diameter / 2;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final gradientColor = LinearGradient(
      colors: [Ycolor.secondarycolor, Ycolor.secondarycolor],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final Paint activePaint = Paint()
      ..shader = gradientColor.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    final Paint backgroundPaint = Paint()
      ..color = Ycolor.gray60.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    final Paint shadowPaint = Paint()
      ..color = Ycolor.secondarycolor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width + blurWidth
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    final double startVal = 125.0 + start;

    // Draw base arc
    canvas.drawArc(rect, radians(startVal), radians(290), false, backgroundPaint);

    // Shadow arc
    final Path shadowPath = Path();
    shadowPath.addArc(rect, radians(startVal), radians(end));
    canvas.drawPath(shadowPath, shadowPaint);

    // Active arc
    canvas.drawArc(rect, radians(startVal), radians(end), false, activePaint);
  }

  @override
  bool shouldRepaint(covariant CustomArcPainter oldDelegate) {
    return start != oldDelegate.start ||
        end != oldDelegate.end ||
        width != oldDelegate.width ||
        blurWidth != oldDelegate.blurWidth;
  }
}
