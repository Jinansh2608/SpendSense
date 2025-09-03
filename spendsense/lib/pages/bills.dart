import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:spendsense/constants/colors/colors.dart';

class BillsPage extends StatefulWidget {
  const BillsPage({super.key});

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  final Telephony telephony = Telephony.instance;

  List<Map<String, dynamic>> bills = [];
  bool isLoading = true;

  // Trusted senders
  final List<String> trustedSenders = [
    'ELECTRICITY',
    'WATERBILL',
    'BSNL',
    'PHONEPAY',
    'BANK',
    'DMRC',
  ];

  // Keywords to identify bills
  final List<String> billKeywords = [
    'bill',
    'due',
    'amount',
    'payment'
  ];

  @override
  void initState() {
    super.initState();
    fetchAndParseSMS('user_123'); // replace with actual UID
  }

  Future<void> fetchAndParseSMS(String uid) async {
    List<SmsMessage> messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    // Filter messages by trusted senders
    List<SmsMessage> filteredBySender = messages.where((sms) {
      if (sms.address == null || sms.body == null) return false;
      String sender = sms.address!.toUpperCase();
      return trustedSenders.any((trusted) => sender.contains(trusted.toUpperCase()));
    }).toList();

    // Further filter messages by keywords and regex
    List<Map<String, dynamic>> billMessages = [];
    for (var sms in filteredBySender) {
      String body = sms.body!.toLowerCase();
      if (billKeywords.any((keyword) => body.contains(keyword))) {
        final amountMatch = RegExp(r'(\d+\.?\d*)\s*(?:INR|₹)?', caseSensitive: false).firstMatch(body);
        final dateMatch = RegExp(r'(\d{2}[-/]\d{2}[-/]\d{4})').firstMatch(body);

        if (amountMatch != null && dateMatch != null) {
          billMessages.add({
            'sender': sms.address,
            'body': sms.body,
            'date': DateTime.fromMillisecondsSinceEpoch(sms.date!).toIso8601String(),
          });
        }
      }
    }

    if (billMessages.isEmpty) {
      setState(() {
        bills = [];
        isLoading = false;
      });
      return;
    }

    // Send filtered SMS to backend API
    final response = await http.post(
      Uri.parse('https://yourapi.com/bills/parse_sms'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'uid': uid, 'messages': billMessages}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        bills = List<Map<String, dynamic>>.from(data['parsed_bills']);
        isLoading = false;
      });
    } else {
      setState(() {
        bills = [];
        isLoading = false;
      });
      print('Failed to send SMS to API. Status: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Bills')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bills.isEmpty
          ? const Center(child: Text('No bills found.'))
          : ListView.builder(
        itemCount: bills.length,
        itemBuilder: (context, index) {
          final bill = bills[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ListTile(
              leading: Icon(
                bill['status'] == 'Paid' ? Icons.check_circle : Icons.warning,
                color: bill['status'] == 'Paid' ? Colors.green : Colors.red,
              ),
              title: Text(bill['category'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Due: ${bill['due_date']}'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${bill['amount'] ?? '0'}'),
                  Text(bill['status'] ?? 'Unpaid',
                      style: TextStyle(
                          color: bill['status'] == 'Paid' ? Colors.green : Colors.red)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
