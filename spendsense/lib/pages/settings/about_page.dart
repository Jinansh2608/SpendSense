import 'package:flutter/material.dart';
import 'package:spendsense/constants/colors/colors.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About SpendSense'),
        backgroundColor: Ycolor.gray,
        elevation: 0,
      ),
      backgroundColor: Ycolor.gray,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FlutterLogo(size: 80),
              const SizedBox(height: 24),
              Text(
                'SpendSense',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Ycolor.whitee),
              ),
              const SizedBox(height: 8),
              Text(
                'Version 1.0.0', // Replace with dynamic version info if available
                style: TextStyle(fontSize: 16, color: Ycolor.gray10),
              ),
              const Spacer(),
              Text(
                '© 2025 SpendSense. All Rights Reserved.',
                style: TextStyle(fontSize: 12, color: Ycolor.gray60),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
