import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class TransactionTilePage extends StatefulWidget {
  const TransactionTilePage({super.key});

  @override
  State<TransactionTilePage> createState() => _TransactionTilePageState();
}

class _TransactionTilePageState extends State<TransactionTilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<dynamic> transactions = [];
  bool isLoading = true;
  String? errorMessage;

  // Replace with your base API URL
  static const String baseUrl = 'https://your-api-domain.com';

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final uid = user.uid;
      final url = Uri.parse('$baseUrl/records/$uid');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;
        if (responseBody.isEmpty) {
          throw Exception('Empty response from server');
        }

        final Map<String, dynamic> data = json.decode(responseBody);

        // Check if API response is successful
        if (data['status'] != 'success') {
          throw Exception('API Error: ${data['message'] ?? 'Unknown error'}');
        }

        // Extract the data array
        final List<dynamic> transactionList = data['data'] as List? ?? [];

        setState(() {
          transactions = transactionList;
          isLoading = false;
        });

      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to fetch transactions');
      }
    } catch (e) {
      print('Error fetching transactions: $e');
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String formatAmount(dynamic amount) {
    if (amount == null) return '₹0';

    if (amount is String) {
      final parsed = double.tryParse(amount);
      if (parsed != null) {
        return '₹${parsed.toStringAsFixed(2)}';
      }
      return amount.startsWith('₹') ? amount : '₹$amount';
    } else if (amount is num) {
      return '₹${amount.toStringAsFixed(2)}';
    }

    return '₹$amount';
  }

  Color getAmountColor(dynamic amount) {
    if (amount == null) return Colors.grey;

    final amountStr = amount.toString();
    if (amountStr.contains('-')) {
      return Colors.red; // Debit
    }
    return Colors.green; // Credit
  }

  IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'bills':
        return Icons.receipt;
      case 'salary':
        return Icons.attach_money;
      case 'transfer':
        return Icons.swap_horiz;
      case 'atm':
        return Icons.local_atm;
      default:
        return Icons.account_balance_wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchTransactions,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading transactions...'),
          ],
        ),
      )
          : errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Failed to load transactions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchTransactions,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : transactions.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text('No transactions found'),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchTransactions,
        child: ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final txn = transactions[index];

            // Safely extract data based on your API structure
            final account = txn is Map<String, dynamic>
                ? (txn['account'] as String?) ?? 'Unknown'
                : 'Unknown';
            final category = txn is Map<String, dynamic>
                ? (txn['category'] as String?) ?? 'Unknown'
                : 'Unknown';
            final sms = txn is Map<String, dynamic>
                ? (txn['sms'] as String?) ?? ''
                : '';
            final amount = txn is Map<String, dynamic>
                ? txn['amount']
                : '0';
            final date = txn is Map<String, dynamic>
                ? (txn['date'] as String?) ?? ''
                : '';
            final txnType = txn is Map<String, dynamic>
                ? (txn['txn_type'] as String?) ?? ''
                : '';
            final balance = txn is Map<String, dynamic>
                ? txn['balance']
                : '';
            final mode = txn is Map<String, dynamic>
                ? (txn['mode'] as String?) ?? ''
                : '';
            final refNo = txn is Map<String, dynamic>
                ? (txn['ref_no'] as String?) ?? ''
                : '';

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  radius: 24,
                  child: Icon(
                    getCategoryIcon(category),
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                title: Text(
                  category,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sms.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        sms,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (date.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (txnType.isNotEmpty) ...[
                            Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              txnType.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    if (refNo.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Ref: $refNo',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatAmount(amount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: getAmountColor(amount),
                      ),
                    ),
                    if (balance.toString().isNotEmpty)
                      Text(
                        'Bal: ${formatAmount(balance)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    if (mode.isNotEmpty)
                      Text(
                        mode.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}