import 'package:flutter/material.dart';

const spikeRed = Color(0xFFAD0009);
const spikeBg = Color(0xFFF4F4F4);
const spikePanel = Color(0xFFE9E9E9);
const spikeField = Color(0xFFE7E7E7);
const spikeMuted = Color(0xFFBBBBBB);

final spikeTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: spikeBg,
  colorScheme: ColorScheme.fromSeed(seedColor: spikeRed, brightness: Brightness.light),
  fontFamily: 'Graphik Arabic',
  fontFamilyFallback: const ['Tahoma', 'Arial'],
  splashFactory: InkRipple.splashFactory,
  textTheme: const TextTheme(
    titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, height: 1.2),
    titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    bodyMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, height: 1.45),
    bodySmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    height: 76,
    backgroundColor: Colors.white,
    indicatorColor: Colors.transparent,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: Colors.black,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  ),
);
