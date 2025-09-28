import 'package:flutter/material.dart';

class BillsList extends StatelessWidget {
  final List<Map<String, dynamic>> bills;

  const BillsList({super.key, required this.bills});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final bill = bills[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(
              bill['status'] == 'Paid' ? Icons.check_circle : Icons.warning,
              color: bill['status'] == 'Paid' ? Colors.green : Colors.red,
            ),
            title: Text(
              bill['name'] ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Due: ${bill['due_date'] ?? ''}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${bill['amount'] ?? 0}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  bill['status'] ?? '',
                  style: TextStyle(
                    color: bill['status'] == 'Paid' ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
