
import 'package:flutter/material.dart';
import 'package:spendsense/components/logout.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => LogoutHelper.signOut(context),
      child: const Text('Logout'),
    );
  }
}
