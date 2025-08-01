// lib/widgets/analysis/top_categories.dart
import 'package:flutter/material.dart';

class TopCategories extends StatefulWidget {
  const TopCategories({super.key});

  @override
  State<TopCategories> createState() => _TopCategoriesState();
}

class _TopCategoriesState extends State<TopCategories> {
  bool expanded = false;

  final List<Map<String, dynamic>> categories = [
    {'name': 'Food', 'amount': '₹1200'},
    {'name': 'Transport', 'amount': '₹900'},
    {'name': 'Shopping', 'amount': '₹850'},
    {'name': 'Bills', 'amount': '₹600'},
    {'name': 'Entertainment', 'amount': '₹400'},
  ];

  @override
  Widget build(BuildContext context) {
    final topToShow = expanded ? categories : categories.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Top Categories", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...topToShow.map((cat) => ListTile(
              title: Text(cat['name']),
              trailing: Text(cat['amount']),
            )),
        TextButton(
          onPressed: () {
            setState(() => expanded = !expanded);
          },
          child: Text(expanded ? 'Show Less' : 'Show More'),
        )
      ],
    );
  }
}
