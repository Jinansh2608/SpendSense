import 'package:flutter/material.dart';
import 'package:spendsense/components/navbar.dart';
import 'package:spendsense/constants/colors/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BillsPage extends StatefulWidget {
  const BillsPage({super.key});

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  String selectedFilter = 'All';
  bool isLoading = true;

  List<Map<String, dynamic>> bills = [];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String baseUrl = "http://192.168.1.100:5000"; // ✅ Your Flask backend IP

  @override
  void initState() {
    super.initState();
    fetchBills();
  }

  /// ✅ Get Firebase UID
  String? getUid() {
    final user = _auth.currentUser;
    return user?.uid;
  }

  /// ✅ Fetch bills from API based on filter
  Future<void> fetchBills() async {
    final uid = getUid();
    if (uid == null) {
      print("User not logged in");
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.get(Uri.parse('$baseUrl/bills?uid=$uid&filter=$selectedFilter'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          bills = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        print("Failed to fetch bills: ${response.statusCode}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching bills: $e");
      setState(() => isLoading = false);
    }
  }

  /// ✅ Handle filter button click
  void onFilterChange(String filter) {
    setState(() => selectedFilter = filter);
    fetchBills();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      bottomNavigationBar: MyNavbar(),
      appBar: AppBar(title: const Text('Your Bills')),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: ['All', 'Paid', 'Unpaid'].map((filter) {
                final isSelected = selectedFilter == filter;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.01),
                  child: ElevatedButton(
                    onPressed: () => onFilterChange(filter),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? Ycolor.secondarycolor : Colors.grey[300],
                      foregroundColor: isSelected ? Colors.white : Colors.black,
                      padding: EdgeInsets.symmetric(horizontal: width * 0.025, vertical: height * 0.008),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(filter),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: height * 0.02),

            /// ✅ Show loading indicator or bills list
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : bills.isEmpty
                  ? const Center(child: Text("No bills found"))
                  : ListView.builder(
                itemCount: bills.length + 1,
                itemBuilder: (context, index) {
                  if (index == bills.length) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: height * 0.012),
                      child: GestureDetector(
                        onTap: () {
                          // Add your 'Add New Bill' functionality here
                        },
                        child: Container(
                          padding: EdgeInsets.all(width * 0.04),
                          decoration: BoxDecoration(
                            border: Border.all(color: Ycolor.secondarycolor),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: Ycolor.secondarycolor),
                              const SizedBox(width: 8),
                              Text('Add New Bill',
                                  style: TextStyle(
                                      color: Ycolor.secondarycolor, fontWeight: FontWeight.w500))
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  final bill = bills[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: height * 0.008),
                    child: ListTile(
                      leading: Icon(
                        bill['status'] == 'Paid' ? Icons.check_circle : Icons.warning,
                        color: bill['status'] == 'Paid' ? Colors.green : Colors.red,
                      ),
                      title: Text(bill['name'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Due: ${bill['due_date'] ?? ''}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${bill['amount'] ?? 0}', style: TextStyle(fontSize: width * 0.04)),
                          Text(bill['status'] ?? '',
                              style: TextStyle(
                                  fontSize: width * 0.03,
                                  color: bill['status'] == 'Paid' ? Colors.green : Colors.red)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
