import 'package:flutter/material.dart';
import 'package:spendsense/components/analysis/analysis_buttons.dart';
import 'package:spendsense/components/analysis/chart.dart';
import 'package:spendsense/components/analysis/suggestion_box.dart';
import 'package:spendsense/components/analysis/top_categories.dart';
import 'package:spendsense/components/navbar.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Analysis'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ChartContainer(isWeekly: isWeekly),
            const SizedBox(height: 16),
            AnalysisButtons(isWeekly: isWeekly, onToggle: handleToggle),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            const TopCategories(),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            const SuggestionBox(),
          ],
        ),
      ),
      bottomNavigationBar: const MyNavbar(),
    );
  }
}