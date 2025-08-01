// lib/widgets/analysis/analysis_buttons.dart
import 'package:flutter/material.dart';
import 'package:spendsense/constants/colors/colors.dart';

class AnalysisButtons extends StatelessWidget {
  final bool isWeekly;
  final Function(bool) onToggle;

  const AnalysisButtons({super.key, required this.isWeekly, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildButton(context, label: 'Weekly', selected: isWeekly, onTap: () => onToggle(true), size: size),
        SizedBox(width: size.width * 0.04),
        _buildButton(context, label: 'Monthly', selected: !isWeekly, onTap: () => onToggle(false), size: size),
      ],
    );
  }

  Widget _buildButton(BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required Size size
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? Ycolor.secondarycolor50 : Colors.grey[200],
        foregroundColor: selected ? Colors.grey[200] : Colors.black,
        padding: EdgeInsets.symmetric(horizontal: size.width * 0.06, vertical: size.height * 0.014),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label),
    );
  }
}
