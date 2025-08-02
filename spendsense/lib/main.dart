import 'package:flutter/material.dart';
import 'package:telephony/telephony.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const SMSApp());
}

class SMSApp extends StatelessWidget {
  const SMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transaction SMS Viewer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.teal, useMaterial3: true),
      home: const SMSHomeScreen(),
    );
  }
}

class SMSHomeScreen extends StatefulWidget {
  const SMSHomeScreen({super.key});

  @override
  State<SMSHomeScreen> createState() => _SMSHomeScreenState();
}

class _SMSHomeScreenState extends State<SMSHomeScreen> {
  final Telephony telephony = Telephony.instance;
  List<SmsMessage> transactionMessages = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  void _requestPermissions() async {
    final bool? granted = await telephony.requestPhoneAndSmsPermissions;
    if (granted ?? false) {
      fetchSMS();
    } else {
      setState(() => _loading = false);
    }
  }

  void fetchSMS() async {
    setState(() => _loading = true);

    try {
      final messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      final List<String> bankKeywords = [
        "debited",
        "credited",
        "txn",
        "transaction",
        "upi",
        "neft",
        "imps",
        "rtgs",
        "withdrawn",
        "deposited",
        "payment",
        "transfer",
        "received",
        "sent",
        "spent",
      ];

      final RegExp amountRegex = RegExp(
        r'(?:inr|rs\.?)\s?[\d,]+\.?\d{0,2}',
        caseSensitive: false,
      );

      final filtered = messages.where((sms) {
        final body = sms.body?.toLowerCase() ?? "";
        final sender = sms.address?.toLowerCase() ?? "";

        // ✅ Exclude promotional sources (e.g., "idea", "vodafone", "airtel", etc.)
        final isPromo =
            sender.contains("airtel") ||
            sender.contains("vodafone") ||
            sender.contains("idea") ||
            sender.contains("jio") ||
            sender.contains("vi") ||
            sender.contains("care") ||
            sender.contains("info") ||
            sender.contains("alert");

        if (isPromo) return false;

        // ✅ Must match a bank keyword
        final hasBankKeyword = bankKeywords.any((word) => body.contains(word));

        // ✅ Must have a money amount
        final hasAmount = amountRegex.hasMatch(body);

        return hasBankKeyword && hasAmount;
      }).toList();

      setState(() {
        transactionMessages = filtered;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to read SMS: $e')));
    }
  }

  String formatDate(int? timestamp) {
    if (timestamp == null) return '';
    return DateFormat(
      'dd MMM, yyyy – hh:mm a',
    ).format(DateTime.fromMillisecondsSinceEpoch(timestamp));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("📥 Transactional SMS")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : transactionMessages.isEmpty
          ? const Center(child: Text("No transaction SMS found."))
          : ListView.builder(
              itemCount: transactionMessages.length,
              itemBuilder: (context, index) {
                final sms = transactionMessages[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(
                      sms.body ?? "",
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text("Sender: ${sms.address ?? "Unknown"}"),
                        Text("Date: ${formatDate(sms.date)}"),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: fetchSMS,
        icon: const Icon(Icons.refresh),
        label: const Text("Refresh"),
      ),
    );
  }
}
