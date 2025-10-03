import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:spendsense/components/navbar.dart';
import 'package:spendsense/constants/colors/colors.dart';
import 'package:spendsense/pages/transactionTile.dart';
import 'package:spendsense/components/home/home_app_bar.dart';
import 'package:spendsense/pages/add_cash_transaction_page.dart';
import 'package:spendsense/components/bloc/budgets.dart';

import 'package:spendsense/constants/api_constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String _errorMessage = '';
  double _monthlyIncome = 0.0;
  double _monthlyExpenses = 0.0;
  double _cashBalance = 0.0;
  double _budget = 0.0;
  double _budgetSpent = 0.0;
  String _selectedFilter = 'digital'; // 'digital', 'cash'

  final BudgetService _budgetService = BudgetService();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Fetch transactions
      final transactionsUrl = Uri.parse(
        '${ApiConstants.baseUrl}/records/${user.uid}?limit=100',
      );
      final transactionsResponse = await http.get(transactionsUrl);

      if (transactionsResponse.statusCode == 200) {
        final decoded = json.decode(transactionsResponse.body);
        final List<dynamic> data = decoded['data'];
        final summary = decoded['summary'];

        double cashBalance = 0;
        for (var transaction in data) {
          if (transaction['paymentMode'] == 'PaymentMode.cash') {
            if (transaction['txn_type'] == 'Credit') {
              cashBalance += (transaction['amount'] as num).toDouble();
            } else {
              cashBalance -= (transaction['amount'] as num).toDouble();
            }
          }
        }

        if (mounted) {
          setState(() {
            _transactions = data
                .map((item) => item as Map<String, dynamic>)
                .toList();
            _monthlyIncome = (summary['monthlyIncome'] as num).toDouble();
            _monthlyExpenses = (summary['monthlyExpenses'] as num).toDouble();
            _cashBalance = cashBalance;
          });
        }
      } else {
        throw Exception('Failed to load data (Status ${transactionsResponse.statusCode})');
      }

      // Fetch budgets
      final budgets = await _budgetService.getBudgets(user.uid);
      if (budgets.isNotEmpty) {
        // Assuming the first budget is the one we want to show
        final budget = budgets.first;
        if (mounted) {
          setState(() {
            _budget = (budget['cap'] as num).toDouble();
            // For now, let's assume budgetSpent is the same as monthlyExpenses
            _budgetSpent = _monthlyExpenses;
          });
        }
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
    return Scaffold(
      extendBody: true,
      backgroundColor: Ycolor.gray,
      bottomNavigationBar: const MyNavbar(),
      floatingActionButton: _selectedFilter == 'cash'
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddCashTransactionPage(),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
      body: NestedScrollView(
        headerSliverBuilder: (context, bool innerBoxIsScrolled) {
          return [
            HomeAppBar(
              monthlyIncome: _monthlyIncome,
              monthlyExpenses: _monthlyExpenses,
              budget: _budget,
              budgetSpent: _budgetSpent,
              transactions: _transactions,
            )
          ];
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
      onRefresh: _fetchData,
      child: CustomScrollView(
        slivers: [
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
            label: const Text('Digital Payments'),
            selected: _selectedFilter == 'digital',
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedFilter = 'digital';
                });
              }
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Cash'),
            selected: _selectedFilter == 'cash',
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedFilter = 'cash';
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    // TODO: Filter transactions based on _selectedFilter
    List<Map<String, dynamic>> filteredTransactions = _transactions;

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
        (context, index) =>
            TransactionTile(transaction: filteredTransactions[index]),
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
            onPressed: _fetchData,
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