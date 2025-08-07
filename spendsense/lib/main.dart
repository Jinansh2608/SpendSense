import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:spendsense/Theme/Ytheme.dart';
import 'package:spendsense/pages/dashboard.dart';
import 'package:spendsense/pages/login_page.dart';
import 'package:spendsense/components/sms_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
    Future.microtask(() async {
      final smsService = SMSService();
      await smsService.saveTransactionSMS();
      print("Fetched ${smsService.savedMessages.length} transactional SMS.");
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "PayNest",
      theme: Ytheme.lightTheme,
      darkTheme: Ytheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: FirebaseAuth.instance.currentUser == null ? '/' : '/dashboard',
      routes: {
        '/': (context) => const LoginPage(),
        '/dashboard': (context) => const dashboard(),
      },
    );
  }
}
