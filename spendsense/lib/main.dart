import 'package:flutter/material.dart';
import 'package:spendsense/Theme/Ytheme.dart';
import 'package:spendsense/pages/dashboars.dart';

void main() {
  runApp(const PayNest());
}
class PayNest extends StatelessWidget {
  const PayNest({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      title: "PayNest: frictionless budgetting app",
      theme: Ytheme.lightTheme,
      darkTheme: Ytheme.darkTheme,
      home: dashboard(),

    );
  }
}