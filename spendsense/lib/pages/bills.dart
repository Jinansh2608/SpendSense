import 'package:flutter/material.dart';
import 'package:spendsense/components/navbar.dart';

class Bills extends StatelessWidget {
  const Bills({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: MyNavbar(),
      body: Container(child: Text("bills"),),
    );
  }
}