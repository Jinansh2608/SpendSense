import 'package:flutter/material.dart';

class TransactionTile extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionTile({super.key, required this.transaction});

  /// ✅ Format amount safely
  String formatAmount(dynamic amount) {
    if (amount == null) return "₹0.00";
    final amt = amount is num ? amount : double.tryParse(amount.toString()) ?? 0.0;
    return "₹${amt.toStringAsFixed(2)}";
  }

  /// ✅ Color for debit/credit
  Color getAmountColor(String txnType) {
    if (txnType.toLowerCase() == 'debit') return Colors.red;
    if (txnType.toLowerCase() == 'credit') return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final sender = transaction['sender'] ?? 'Unknown';
    final category = transaction['category'] ?? 'Unknown';
    final amount = transaction['amount'] ?? 0.0;
    final sms = transaction['sms'] ?? '';
    final date = transaction['date'] ?? '';
    final txnType = transaction['txn_type'] ?? 'Unknown';
    final balance = transaction['balance'];
    final mode = transaction['mode'] ?? '';
    final refNo = transaction['ref_no'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            sender.isNotEmpty ? sender[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                category,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              formatAmount(amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: getAmountColor(txnType),
              ),
            ),
          ],
        ),
        subtitle: Text(
          sms.length > 40 ? '${sms.substring(0, 40)}...' : sms,
          style: const TextStyle(color: Colors.grey),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Full SMS:\n$sms', style: const TextStyle(fontSize: 14)),
                if (date.isNotEmpty)
                  Text('Date: $date', style: const TextStyle(fontSize: 14)),
                if (txnType.isNotEmpty)
                  Text('Type: $txnType', style: const TextStyle(fontSize: 14)),
                if (balance != null)
                  Text('Balance: ${formatAmount(balance)}', style: const TextStyle(fontSize: 14)),
                if (mode.isNotEmpty)
                  Text('Mode: $mode', style: const TextStyle(fontSize: 14)),
                if (refNo.isNotEmpty)
                  Text('Ref No: $refNo', style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
