import 'package:flutter/material.dart';

const spikeRed=Color(0xFFAD0009);
const spikeBg=Color(0xFFF4F4F4);
const spikePanel=Color(0xFFE9E9E9);
const spikeField=Color(0xFFE7E7E7);
const spikeMuted=Color(0xFFBBBBBB);
const spikeDarkBg=Color(0xFF111111);
const spikeDarkPanel=Color(0xFF1D1D1D);

/// Shared spacing scale used across Spike screens.
/// Keep page gutters, cards, sections and controls aligned to this scale.
abstract final class SpikeSpacing {
  static const double xs=4;
  static const double sm=8;
  static const double md=12;
  static const double lg=16;
  static const double page=17;
  static const double xl=24;
  static const double xxl=32;

  static const EdgeInsets pageHorizontal=EdgeInsets.symmetric(horizontal:page);
  static const EdgeInsets pageList=EdgeInsets.fromLTRB(page,sm,page,xl);
  static const EdgeInsets card=EdgeInsets.all(14);
  static const EdgeInsets sheet=EdgeInsets.fromLTRB(page,md,page,xl);
}

abstract final class SpikeRadius {
  static const double control=16;
  static const double card=20;
  static const double sheet=24;
}

TextTheme _textTheme(Brightness b)=>TextTheme(
  titleLarge:TextStyle(fontSize:21,fontWeight:FontWeight.w700,height:1.2,color:b==Brightness.dark?Colors.white:null),
  titleMedium:TextStyle(fontSize:14,fontWeight:FontWeight.w700,color:b==Brightness.dark?Colors.white:null),
  bodyMedium:TextStyle(fontSize:12,fontWeight:FontWeight.w500,height:1.45,color:b==Brightness.dark?Colors.white:null),
  bodySmall:TextStyle(fontSize:10,fontWeight:FontWeight.w500,color:b==Brightness.dark?Colors.white70:null),
);

ThemeData _theme(Brightness brightness){
  final dark=brightness==Brightness.dark;
  final surface=dark?spikeDarkPanel:Colors.white;
  final field=dark?spikeDarkPanel:spikeField;
  final onSurface=dark?Colors.white:Colors.black;
  return ThemeData(
    useMaterial3:true,
    brightness:brightness,
    scaffoldBackgroundColor:dark?spikeDarkBg:spikeBg,
    colorScheme:ColorScheme.fromSeed(seedColor:spikeRed,brightness:brightness),
    fontFamily:'GraphikArabic',
    fontFamilyFallback:const ['Tahoma','Arial'],
    splashFactory:InkRipple.splashFactory,
    textTheme:_textTheme(brightness),
    iconTheme:IconThemeData(color:onSurface),
    appBarTheme:AppBarTheme(backgroundColor:Colors.transparent,foregroundColor:onSurface,elevation:0,scrolledUnderElevation:0),
    navigationBarTheme:NavigationBarThemeData(height:76,backgroundColor:surface,indicatorColor:Colors.transparent,labelBehavior:NavigationDestinationLabelBehavior.alwaysHide),
    bottomSheetTheme:BottomSheetThemeData(backgroundColor:dark?spikeDarkBg:spikeBg,modalBackgroundColor:dark?spikeDarkBg:spikeBg,shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(SpikeRadius.sheet)))),
    dividerTheme:DividerThemeData(color:onSurface.withValues(alpha:.10),space:1,thickness:1),
    listTileTheme:ListTileThemeData(iconColor:onSurface,textColor:onSurface,contentPadding:const EdgeInsets.symmetric(horizontal:SpikeSpacing.md,vertical:SpikeSpacing.xs)),
    inputDecorationTheme:InputDecorationTheme(
      filled:true,
      fillColor:field,
      contentPadding:const EdgeInsets.symmetric(horizontal:SpikeSpacing.lg,vertical:SpikeSpacing.md),
      hintStyle:const TextStyle(color:spikeMuted,fontSize:12),
      labelStyle:TextStyle(color:onSurface.withValues(alpha:.70),fontSize:12),
      enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(SpikeRadius.control),borderSide:BorderSide.none),
      focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(SpikeRadius.control),borderSide:const BorderSide(color:spikeRed,width:1.2)),
      errorBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(SpikeRadius.control),borderSide:const BorderSide(color:spikeRed)),
      focusedErrorBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(SpikeRadius.control),borderSide:const BorderSide(color:spikeRed,width:1.2)),
    ),
    filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(minimumSize:const Size(0,48),padding:const EdgeInsets.symmetric(horizontal:SpikeSpacing.lg,vertical:SpikeSpacing.md),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(SpikeRadius.control)))),
    outlinedButtonTheme:OutlinedButtonThemeData(style:OutlinedButton.styleFrom(minimumSize:const Size(0,46),padding:const EdgeInsets.symmetric(horizontal:SpikeSpacing.lg,vertical:SpikeSpacing.sm),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(SpikeRadius.control)))),
    snackBarTheme:SnackBarThemeData(backgroundColor:dark?Colors.white:Colors.black,contentTextStyle:TextStyle(color:dark?Colors.black:Colors.white),behavior:SnackBarBehavior.floating,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18))),
  );
}

final spikeTheme=_theme(Brightness.light);
final spikeDarkTheme=_theme(Brightness.dark);
