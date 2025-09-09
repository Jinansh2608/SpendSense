import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:spendsense/components/navbar.dart';
import 'package:spendsense/constants/colors/colors.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final String baseUrl = "http://192.168.1.103:5000/api"; // API Base URL
  bool isLoading = true;
  List wallets = [];
  List budgets = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => isLoading = true);

    try {
      final walletRes = await http.get(Uri.parse('$baseUrl/wallets/${user.uid}'));
      final budgetRes = await http.get(Uri.parse('$baseUrl/budgets/${user.uid}'));

      if (walletRes.statusCode == 200 && budgetRes.statusCode == 200) {
        setState(() {
          wallets = jsonDecode(walletRes.body)['wallets'];
          budgets = jsonDecode(budgetRes.body)['budgets'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }

    setState(() => isLoading = false);
  }

  Future<void> deleteBudget(String id) async {
    try {
      await http.delete(Uri.parse('$baseUrl/budgets/$id'));
      fetchData();
    } catch (e) {
      debugPrint("Error deleting budget: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final User? user = FirebaseAuth.instance.currentUser;
    final String name = user?.displayName ?? 'Guest User';
    final String email = user?.email ?? 'No email';
    final String photoUrl = user?.photoURL ?? '';

    return Scaffold(
      bottomNavigationBar: MyNavbar(),
      appBar: AppBar(title: const Text('Profile')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/create-budget');
          if (result == true) {
            fetchData();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(width * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Info Box
            Container(
              padding: EdgeInsets.all(width * 0.04),
              decoration: BoxDecoration(
                color: Ycolor.secondarycolor50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: width * 0.1,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                    child: photoUrl.isEmpty ? Icon(Icons.person, size: width * 0.1) : null,
                  ),
                  SizedBox(width: width * 0.04),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: width * 0.05, fontWeight: FontWeight.bold)),
                      SizedBox(height: height * 0.004),
                      Text(email, style: TextStyle(fontSize: width * 0.035, color: Colors.grey)),
                      SizedBox(height: height * 0.004),
                      Text('Total balance: ₹5000',
                          style: TextStyle(fontSize: width * 0.035, color: Colors.grey[400], fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: height * 0.03),

            // Wallets Section
            Text('Wallets', style: TextStyle(fontSize: width * 0.045, fontWeight: FontWeight.bold)),
            SizedBox(height: height * 0.015),
            Center(
              child: Wrap(
                spacing: width * 0.04,
                runSpacing: height * 0.015,
                children: [
                  for (var wallet in wallets)
                    _walletTile(context, wallet['name'], double.tryParse(wallet['balance'].toString()) ?? 0, Icons.account_balance),
                  _walletTile(context, 'Add Wallet', 0, Icons.add, isAdd: true),
                ],
              ),
            ),

            SizedBox(height: height * 0.04),

            // Budgets Section
            Text('Budgets', style: TextStyle(fontSize: width * 0.045, fontWeight: FontWeight.bold)),
            SizedBox(height: height * 0.015),
            if (budgets.isEmpty)
              const Text("No budgets added yet"),
            for (var budget in budgets)
              Container(
                width: width * 0.9,
                margin: const EdgeInsets.only(bottom: 10),
                padding: EdgeInsets.all(width * 0.04),
                decoration: BoxDecoration(
                  color: Ycolor.secondarycolor50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(budget['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: width * 0.04)),
                    SizedBox(height: height * 0.005),
                    Text('Spending cap for ${budget['period']}',
                        style: TextStyle(fontSize: width * 0.032, color: Colors.grey[600])),
                    SizedBox(height: height * 0.01),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('₹${budget['cap']}', style: TextStyle(fontSize: width * 0.045, fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.pushNamed(context, '/edit-budget', arguments: budget);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteBudget(budget['id'].toString()),
                            ),
                          ],
                        )
                      ],
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {}, // Can navigate to "All Budgets" page
                child: Text('Show all budgets', style: TextStyle(color: Ycolor.primarycolor)),
              ),
            ),

            SizedBox(height: height * 0.02),
            ListTile(leading: const Icon(Icons.repeat), title: const Text('Reimbursements'), onTap: () {}),
            ListTile(leading: const Icon(Icons.help_outline), title: const Text('Help & Support'), onTap: () {}),
            ListTile(leading: const Icon(Icons.settings), title: const Text('Settings'), onTap: () {}),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _walletTile(BuildContext context, String label, double amt, IconData icon, {bool isAdd = false}) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        if (isAdd) {
          Navigator.pushNamed(context, '/create-wallet'); // Navigate to Add Wallet Page
        }
      },
      child: Container(
        height: height * 0.14,
        width: width * 0.44,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAdd ? Colors.transparent : Ycolor.secondarycolor50,
          borderRadius: BorderRadius.circular(16),
          border: isAdd ? Border.all(color: Ycolor.secondarycolor) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: isAdd ? Ycolor.secondarycolor : Ycolor.gray10),
            SizedBox(height: height * 0.005),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            SizedBox(height: height * 0.005),
            isAdd
                ? const SizedBox()
                : Text("₹${amt.toStringAsFixed(2)}", style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}
