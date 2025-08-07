import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:spendsense/components/navbar.dart';
import 'package:spendsense/constants/colors/colors.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    // Get current Firebase user
    final User? user = FirebaseAuth.instance.currentUser;

    final String name = user?.displayName ?? 'Guest User';
    final String email = user?.email ?? 'No email';
    final String photoUrl = user?.photoURL ?? '';

    return Scaffold(
      bottomNavigationBar: MyNavbar(),
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
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
                    child: photoUrl.isEmpty
                        ? Icon(Icons.person, size: width * 0.1)
                        : null,
                  ),
                  SizedBox(width: width * 0.04),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: width * 0.05, fontWeight: FontWeight.bold)),
                      SizedBox(height: height * 0.004),
                      Text(email, style: TextStyle(fontSize: width * 0.035, color: const Color.fromARGB(255, 152, 152, 152))),
                      SizedBox(height: height * 0.004),
                      Text('Total balance: ₹5000', style: TextStyle(fontSize: width * 0.035, color: const Color.fromARGB(255, 207, 206, 206), fontWeight: FontWeight.w600)),
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
                  _walletTile(context, 'Bank', 2000, Icons.account_balance),
                  _walletTile(context, 'Cash', 1000, Icons.money),
                  _walletTile(context, 'Savings', 3000, Icons.savings),
                  _walletTile(context, 'Add Wallet', 0, Icons.add, isAdd: true),
                ],
              ),
            ),

            SizedBox(height: height * 0.04),

            // Budgets Section
            Text('Budgets', style: TextStyle(fontSize: width * 0.045, fontWeight: FontWeight.bold)),
            SizedBox(height: height * 0.015),
            Center(
              child: Container(
                width: width * 0.9,
                height: height * 0.15,
                padding: EdgeInsets.all(width * 0.04),
                decoration: BoxDecoration(
                  color: Ycolor.secondarycolor50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Groceries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: width * 0.04)),
                    SizedBox(height: height * 0.005),
                    Text('Spending cap for August', style: TextStyle(fontSize: width * 0.032, color: Colors.grey[600])),
                    SizedBox(height: height * 0.01),
                    Text('₹5,000', style: TextStyle(fontSize: width * 0.045, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            SizedBox(height: height * 0.001),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: Text('Show all budgets', style: TextStyle(color: Ycolor.primarycolor)),
              ),
            ),

            SizedBox(height: height * 0.02),
            ListTile(
              leading: Icon(Icons.repeat),
              title: const Text('Reimbursements'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.logout),
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

    return Container(
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
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          SizedBox(height: height * 0.005),
          isAdd
              ? const SizedBox()
              : Text("₹${amt.toStringAsFixed(2)}", style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
