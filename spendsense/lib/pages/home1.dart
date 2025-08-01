import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:spendsense/components/myAppBar.dart';
import 'package:spendsense/components/navbar.dart';
import 'package:spendsense/pages/transactionTile.dart';

class Home1 extends StatelessWidget {
  const Home1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      bottomNavigationBar: MyNavbar(),
      body: NestedScrollView(
        headerSliverBuilder: (context,bool innerBoxIsScrolled){
          return [const Myappbar()];
        }

        , body: Transactiontile(tittttle: "tittttle"),
    ));
  }
}