import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:spendsense/components/myAppBar.dart';
import 'package:spendsense/components/navbar.dart';
import 'package:spendsense/constants/colors/colors.dart';
import 'package:spendsense/pages/transactionTile.dart'; // Import the perfected tile

class Home1 extends StatefulWidget {
  const Home1({super.key});

  @override
  State<Home1> createState() => _Home1State();
}

class _Home1State extends State<Home1> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String _errorMessage = '';
  double _monthlyIncome = 0.0;
  double _monthlyExpenses = 0.0;
  String _selectedFilter = 'all'; // 'all', 'income', 'expenses'

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final url = Uri.parse(
        'http://192.168.1.110:5000/api/records/${user.uid}?limit=100',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> data = decoded['data'];
        final summary = decoded['summary'];

        if (mounted) {
          setState(() {
            _transactions =
                data.map((item) => item as Map<String, dynamic>).toList();
            _monthlyIncome = (summary['monthlyIncome'] as num).toDouble();
            _monthlyExpenses = (summary['monthlyExpenses'] as num).toDouble();
          });
        }
      } else {
        throw Exception('Failed to load data (Status ${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double arcValue;
    if (_monthlyIncome == 0) {
      arcValue = _monthlyExpenses > 0 ? 1.0 : 0.0;
    } else {
      arcValue = (_monthlyExpenses / _monthlyIncome).clamp(0.0, 1.0);
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: Ycolor.gray,
      bottomNavigationBar: const MyNavbar(),
      body: NestedScrollView(
        headerSliverBuilder: (context, bool innerBoxIsScrolled) {
          return [Myappbar(arcValue: arcValue)];
        },
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage.isNotEmpty) {
      return _buildErrorWidget();
    }
    return RefreshIndicator(
      onRefresh: _fetchTransactions,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildSummarySection()),
          SliverToBoxAdapter(child: _buildFilterSection()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Recent Transactions',
                style: TextStyle(
                  color: Ycolor.whitee,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          _buildTransactionList(),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: _selectedFilter == 'all',
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedFilter = 'all';
                });
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Income'),
            selected: _selectedFilter == 'income',
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedFilter = 'income';
                });
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Expenses'),
            selected: _selectedFilter == 'expenses',
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedFilter = 'expenses';
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Income',
              _monthlyIncome,
              Icons.arrow_upward,
              Colors.green.shade700,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Expenses',
              _monthlyExpenses,
              Icons.arrow_downward,
              Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: Ycolor.gray80,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Ycolor.gray10, fontSize: 14),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '₹${amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: Ycolor.whitee,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    List<Map<String, dynamic>> filteredTransactions = _transactions;
    if (_selectedFilter == 'income') {
      filteredTransactions = _transactions
          .where((t) => t['txn_type'] == 'Credit')
          .toList();
    } else if (_selectedFilter == 'expenses') {
      filteredTransactions = _transactions
          .where((t) => t['txn_type'] == 'Debit')
          .toList();
    }

    if (filteredTransactions.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          heightFactor: 5,
          child: Text(
            'No transactions for this filter.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => TransactionTile(transaction: filteredTransactions[index]),
        childCount: filteredTransactions.length,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 16),
          Text(
            'Failed to load transactions',
            style: TextStyle(color: Ycolor.whitee, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage,
            style: TextStyle(color: Ycolor.gray10),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchTransactions,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Ycolor.primarycolor,
            ),
          ),
        ],
      ),
    );
  }
}