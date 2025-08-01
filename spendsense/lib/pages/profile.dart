import 'package:flutter/material.dart';
import 'package:spendsense/components/navbar.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: MyNavbar(),
      body: Container(child: Text("data"),),
    );
  }
}