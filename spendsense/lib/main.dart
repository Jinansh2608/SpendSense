import 'package:flutter/material.dart';
import 'package:spendsense/Theme/Ytheme.dart';
import 'package:spendsense/pages/dashboard.dart';
import 'package:spendsense/components/SMSsaver.dart'; // <-- Import your SMS saver

void main() {
  runApp(const PayNest());
}

class PayNest extends StatefulWidget {
  const PayNest({super.key});

  @override
  State<PayNest> createState() => _PayNestState();
}

class _PayNestState extends State<PayNest> {
  @override
  void initState() {
    super.initState();
    _fetchSMSInBackground();
  }

  void _fetchSMSInBackground() {
    // This avoids blocking the UI thread.
    Future.microtask(() async {
      final smsSaver = SMSSaver();
      await smsSaver.saveTransactionSMS();
      // You can print or log how many were saved
      print("Fetched ${smsSaver.savedMessages.length} transactional SMS.");
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      title: "PayNest: frictionless budgeting app",
      theme: Ytheme.lightTheme,
      darkTheme: Ytheme.darkTheme,
      home: dashboard(),
    );
  }
}
