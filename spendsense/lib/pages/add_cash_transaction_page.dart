import 'package:flutter/material.dart';

class AddCashTransactionPage extends StatelessWidget {
  const AddCashTransactionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Cash Transaction'),
      ),
      body: const Center(
        child: Text('Add Cash Transaction Form'),
      ),
    );
  }
}
