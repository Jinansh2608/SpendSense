import 'package:flutter/material.dart';
import 'package:spendsense/components/animatedArc.dart';
import 'package:spendsense/constants/colors/colors.dart';
import 'package:spendsense/pages/Insights.dart';

class Dashscreen extends StatelessWidget {
  final double arcValue;
  const Dashscreen({super.key, required this.arcValue});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    return Stack(
      alignment: Alignment.topCenter, // 🔥 ensures arc + texts are centered
      children: [
        // Arc Indicator
        SizedBox(
          width: width * 0.74,
          height: height * 0.25, // adjust height to fit arc & text
          child: ArcIndicator(value: arcValue),
        ),

        // Texts + button
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "budget1",
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              "1,234",
              style: TextStyle(fontSize: 50),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Insights()),
                );
              },
              child: Container(
                width: width * 0.3,
                height: width * 0.1,
                decoration: BoxDecoration(
                  color: Ycolor.whitee24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    "insights",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}