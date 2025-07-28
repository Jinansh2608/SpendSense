import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:spendsense/components/navigationcontroller.dart';
class MyNavbar extends StatelessWidget {
  const MyNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(navigationController());

    return Obx(
      () => NavigationBar(
        elevation: 0,
        height: 70,
        selectedIndex: controller.selectedIndex.value,
        onDestinationSelected: (index) => controller.selectedIndex.value = index,
        destinations: [
        NavigationDestination(icon: Icon(IconlyBold.home), label: "Home"),
        NavigationDestination(icon: Icon(IconlyBold.activity), label: "analysis"),
        NavigationDestination(icon: Icon(IconlyBold.wallet), label: "bills"),
        NavigationDestination(icon: Icon(IconlyBold.profile), label: "profile"),
        ]),
    );

  }
}
