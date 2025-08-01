import 'package:flutter/material.dart';
import 'package:spendsense/components/navbar.dart';

class Analysis extends StatelessWidget {
  const Analysis({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: MyNavbar(),
      body: Container(child: Text("analysis"),),
    );
  }
}