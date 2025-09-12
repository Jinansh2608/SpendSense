import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:spendsense/auth/authpage.dart';
import 'auth/authcontroller.dart';
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
  Get.put(AuthController()); 
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

      // ✅ Send to Flask API after reading SMS
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? "test-user-uid"; // fallback if user not logged in
      await smsService.sendTransactionSMS(uid);
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return const dashboard(); // ✅ If signed in
          }

          return  AuthPage(); // ❌ If not signed in
        },
      ),
    );
  }
}
