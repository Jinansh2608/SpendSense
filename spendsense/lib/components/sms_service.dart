import 'package:telephony/telephony.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SMSService {
  final Telephony telephony = Telephony.instance;

  // Internal list to hold saved transactional messages
  final List<SmsMessage> _savedMessages = [];

  // Getter to access saved messages
  List<SmsMessage> get savedMessages => _savedMessages;

  /// Sends filtered SMS to backend API
  Future<void> sendTransactionSMS() async {
    await saveTransactionSMS(); // Ensure messages are fetched and saved first

    final smsList = _savedMessages.map((sms) => {
      "message": sms.body ?? "",
    }).toList();

    final uri = Uri.parse("http://192.168.1.104:5000/predict-bulk");
    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: json.encode({"messages": smsList}),
    );

    if (response.statusCode != 200) {
      throw Exception("❌ Failed to post SMS data: ${response.body}");
    }

    print("✅ Sent ${smsList.length} transactional messages to server.");
  }

  /// Filters and saves transactional SMS to _savedMessages
  Future<void> saveTransactionSMS() async {
    final bool? permissionsGranted =
    await telephony.requestPhoneAndSmsPermissions;

    if (permissionsGranted != true) {
      throw Exception("SMS permissions not granted");
    }

    final int ninetyDaysAgo = DateTime.now()
        .subtract(const Duration(days: 90))
        .millisecondsSinceEpoch;

    final List<SmsMessage> messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
      filter: SmsFilter.where(SmsColumn.DATE)
          .greaterThan(ninetyDaysAgo.toString()),
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    _savedMessages.clear(); // Clear previous list before saving new

    _savedMessages.addAll(messages.where((msg) {
      final body = msg.body?.toLowerCase() ?? '';
      final address = msg.address?.toLowerCase() ?? '';

      // Heuristics to detect transactional senders
      final isFromBank = address.contains("bk") ||
          address.contains("sbi") ||
          address.contains("axis") ||
          address.contains("hdfc") ||
          address.contains("icici") ||
          address.contains("bank") ||
          address.contains("paytm") ||
          address.contains("phonepe") ||
          address.contains("gpay");

      final containsTransactionKeywords = body.contains("debited") ||
          body.contains("credited") ||
          body.contains("txn") ||
          body.contains("payment") ||
          body.contains("rs") ||
          body.contains("inr") ||
          body.contains("upi") ||
          body.contains("account") ||
          body.contains("withdrawn") ||
          body.contains("transfer") ||
          body.contains("sent to") ||
          body.contains("spent") ||
          body.contains("purchase") ||
          body.contains("amount");

      return isFromBank || containsTransactionKeywords;
    }));
  }
}
