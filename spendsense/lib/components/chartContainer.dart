// lib/widgets/analysis/chart_container.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:spendsense/constants/colors/colors.dart';

class ChartContainer extends StatelessWidget {
  final bool isWeekly;

  const ChartContainer({super.key, required this.isWeekly});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final totalSpend = isWeekly ? 21.0 : 35.0; // Example totals

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Ycolor.secondarycolor50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isWeekly ? "This Week's Spending" : "This Month's Spending",
            style: TextStyle(fontSize: width * 0.045, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: height * 0.008),
          Text(
            "Total: ₹${totalSpend.toStringAsFixed(2)}",
            style: TextStyle(fontSize: width * 0.035, color: Colors.grey[600]),
          ),
          SizedBox(height: height * 0.02),
          SizedBox(
            height: height * 0.22,
            child: BarChart(
              BarChartData(
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    
                    
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        "₹${rod.toY.toStringAsFixed(1)}",
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
                barGroups: _generateBarData(isWeekly),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (value, meta) {
                        final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final weeks = ['W1', 'W2', 'W3', 'W4'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            isWeekly ? days[value.toInt()] : weeks[value.toInt()],
                            style: TextStyle(fontSize: width * 0.03, fontWeight: FontWeight.w500),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _generateBarData(bool isWeekly) {
    final data = isWeekly
        ? [3.0, 4.0, 2.5, 3.5, 4.5, 2.0, 1.5]
        : [10.0, 9.5, 8.0, 7.5];

    return List.generate(
      data.length,
      (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: data[i],
            width: 12,
            borderRadius: BorderRadius.circular(4),
            color: Ycolor.secondarycolor,
          ),
        ],
      ),
    );
  }
}
