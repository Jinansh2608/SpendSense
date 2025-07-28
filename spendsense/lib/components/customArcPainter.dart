import 'package:flutter/material.dart';
import 'package:spendsense/constants/colors/colors.dart';
import 'package:vector_math/vector_math.dart';

class CustomArcPainter extends CustomPainter {

  final double start;
  final double end;
  final double width;
  final double blurWidth;

  CustomArcPainter({this.start = 0, this.end = 180, this.width = 18, this.blurWidth = 6});

  @override
  void paint(Canvas canvas, Size size) {
    var rect = Rect.fromCircle(
        center: Offset(size.width / 2, size.height / 2),
        radius: size.width / 2);

    var gradientColor = LinearGradient(
        colors: [Ycolor.secondarycolor,  Ycolor.secondarycolor],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter);

    Paint activePaint = Paint()..shader = gradientColor.createShader(rect);

    activePaint.style = PaintingStyle.stroke;
    activePaint.strokeWidth = width;
    activePaint.strokeCap = StrokeCap.round;

    Paint backgroundPaint = Paint();
    backgroundPaint.color = Ycolor.gray60.withOpacity(0.5);
    backgroundPaint.style = PaintingStyle.stroke;
    backgroundPaint.strokeWidth = width;
    backgroundPaint.strokeCap = StrokeCap.round;

    

    Paint shadowPaint = Paint()
        ..color = Ycolor.secondarycolor.withOpacity(0.3) // .. is cascading used just after creting the object so basically paint.color would be ..color after making a paint object
        ..style = PaintingStyle.stroke
        ..strokeWidth = width + blurWidth
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    var startVal = 125.0 + start;

    canvas.drawArc(rect, radians(startVal) , radians(290), false, backgroundPaint);
    
    //Draw Shadow Arc
    Path path = Path();
    path.addArc(rect, radians(startVal) , radians(end));
    canvas.drawPath(path, shadowPaint );
    
    canvas.drawArc(rect, radians(startVal), radians(end), false, activePaint);
  }

  @override
  bool shouldRepaint(covariant CustomArcPainter oldDelegate) {
    return start != oldDelegate.start || end != oldDelegate.end;
  }

  @override
  bool shouldRebuildSemantics(CustomArcPainter oldDelegate) => false;
}