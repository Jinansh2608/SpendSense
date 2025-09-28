import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting - add `intl: ^0.19.0` to pubspec.yaml

class TransactionTile extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionTile({super.key, required this.transaction});

  // Helper to safely get a string from the map
  String _getString(String key, {String defaultValue = ''}) {
    return transaction[key]?.toString() ?? defaultValue;
  }

  // Helper to safely get a number
  double _getDouble(String key, {double defaultValue = 0.0}) {
    final value = transaction[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? defaultValue;
  }

  @override
  Widget build(BuildContext context) {
    // --- Data Extraction ---
    final sender = _getString('sender', defaultValue: 'Unknown Sender');
    final amount = _getDouble('amount');
    final txnType = _getString('txn_type').toLowerCase();
    final mode = _getString('mode', defaultValue: 'N/A');
    final dateStr = _getString('date');

    // --- UI Logic ---
    final isDebit = txnType == 'debit';
    final amountColor = isDebit ? Colors.red.shade700 : Colors.green.shade700;
    final amountString =
        (isDebit ? '- ' : '+ ') + '₹${amount.toStringAsFixed(2)}';
    final icon = isDebit
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    // --- Date Formatting ---
    String formattedDate = dateStr;
    if (dateStr.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(dateStr);
        formattedDate = DateFormat('d MMM yyyy, h:mm a').format(dateTime);
      } catch (e) {
        formattedDate = dateStr;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: amountColor.withOpacity(0.15),
          child: Icon(icon, color: amountColor, size: 22),
        ),
        title: Text(
          sender,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$mode • $formattedDate',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: Text(
          amountString,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: amountColor,
            fontSize: 15,
          ),
        ),
        children: [_buildDetailsPanel(context)],
      ),
    );
  }

  /// Builds the structured details panel shown on expansion.
  Widget _buildDetailsPanel(BuildContext context) {
    final category = _getString('category', defaultValue: 'Uncategorized');
    final balance = _getDouble('balance');
    final refNo = _getString('ref_no');
    final sms = _getString('sms');

    return Container(
      color: Colors.black.withOpacity(0.03),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Category', category),
          if (balance > 0)
            _buildDetailRow(
              'Available Balance',
              '₹${balance.toStringAsFixed(2)}',
            ),
          if (refNo.isNotEmpty) _buildDetailRow('Reference No.', refNo),
          if (sms.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Original Message',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sms,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds a single row in the details panel.
  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
