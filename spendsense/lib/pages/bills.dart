import 'package:flutter/material.dart';
import 'package:spendsense/components/navbar.dart';
import 'package:spendsense/constants/colors/colors.dart';

class BillsPage extends StatefulWidget {
  const BillsPage({super.key});

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  String selectedFilter = 'All';

  final List<Map<String, dynamic>> allBills = [
    {'name': 'Electricity', 'dueDate': '2025-08-10', 'status': 'Paid', 'amount': 1200},
    {'name': 'Water', 'dueDate': '2025-08-12', 'status': 'Unpaid', 'amount': 300},
    {'name': 'Internet', 'dueDate': '2025-08-15', 'status': 'Paid', 'amount': 999},
    {'name': 'Phone', 'dueDate': '2025-08-18', 'status': 'Unpaid', 'amount': 650},
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    List<Map<String, dynamic>> filteredBills = selectedFilter == 'All'
        ? allBills
        : allBills.where((bill) => bill['status'] == selectedFilter).toList();

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
                    onPressed: () => setState(() => selectedFilter = filter),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ?Ycolor.secondarycolor : Colors.grey[300],
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
            Expanded(
              child: ListView.builder(
                itemCount: filteredBills.length + 1,
                itemBuilder: (context, index) {
                if (index == filteredBills.length) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: height * 0.012),
                    child: GestureDetector(
                      onTap: () {
                        // Add your 'Add New Bill' functionality here
                      },
                      child: Container(
                        padding: EdgeInsets.all(width * 0.04),
                        decoration: BoxDecoration(
                          border: Border.all(color:Ycolor.secondarycolor),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Ycolor.secondarycolor),
                            SizedBox(width: 8),
                            Text('Add New Bill', style: TextStyle(color: Ycolor.secondarycolor, fontWeight: FontWeight.w500))
                          ],
                        ),
                      ),
                    ),
                  );
                }
                final bill = filteredBills[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: height * 0.008),
                    child: ListTile(
                      leading: Icon(
                        bill['status'] == 'Paid' ? Icons.check_circle : Icons.warning,
                        color: bill['status'] == 'Paid' ? Colors.green : Colors.red,
                      ),
                      title: Text(bill['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Due: ${bill['dueDate']}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${bill['amount']}', style: TextStyle(fontSize: width * 0.04)),
                          Text(bill['status'],
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
