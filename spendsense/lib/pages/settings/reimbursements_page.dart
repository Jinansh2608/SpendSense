import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:spendsense/constants/colors/colors.dart';

class Reimbursement {
  final String description;
  final double amount;
  final DateTime date;

  Reimbursement({required this.description, required this.amount, required this.date});
}

class ReimbursementsPage extends StatefulWidget {
  const ReimbursementsPage({super.key});

  @override
  State<ReimbursementsPage> createState() => _ReimbursementsPageState();
}

class _ReimbursementsPageState extends State<ReimbursementsPage> {
  final List<Reimbursement> _reimbursements = [
    Reimbursement(description: 'Client Lunch', amount: 1250.00, date: DateTime.now().subtract(const Duration(days: 2))),
    Reimbursement(description: 'Office Supplies', amount: 480.50, date: DateTime.now().subtract(const Duration(days: 5))),
  ];

  void _addReimbursement(String description, double amount) {
    if (description.isNotEmpty && amount > 0) {
      setState(() {
        _reimbursements.insert(0, Reimbursement(description: description, amount: amount, date: DateTime.now()));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reimbursements'),
        backgroundColor: Ycolor.gray,
        elevation: 0,
      ),
      backgroundColor: Ycolor.gray,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        backgroundColor: Ycolor.primarycolor,
        child: const Icon(Icons.add),
      ),
      body: _reimbursements.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: _reimbursements.length,
              itemBuilder: (context, index) {
                final item = _reimbursements[index];
                return ListTile(
                  leading: Icon(Icons.receipt_long_outlined, color: Ycolor.primarycolor),
                  title: Text(item.description, style: TextStyle(color: Ycolor.whitee, fontWeight: FontWeight.bold)),
                  subtitle: Text(DateFormat.yMMMd().format(item.date), style: TextStyle(color: Ycolor.gray10)),
                  trailing: Text('₹${item.amount.toStringAsFixed(2)}', style: TextStyle(color: Ycolor.whitee, fontSize: 16, fontWeight: FontWeight.w600)),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Ycolor.gray60),
          const SizedBox(height: 16),
          Text(
            'No Reimbursements Yet',
            style: TextStyle(fontSize: 20, color: Ycolor.gray10),
          ),
          const SizedBox(height: 8),
          Text(
            'Track money owed to you here.',
            style: TextStyle(fontSize: 16, color: Ycolor.gray60),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Ycolor.gray70,
        title: Text('Add Reimbursement', style: TextStyle(color: Ycolor.whitee)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              autofocus: true,
              style: TextStyle(color: Ycolor.whitee),
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: Ycolor.gray10),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Ycolor.primarycolor)),
              ),
            ),
            TextField(
              controller: amountController,
              style: TextStyle(color: Ycolor.whitee),
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: TextStyle(color: Ycolor.gray10),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Ycolor.primarycolor)),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Ycolor.primarycolor)),
          ),
          TextButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0.0;
              _addReimbursement(descriptionController.text, amount);
              Navigator.pop(context);
            },
            child: Text('Add', style: TextStyle(color: Ycolor.primarycolor)),
          ),
        ],
      ),
    );
  }
}
