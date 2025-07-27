import 'package:flutter/material.dart';
import 'package:spendsense/constants/colors/colors.dart';

class Myappbar extends StatefulWidget {
  const Myappbar({super.key});

  @override
  State<Myappbar> createState() => _MyappbarState();
}

class _MyappbarState extends State<Myappbar> {
  @override
  Widget build(BuildContext context) {
    return  SliverAppBar(
              title: Center(child: Text("Dashboaard",style: TextStyle(color: Ycolor.whitee),)),
              backgroundColor: Ycolor.secondarycolor50  ,
              expandedHeight: (MediaQuery.of(context).size.height)*0.57,
              pinned: true,
              flexibleSpace: const FlexibleSpaceBar(
              background: Placeholder(),
              ),
              bottom: PreferredSize(preferredSize: const Size.fromHeight(25),
               child: Container(
                height: (MediaQuery.of(context).size.height)*0.09  ,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(35))
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // MyDay(isselected: true),
                    
                    // MyDay(isselected: false),
                    
                    // MyDay(isselected: false),
                    // Padding(
                    //   padding: const EdgeInsets.only(top: 23,left: 10,right: 10),
                    //   child: Container(
                    //     width:( MediaQuery.of(context).size.width)*0.2,
                    //     height: ( MediaQuery.of(context).size.width)*0.1,
                    //     decoration: BoxDecoration(
                    //       color: Tcolor.secondarycolor,
                    //       borderRadius: BorderRadius.circular(6)
                    //     ),
                    //     child: Center(child: Text("data",
                    //     style: TextStyle(
                    //       color: Tcolor.gray80
                    //     ),
                    //     )),
                    //   ),
                    // ),
                    // Padding(
                    //   padding: const EdgeInsets.only(top: 23,left: 10,right: 10),
                    //   child: GestureDetector(
                    //     onTap: () {
                    //       setState(() {
                            
                    //       });
                    //     },
                    //     child: Container(
                    //       width:( MediaQuery.of(context).size.width)*0.2,
                    //       height: ( MediaQuery.of(context).size.width)*0.1,
                    //       decoration: BoxDecoration(
                    //         color: Tcolor.gray60,
                    //         borderRadius: BorderRadius.circular(6)
                    //       ),
                    //       child: Center(child: Text("data")),
                    //     ),
                    //   ),
                    // ),
                    // Padding(
                    //   padding: const EdgeInsets.only(top: 23,left: 10,right: 10),
                    //   child: Container(
                    //     width:( MediaQuery.of(context).size.width)*0.2,
                    //     height: ( MediaQuery.of(context).size.width)*0.1,
                    //     decoration: BoxDecoration(
                    //       color: Tcolor.gray60,
                    //       borderRadius: BorderRadius.circular(6)
                    //     ),
                    //     child: Center(child: Text("data")),
                    //   ),
                    // )
                  ],
                ),
               )),
            );
  
  }
}