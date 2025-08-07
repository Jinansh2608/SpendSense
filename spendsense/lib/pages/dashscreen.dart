import 'package:flutter/material.dart';
import 'package:spendsense/components/animatedArc.dart';
import 'package:spendsense/constants/colors/colors.dart';
import 'package:spendsense/pages/Insights.dart';
// import 'package:spendsense/components/sms_viewer.dart'; // ❌ Removed

class Dashscreen extends StatelessWidget {
  const Dashscreen({super.key});

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: height * 0.12),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Column(
                    children: [
                      SizedBox(height: height * 0.12),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.74,
                        height: height * 0.13,
                        child: ArcIndicator(value: 0.5),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: height * 0.11),
                      Text(
                        "budget1",
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      SizedBox(height: height * 0.006),
                      Text("1,234", style: TextStyle(fontSize: 50)),
                      SizedBox(height: height * 0.097),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Insights()),
                          );
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.3,
                          height: MediaQuery.of(context).size.width * 0.1,
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
              ),
            ),
          ],
        ),
      ],
    );
  }
}
