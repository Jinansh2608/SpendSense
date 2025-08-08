import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:spendsense/components/myAppBar.dart';
import 'package:spendsense/components/navbar.dart';

class Home1 extends StatefulWidget {
  const Home1({super.key});

  @override
  State<Home1> createState() => _Home1State();
}

class _Home1State extends State<Home1> {
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          errorMessage = 'User not logged in';
          isLoading = false;
        });
        return;
      }

      final uid = user.uid;
      final url = Uri.parse('http://192.168.1.105:5000/records/$uid');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          transactions =
              data.map((item) => item as Map<String, dynamic>).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load data';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Widget buildTransactionTile(Map<String, dynamic> transaction) {
    final amount = transaction['amount']?.toString() ?? '-';
    final type = transaction['type'] ?? 'Unknown';
    final datetime = transaction['datetime'] ?? '';
    final sender = transaction['sender'] ?? 'N/A';
    final receiver = transaction['receiver'] ?? 'N/A';
    final category = transaction['category'] ?? 'Uncategorized';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: ListTile(
        title: Text('₹$amount'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Sender: $sender'),
            Text('Category: $category'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: MyNavbar(),
      body: NestedScrollView(
        headerSliverBuilder: (context, bool innerBoxIsScrolled) {
          return [const Myappbar()];
        },
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
            ? Center(child: Text(errorMessage))
            : ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            return buildTransactionTile(transactions[index]);
          },
        ),
      ),
    );
  }
}
