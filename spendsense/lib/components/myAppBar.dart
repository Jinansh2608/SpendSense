import 'package:flutter/material.dart';
import 'package:spendsense/constants/colors/colors.dart';
import 'package:spendsense/pages/Dashscreen.dart';

class Myappbar extends StatefulWidget {
  const Myappbar({super.key});

  @override
  State<Myappbar> createState() => _MyappbarState();
}

class _MyappbarState extends State<Myappbar> {

  int selectedIndex = 0;
  List<String> buttonlabels = ["today","week","month"];
  @override
  Widget build(BuildContext context) {
    return  SliverAppBar(
              title: Center(child: Text("Dashboaard",style: Theme.of(context).textTheme.headlineMedium,)),
              backgroundColor: Ycolor.secondarycolor50  ,
              expandedHeight: (MediaQuery.of(context).size.height)*0.57,
              pinned: true,
              flexibleSpace: const FlexibleSpaceBar(
              background: Dashscreen(),
              ),
              bottom: PreferredSize(preferredSize: const Size.fromHeight(25),
               child: Container(
                height: (MediaQuery.of(context).size.height)*0.0885  ,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(35))
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3,(index) { //the entire purpose of using the list.generate method is to get yhe index once get that
                    final isselected = index == selectedIndex;
                    return Padding(
                      padding: const EdgeInsets.only(top: 28,left: 10,right: 10),
                      child: TextButton(
                        onPressed: (){
                          setState(() {
                            selectedIndex = index;
                          });
                      
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: isselected ? Ycolor.primarycolor50 : Theme.of(context).colorScheme.background,
                          foregroundColor: isselected ? Theme.of(context).colorScheme.background : Ycolor.primarycolor50,
                          padding: EdgeInsets.symmetric(horizontal: 18,vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      
                         child: Text(buttonlabels[index],
                         style: TextTheme.of(context).headlineSmall)),
                    );
                  },)
                ),
               )),
            );
  
  }
}