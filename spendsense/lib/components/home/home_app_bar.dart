import 'package:flutter/material.dart';
import 'package:spendsense/components/home/custom_calendar.dart';
import 'package:spendsense/components/home/wallet_card.dart';
import 'package:spendsense/constants/colors/colors.dart';

class HomeAppBar extends StatelessWidget {
  final double monthlyIncome;
  final double monthlyExpenses;
  final double budget;
  final double budgetSpent;
  final List<Map<String, dynamic>> transactions;

  const HomeAppBar({
    super.key,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.budget,
    required this.budgetSpent,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Ycolor.gray,
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView( // To prevent overflow
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top),
                ElevatedButton.icon(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => CustomCalendar(transactions: transactions),
                    );
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Show Calendar'),
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    WalletCard(
                      title: 'Income',
                      amount: monthlyIncome,
                      icon: Icons.arrow_upward,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(height: 8),
                    WalletCard(
                      title: 'Expenses',
                      amount: monthlyExpenses,
                      icon: Icons.arrow_downward,
                      color: Colors.red.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildBudgetSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetSection() {
    final double progress = budget == 0 ? 0 : (budgetSpent / budget).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Ycolor.whitee,
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Ycolor.gray80,
          valueColor: AlwaysStoppedAnimation<Color>(Ycolor.primarycolor),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '₹${budgetSpent.toStringAsFixed(2)}',
              style: TextStyle(color: Ycolor.whitee),
            ),
            Text(
              '₹${budget.toStringAsFixed(2)}',
              style: TextStyle(color: Ycolor.gray10),
            ),
          ],
        ),
      ],
    );
  }
}