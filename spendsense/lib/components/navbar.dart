import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconly/iconly.dart';
import 'package:spendsense/Theme/Ytheme.dart';
import 'package:spendsense/components/navigationcontroller.dart';
import 'package:spendsense/constants/colors/colors.dart';

class MyNavbar extends StatelessWidget {
  const MyNavbar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(navigationController());

    return Obx(
      () => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 16, right: 16),
        child: PhysicalModel(
          color: Ycolor.gray10,
          elevation: 5,
          borderRadius: BorderRadius.circular(30),
          shadowColor: Colors.black.withOpacity(0.2),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: NavigationBar(
              backgroundColor:  Theme.of(context).colorScheme.background ,
              height: 70,
              elevation: 0,
              selectedIndex: controller.selectedIndex.value,
              onDestinationSelected: (index) => controller.selectedIndex.value = index,
              indicatorColor: Ycolor.primarycolor50,
              destinations: const [
                NavigationDestination(icon: Icon(IconlyBold.home), label: "Home"),
                NavigationDestination(icon: Icon(IconlyBold.activity), label: "Analysis"),
                NavigationDestination(icon: Icon(IconlyBold.wallet), label: "Bills"),
                NavigationDestination(icon: Icon(IconlyBold.profile), label: "Profile"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
