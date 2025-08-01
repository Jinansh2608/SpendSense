import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:spendsense/components/myAppBar.dart';
import 'package:spendsense/components/navbar.dart';
import 'package:spendsense/components/navigationcontroller.dart';
import 'package:spendsense/constants/colors/colors.dart';
import 'package:spendsense/pages/home.dart';


class dashboard extends StatelessWidget {
  const dashboard({super.key});
  
  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      Transactiontile(tittttle: "tittttle"),
      Container(child: Text("analysis"),),
      Container(child: Text("bills"),),
      Container(child: Text("profile"),)
    ];
    final controller = Get.put(navigationController());
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: MyNavbar(),
      body: NestedScrollView(
        headerSliverBuilder: (context,bool innerBoxIsScrolled){
          return [const Myappbar()];
        }

        , body: Obx(()=> pages[controller.selectedIndex.value])),
    );
  }
}