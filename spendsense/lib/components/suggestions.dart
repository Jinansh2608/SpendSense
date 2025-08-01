// lib/widgets/analysis/suggestion_box.dart
import 'package:flutter/material.dart';
import 'package:spendsense/constants/colors/colors.dart';

class SuggestionBox extends StatelessWidget {
  const SuggestionBox({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Suggestions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Ycolor.secondarycolor50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text("You can reduce your food expenses by planning meals weekly.",
          style: TextStyle(
            fontStyle: FontStyle.italic
          ),
          ),
        ),
      ],
    );
  }
}
