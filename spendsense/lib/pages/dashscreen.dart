import 'package:flutter/material.dart';
import 'package:spendsense/components/animatedArc.dart';
import 'package:spendsense/components/customArcPainter.dart';
import 'package:spendsense/constants/colors/colors.dart';

class Dashscreen extends StatelessWidget {
  const Dashscreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    int spending = 100;
    int totalbudget = 1000;
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      // crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // const Padding(
        //   padding: EdgeInsets.only(top: 40, bottom: 28, left: 14),
        //   child: Text(
        //     "Dashboard",
        //     style: TextStyle(fontSize: 18),
        //   ),
        // ),
        SizedBox(height:( MediaQuery.of(context).size.height)*0.12,),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Column(children: [
               SizedBox(height: (MediaQuery.of(context).size.height)*0.12,),
               Container(
                width:( MediaQuery.of(context).size.width)*0.74,
                height: ( MediaQuery.of(context).size.height)*0.13,
                child: ArcIndicator(value: 0.6)
               ),
          
              ],
              
              ),
              
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height:( MediaQuery.of(context).size.height)*0.11,),
                  Text("budget1",
                  style: TextTheme.of(context).labelMedium),
                  SizedBox(height: ( MediaQuery.of(context).size.height)*0.006,),
                  Text("1,234",
                  style: TextStyle(
                    fontSize: 50
                  ),),
                  SizedBox(height: ( MediaQuery.of(context).size.height)*0.097,),
                  GestureDetector(
                    onTap: () {
                      // Navigator.push(context, MaterialPageRoute(builder: (context)=>MyInsights()));
                    },
                    child: Container(
                     
                      width: (MediaQuery.of(context).size.width)*0.3,
                      height: (MediaQuery.of(context).size.width)*0.08,
                      decoration: BoxDecoration(
                         color: Ycolor.whitee24,
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Center(child: Text("insights",
                      style: TextTheme.of(context).titleLarge
                      )),
                    ),
                  )
                  
          
                ],
              )
            ],
          ),
        )
      ],
    );
  }
}
