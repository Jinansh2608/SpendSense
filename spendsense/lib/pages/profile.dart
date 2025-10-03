import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:spendsense/components/navbar.dart';
import 'package:spendsense/constants/colors/colors.dart';
import 'package:spendsense/pages/settings/about_page.dart';
import 'package:spendsense/pages/settings/edit_profile_page.dart';
import 'package:spendsense/pages/settings/help_page.dart';
import 'package:spendsense/pages/settings/manage_categories_page.dart';
import 'package:spendsense/pages/settings/payment_dashboard_page.dart';
import 'package:spendsense/pages/settings/reimbursements_page.dart';

import 'package:spendsense/constants/api_constants.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  double _totalBalance = 0.0;
  List _wallets = [];
  List _budgets = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final walletRes = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/wallets/${user.uid}'),
      );
      final budgetRes = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/budgets/${user.uid}'),
      );

      double totalBalance = 0.0;
      if (mounted && walletRes.statusCode == 200) {
        final walletData = jsonDecode(walletRes.body)['wallets'];
        _wallets = walletData;
        for (var wallet in _wallets) {
          totalBalance += double.tryParse(wallet['balance'].toString()) ?? 0.0;
        }
      }

      if (mounted && budgetRes.statusCode == 200) {
        _budgets = jsonDecode(budgetRes.body)['budgets'];
      }

      if (mounted) {
        setState(() {
          _totalBalance = totalBalance;
        });
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to load data.')));
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBudget(String id) async {
    try {
      final response = await http.delete(Uri.parse('${ApiConstants.baseUrl}/budgets/$id'));
      if (response.statusCode == 200) {
        _fetchData(); // Refresh data after deleting
      }
    } catch (e) {
      debugPrint("Error deleting budget: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const MyNavbar(),
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Ycolor.whitee,
      ),
      backgroundColor: Ycolor.gray,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/create-budget');
          if (result == true) {
            _fetchData();
          }
        },
        backgroundColor: Ycolor.primarycolor,
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  _buildWalletsSection(context),
                  const SizedBox(height: 24),
                  _buildBudgetsSection(context),
                  const SizedBox(height: 24),
                  _buildSettings(context),
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'Guest User';
    final email = user?.email ?? 'no-email@provider.com';
    final photoUrl = user?.photoURL ?? '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Ycolor.gray80,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Ycolor.gray70,
              backgroundImage: photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: photoUrl.isEmpty
                  ? Icon(Icons.person, size: 32, color: Ycolor.gray10)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Ycolor.whitee,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(fontSize: 14, color: Ycolor.gray10),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Balance: ₹${_totalBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Ycolor.primarycolor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wallets',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Ycolor.whitee,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (var wallet in _wallets)
              _walletTile(
                context,
                wallet['name'],
                double.tryParse(wallet['balance'].toString()) ?? 0,
                Icons.account_balance_wallet_outlined,
              ),
            _walletTile(context, 'Add Wallet', 0, Icons.add, isAdd: true),
          ],
        ),
      ],
    );
  }

  Widget _buildBudgetsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budgets',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Ycolor.whitee,
          ),
        ),
        const SizedBox(height: 16),
        ..._budgets.map((budget) => _budgetCard(context, budget)),
      ],
    );
  }

  Widget _budgetCard(BuildContext context, Map<String, dynamic> budget) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Ycolor.secondarycolor50,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              budget['name'],
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Ycolor.whitee,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Spending cap for ${budget['period']}',
              style: TextStyle(fontSize: 13, color: Ycolor.gray10),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${budget['cap']}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Ycolor.whitee,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => Navigator.pushNamed(
                        context,
                        '/edit-budget',
                        arguments: budget,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteBudget(budget['id'].toString()),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _walletTile(
    BuildContext context,
    String label,
    double amt,
    IconData icon, {
    bool isAdd = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (isAdd) {
          Navigator.pushNamed(context, '/create-wallet');
        }
      },
      child: Container(
        width: (MediaQuery.of(context).size.width / 2) - 24,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAdd ? Colors.transparent : Ycolor.secondarycolor50,
          borderRadius: BorderRadius.circular(16),
          border: isAdd ? Border.all(color: Ycolor.secondarycolor) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: isAdd ? Ycolor.secondarycolor : Ycolor.gray10,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Ycolor.whitee,
              ),
            ),
            if (!isAdd) ...[
              const SizedBox(height: 4),
              Text(
                "₹${amt.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 13, color: Ycolor.gray10),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSettings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Ycolor.whitee,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(
          context,
          title: 'General',
          children: [
            _buildSettingsTile(
              context,
              icon: Icons.edit_outlined,
              title: 'Edit Profile',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              ),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.category_outlined,
              title: 'Manage Categories',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ManageCategoriesPage(),
                ),
              ),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.receipt_long_outlined,
              title: 'Reimbursements',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReimbursementsPage(),
                ),
              ),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.payment_outlined,
              title: 'Payment Reminders',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentDashboardPage(),
                ),
              ),
            ),
          ],
        ),
        _buildSettingsCard(
          context,
          title: 'Preferences',
          children: [
            SwitchListTile(
              secondary: Icon(
                Icons.notifications_outlined,
                color: Ycolor.gray10,
              ),
              title: Text(
                'Enable Notifications',
                style: TextStyle(color: Ycolor.whitee),
              ),
              value: _notificationsEnabled,
              onChanged: (bool value) =>
                  setState(() => _notificationsEnabled = value),
              activeColor: Ycolor.primarycolor,
            ),
          ],
        ),
        _buildSettingsCard(
          context,
          title: 'Support & Legal',
          children: [
            _buildSettingsTile(
              context,
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpPage()),
              ),
            ),
            _buildSettingsTile(
              context,
              icon: Icons.info_outline,
              title: 'About SpendSense',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildLogoutButton(context),
        const SizedBox(height: 8),
        Center(child: _buildDeleteAccountButton(context)),
      ],
    );
  }

  Card _buildSettingsCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      color: Ycolor.gray80,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 12.0, bottom: 4.0),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                color: Ycolor.gray60,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  ListTile _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Ycolor.gray10),
      title: Text(title, style: TextStyle(color: Ycolor.whitee)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Ycolor.gray60),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Ycolor.primarycolor50.withAlpha(128),
          foregroundColor: Ycolor.primarycolor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
        },
      ),
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context) {
    return TextButton(
      child: const Text(
        'Delete Account',
        style: TextStyle(color: Colors.redAccent),
      ),
      onPressed: () => _showDeleteConfirmationDialog(context),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Ycolor.gray70,
        title: Text('Are you sure?', style: TextStyle(color: Ycolor.whitee)),
        content: Text(
          'This action is permanent and cannot be undone. All your data will be erased.',
          style: TextStyle(color: Ycolor.gray10),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Ycolor.primarycolor)),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement account deletion logic
              Navigator.pop(context);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
