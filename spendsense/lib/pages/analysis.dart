import 'package:flutter/material.dart';
import 'package:spendsense/components/analysisButton.dart';
import 'package:spendsense/components/chartContainer.dart';
import 'package:spendsense/components/navbar.dart';
import 'package:spendsense/components/suggestions.dart';
import 'package:spendsense/components/topCategories.dart';

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  bool isWeekly = true;

  void handleToggle(bool value) {
    setState(() {
      isWeekly = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      bottomNavigationBar: MyNavbar(),
      appBar: AppBar(title: const Text('Spending Analysis')),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: height * 0.02),
            ChartContainer(isWeekly: isWeekly),
            SizedBox(height: height * 0.02),
            AnalysisButtons(isWeekly: isWeekly, onToggle: handleToggle),
            SizedBox(height: height * 0.03),
            const TopCategories(), // ✅ No uid parameter
            SizedBox(height: height * 0.03),
            const SuggestionBox(),
          ],
        ),
      ),
    );
  }
}
