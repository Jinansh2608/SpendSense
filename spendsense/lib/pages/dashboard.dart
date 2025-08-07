import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:spendsense/components/myAppBar.dart';
import 'package:spendsense/components/navbar.dart';
import 'package:spendsense/components/navigationcontroller.dart';
import 'package:spendsense/constants/colors/colors.dart';
import 'package:spendsense/pages/analysis.dart';
import 'package:spendsense/pages/bills.dart';
import 'package:spendsense/pages/home1.dart';
import 'package:spendsense/pages/profile.dart';
import 'package:spendsense/pages/transactionTile.dart';

class dashboard extends StatelessWidget {
  const dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      Home1(),
      AnalysisPage(),
      BillsPage(),
      ProfilePage(),
    ];
    final controller = Get.put(navigationController());
    return Obx(() => pages[controller.selectedIndex.value]);
  }
}
