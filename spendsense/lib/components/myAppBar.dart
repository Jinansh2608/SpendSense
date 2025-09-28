import 'package:flutter/material.dart';
import 'package:spendsense/auth/authcontroller.dart';
import 'package:spendsense/constants/colors/colors.dart';
import 'package:spendsense/pages/Dashscreen.dart';

class Myappbar extends StatefulWidget {
  final double arcValue;
  const Myappbar({super.key, required this.arcValue});

  @override
  State<Myappbar> createState() => _MyappbarState();
}

class _MyappbarState extends State<Myappbar> {
  int selectedIndex = 0;
  List<String> buttonlabels = ["today", "week", "month"];

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      title: Center(
        child: Row(
  children: [
    IconButton(
      icon: Icon(Icons.logout_rounded),
      onPressed: () {
        // handle logout
      },
    ),
    Spacer(), // pushes text to center
    Text(
      "Dashboard",
      style: Theme.of(context).textTheme.headlineMedium,
    ),
    Spacer(), // balances the left spacer
    IconButton(
  icon: const Icon(Icons.logout_rounded),
  onPressed: () async {
    await AuthController.to.signOut();
    // ⬅️ replace with your actual login screen widget
  },
),

  ],
)

      ),
      backgroundColor: Ycolor.secondarycolor50,
      expandedHeight: MediaQuery.of(context).size.height * 0.57,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Center( // ✅ keeps Dashscreen centered
          child: Dashscreen(arcValue: widget.arcValue),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(25),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.0885,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (index) {
                final isselected = index == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(top: 20, left: 5, right: 5),
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: isselected
                          ? Ycolor.primarycolor50
                          : Theme.of(context).colorScheme.background,
                      foregroundColor: isselected
                          ? Theme.of(context).colorScheme.background
                          : Ycolor.primarycolor50,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    child: Text(buttonlabels[index],
                        style: Theme.of(context).textTheme.headlineSmall),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}