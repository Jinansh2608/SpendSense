import 'package:flutter/material.dart';
import 'package:spendsense/components/bills/bills_list.dart';
import 'package:spendsense/components/bills/filter_buttons.dart';
import 'package:spendsense/components/navbar.dart';
import 'package:spendsense/pages/add_bill_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:spendsense/constants/api_constants.dart';

class BillsPage extends StatefulWidget {
  const BillsPage({super.key});

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  String selectedFilter = 'All';
  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> bills = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    fetchBills();
  }

  String? getUid() {
    final user = _auth.currentUser;
    return user?.uid;
  }

  Future<void> fetchBills() async {
    final uid = getUid();
    if (uid == null) {
      setState(() {
        errorMessage = "User not logged in";
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/bills/$uid?filter=$selectedFilter'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          bills = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Failed to fetch bills: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Error fetching bills: $e";
        isLoading = false;
      });
    }
  }

  void onFilterChange(String filter) {
    setState(() => selectedFilter = filter);
    fetchBills();
  }

  void _navigateToAddBillPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddBillPage()),
    );
    if (result == true) {
      fetchBills();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Bills'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            FilterButtons(
              selectedFilter: selectedFilter,
              onFilterChanged: onFilterChange,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                  ? Center(child: Text(errorMessage!))
                  : bills.isEmpty
                  ? const Center(child: Text("No bills found"))
                  : BillsList(bills: bills),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddBillPage,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const MyNavbar(),
    );
  }
}
