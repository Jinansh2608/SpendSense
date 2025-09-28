import 'package:flutter/material.dart';
import 'package:spendsense/constants/colors/colors.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Ycolor.gray,
        elevation: 0,
      ),
      backgroundColor: Ycolor.gray,
      body: ListView(
        children: [
          _buildHelpTile(Icons.quiz_outlined, 'Frequently Asked Questions', 'Find answers to common questions.', () {}),
          _buildHelpTile(Icons.contact_support_outlined, 'Contact Us', 'Get in touch with our support team.', () {}),
          _buildHelpTile(Icons.bug_report_outlined, 'Report a Bug', 'Let us know about a technical issue.', () {}),
          _buildHelpTile(Icons.feedback_outlined, 'Send Feedback', 'Share your suggestions with us.', () {}),
        ],
      ),
    );
  }

  Widget _buildHelpTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Ycolor.primarycolor, size: 32),
      title: Text(title, style: TextStyle(color: Ycolor.whitee, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: Ycolor.gray10)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Ycolor.gray60),
      onTap: onTap,
    );
  }
}
