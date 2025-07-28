import 'package:flutter/material.dart';
import 'package:spendsense/Theme/texttheme.dart';
import 'package:spendsense/constants/colors/colors.dart';

class Ytheme{

  Ytheme._(); //this is used as singleton class so basically it makes the class private this can also be known as a factory constructor where only one object is created adn used
   
  static ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Ycolor.primarycolor,
      background: Ycolor.whitee,
      primary: Ycolor.primarycolor,
      primaryContainer: Ycolor.whitee80,
      secondary: Ycolor.secondarycolor,
      brightness: Brightness.light,
      ),
    useMaterial3: true,
    primaryColor: Ycolor.primarycolor,
    fontFamily: 'Manrope',
    brightness: Brightness.light,
    scaffoldBackgroundColor:  Ycolor.whitee80,
    textTheme: YTexttheme.lightTextTheme()

  );


  static ThemeData darkTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Ycolor.primarycolor,
      background: Ycolor.gray80,
      primary: Ycolor.primarycolor,
      primaryContainer: Ycolor.gray60,
      secondary: Ycolor.secondarycolor,
      brightness: Brightness.dark,
      ),
    useMaterial3: true,
    primaryColor: Ycolor.primarycolor,
    fontFamily: 'Manrope',
    brightness: Brightness.dark,
    scaffoldBackgroundColor:  Ycolor.gray80,
    textTheme: YTexttheme.darkTextTheme()

  );



}