import 'package:flutter/material.dart';
import 'package:spendsense/constants/colors/colors.dart';

class FilterButtons extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const FilterButtons({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ['All', 'Paid', 'Unpaid'].map((filter) {
        final isSelected = selectedFilter == filter;
        return ElevatedButton(
          onPressed: () => onFilterChanged(filter),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Ycolor.secondarycolor : Colors.grey[300],
            foregroundColor: isSelected ? Colors.white : Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(filter),
        );
      }).toList(),
    );
  }
}
