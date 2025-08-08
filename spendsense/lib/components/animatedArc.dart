import 'package:flutter/material.dart';
import 'package:spendsense/components/customArcPainter.dart';

class ArcIndicator extends StatefulWidget {
  final double value; // percent 0–1

  const ArcIndicator({super.key, required this.value});

  @override
  State<ArcIndicator> createState() => _ArcIndicatorState();
}

class _ArcIndicatorState extends State<ArcIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  double _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: widget.value).animate(_controller);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant ArcIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(begin: _previousValue, end: widget.value).animate(_controller);
      _controller.forward(from: 0);
      _previousValue = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double endAngle = _animation.value * 290; // Map to arc
        return RepaintBoundary(
          child: CustomPaint(
            painter: CustomArcPainter(end: endAngle),

          ),
        );
      },
    );
  }
}