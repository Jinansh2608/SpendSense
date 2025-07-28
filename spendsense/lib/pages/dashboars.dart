import 'package:flutter/material.dart';
import 'package:spendsense/components/myAppBar.dart';
import 'package:spendsense/constants/colors/colors.dart';


class dashboard extends StatelessWidget {
  const dashboard({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context,bool innerBoxIsScrolled){
          return [const Myappbar()];
        }
        
        , body: Container(color: Theme.of(context).scaffoldBackgroundColor,)),
    );
  }
}