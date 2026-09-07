import 'package:flutter/material.dart';

const spikeRed=Color(0xFFAD0009);
const spikeBg=Color(0xFFF4F4F4);
const spikePanel=Color(0xFFE9E9E9);
const spikeField=Color(0xFFE7E7E7);
const spikeMuted=Color(0xFFBBBBBB);
const spikeDarkBg=Color(0xFF111111);
const spikeDarkPanel=Color(0xFF1D1D1D);

TextTheme _textTheme(Brightness b)=>TextTheme(
  titleLarge:TextStyle(fontSize:21,fontWeight:FontWeight.w700,height:1.2,color:b==Brightness.dark?Colors.white:null),
  titleMedium:TextStyle(fontSize:14,fontWeight:FontWeight.w700,color:b==Brightness.dark?Colors.white:null),
  bodyMedium:TextStyle(fontSize:12,fontWeight:FontWeight.w500,height:1.45,color:b==Brightness.dark?Colors.white:null),
  bodySmall:TextStyle(fontSize:10,fontWeight:FontWeight.w500,color:b==Brightness.dark?Colors.white70:null),
);

ThemeData _theme(Brightness brightness)=>ThemeData(
  useMaterial3:true,
  brightness:brightness,
  scaffoldBackgroundColor:brightness==Brightness.dark?spikeDarkBg:spikeBg,
  colorScheme:ColorScheme.fromSeed(seedColor:spikeRed,brightness:brightness),
  fontFamily:'GraphikArabic',
  fontFamilyFallback:const ['Tahoma','Arial'],
  splashFactory:InkRipple.splashFactory,
  textTheme:_textTheme(brightness),
  appBarTheme:AppBarTheme(backgroundColor:Colors.transparent,foregroundColor:brightness==Brightness.dark?Colors.white:Colors.black),
  navigationBarTheme:NavigationBarThemeData(height:76,backgroundColor:brightness==Brightness.dark?spikeDarkPanel:Colors.white,indicatorColor:Colors.transparent,labelBehavior:NavigationDestinationLabelBehavior.alwaysHide),
  snackBarTheme:SnackBarThemeData(backgroundColor:brightness==Brightness.dark?Colors.white:Colors.black,contentTextStyle:TextStyle(color:brightness==Brightness.dark?Colors.black:Colors.white),behavior:SnackBarBehavior.floating,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18))),
);

final spikeTheme=_theme(Brightness.light);
final spikeDarkTheme=_theme(Brightness.dark);
