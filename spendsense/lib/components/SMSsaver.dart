import 'package:telephony/telephony.dart';

class SMSSaver {
  final Telephony telephony = Telephony.instance;
  List<SmsMessage> savedMessages = [];

  Future<void> saveTransactionSMS() async {
    final bool? granted = await telephony.requestPhoneAndSmsPermissions;
    if (!(granted ?? false)) {
      print("SMS permission not granted.");
      return;
    }

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

        final isPromo =
            sender.contains("airtel") ||
            sender.contains("vodafone") ||
            sender.contains("idea") ||
            sender.contains("jio") ||
            sender.contains("vi") ||
            sender.contains("care") ||
            sender.contains("info") ||
            sender.contains("alert");

        final hasBankKeyword = bankKeywords.any((word) => body.contains(word));
        final hasAmount = amountRegex.hasMatch(body);

        return !isPromo && hasBankKeyword && hasAmount;
      }).toList();

      savedMessages = filtered;
      print("Saved ${savedMessages.length} transactional SMS.");
    } catch (e) {
      print("Error reading SMS: $e");
    }
  }
}
