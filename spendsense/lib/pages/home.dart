import 'package:flutter/material.dart';
import 'package:spendsense/pages/infoPanel.dart';

class Transactiontile extends StatelessWidget {
   final String tittttle;
  const Transactiontile({super.key,required this.tittttle});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 20,left: 18),
                      child: Text("data"),
                    ),
                    
                  ),
                  SliverList(
                    
                    delegate: SliverChildBuilderDelegate((context,index){
                      return Padding(
                        padding: EdgeInsets.all(3),
                        child: GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context)=>infoPanel())),
                          child: ListTile(
                           
                            title: Text(tittttle,
                            style: TextStyle(
                              fontSize: 20
                            ),),
                            subtitle: Text("world",style: TextStyle(
                              fontSize: 15
                            ),),
                            trailing: Text("800",
                            style: TextStyle(
                              fontSize: 24
                            ),),
                          ),
                        ),
                      );
                    },
                    childCount: 20)
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        height: (MediaQuery.of(context).size.height*0.15),
                       
                      ),
                    )
                ],
              );
  }
}