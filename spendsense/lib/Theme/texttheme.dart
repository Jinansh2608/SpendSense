import 'package:flutter/material.dart';

class YTexttheme {
  YTexttheme._();

static lightTextTheme(){
  return TextTheme(
    headlineLarge: const TextStyle().copyWith(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color: const Color.fromARGB(255, 35, 35, 33),
    ),
    headlineMedium: const TextStyle().copyWith(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: const Color.fromARGB(255, 35, 35, 33),
    ),
    titleLarge: const TextStyle().copyWith(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: const Color.fromARGB(255, 35, 35, 33),
    ),
    titleMedium: const TextStyle().copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: const Color.fromARGB(255, 35, 35, 33),
    ),
    bodyMedium: const TextStyle().copyWith(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: const Color.fromARGB(255, 35, 35, 33),
    ),
    labelMedium: const TextStyle().copyWith(
      fontSize: 18,
      fontWeight: FontWeight.normal,
      color: const Color.fromARGB(255, 35, 35, 33),
    )
  );
 }
 static darkTextTheme(){
   return TextTheme(
    headlineLarge: const TextStyle().copyWith(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      color:  const Color.fromARGB(255, 239, 241, 229),
    ),
    headlineMedium: const TextStyle().copyWith(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color:  const Color.fromARGB(255, 239, 241, 229),
    ),
    titleLarge: const TextStyle().copyWith(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color:  const Color.fromARGB(255, 239, 241, 229),
    ),
    titleMedium: const TextStyle().copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color:  const Color.fromARGB(255, 239, 241, 229),
    ),
    bodyMedium: const TextStyle().copyWith(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color:  const Color.fromARGB(255, 239, 241, 229),
    ),
    labelMedium: const TextStyle().copyWith(
      fontSize: 18,
      fontWeight: FontWeight.normal,
      color:  const Color.fromARGB(255, 239, 241, 229),
    )
  );
 }





}