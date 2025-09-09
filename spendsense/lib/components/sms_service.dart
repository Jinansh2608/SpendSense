import 'package:telephony/telephony.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SMSService {
  final Telephony telephony = Telephony.instance;
  final List<SmsMessage> _savedMessages = [];
  final Set<int> _sentMessageIds = {};

  List<SmsMessage> get savedMessages => _savedMessages;

  /// Load already sent SMS ids from SharedPreferences
  Future<void> _loadSentMessageIds() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? storedIds = prefs.getStringList('sent_sms_ids');
    if (storedIds != null) {
      _sentMessageIds.addAll(storedIds.map(int.parse));
    }
  }

  /// Save updated sent message IDs to SharedPreferences
  Future<void> _saveSentMessageIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'sent_sms_ids',
      _sentMessageIds.map((id) => id.toString()).toList(),
    );
  }

  /// Filters and stores transactional SMS messages from last 90 days
  Future<void> saveTransactionSMS() async {
    await _loadSentMessageIds();

    final permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
    if (permissionsGranted != true) {
      print("❌ SMS permission not granted.");
      return;
    }

    final int ninetyDaysAgo = DateTime.now()
        .subtract(const Duration(days: 90))
        .millisecondsSinceEpoch;

    final List<SmsMessage> messages = await telephony.getInboxSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE, SmsColumn.ID],
      filter: SmsFilter.where(SmsColumn.DATE).greaterThan(ninetyDaysAgo.toString()),
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    _savedMessages.clear();

    _savedMessages.addAll(messages.where((msg) {
      final body = msg.body?.toLowerCase() ?? '';
      final address = msg.address?.toLowerCase() ?? '';

      final isFromBank = address.contains("bk") ||
          address.contains("sbi") ||
          address.contains("axis") ||
          address.contains("hdfc") ||
          address.contains("icici") ||
          address.contains("bank") ||
          address.contains("paytm") ||
          address.contains("phonepe") ||
          address.contains("gpay");

      final containsKeywords = body.contains("debited") ||
          body.contains("credited") ||
          body.contains("txn") ||
          body.contains("payment") ||
          body.contains("inr") ||
          body.contains("upi") ||
          body.contains("account") ||
          body.contains("withdrawn") ||
          body.contains("transfer") ||
          body.contains("sent to") ||
          body.contains("spent") ||
          body.contains("purchase") ||
          body.contains("amount");

      return (isFromBank || containsKeywords) && !_sentMessageIds.contains(msg.id);
    }));

    print("📥 Filtered new transactional SMS: ${_savedMessages.length}");
  }

  /// Sends saved transactional SMS to Flask API with UID
  Future<void> sendTransactionSMS(String uid) async {
    if (_savedMessages.isEmpty) {
      print("⚠️ No new transactional SMS found to send.");
      return;
    }

    final smsList = _savedMessages.map((sms) {
      return {
        "sms": sms.body?.trim() ?? "",
        "sender": sms.address?.trim() ?? "Unknown",
      };
    }).toList();

    final uri = Uri.parse("http://192.168.1.103:5000/api/predict-bulk");

    try {
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "uid": uid,
          "messages": smsList,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> categorized = json.decode(response.body);
        print("✅ SMS sent and categorized for UID: $uid");

        for (var item in categorized) {
          print("• ${item['sms']} → ${item['category']} [${item['sender']}]");
        }

        // Save sent message IDs
        _sentMessageIds.addAll(_savedMessages.map((sms) => sms.id!));
        await _saveSentMessageIds();
      } else {
        print("❌ API error: ${response.statusCode} → ${response.body}");
      }
    } catch (e) {
      print("❌ Network/API exception: $e");
    }
  }
}
