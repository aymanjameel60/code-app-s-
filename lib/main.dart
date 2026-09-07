import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/router.dart';
import 'core/settings/app_settings.dart';
import 'core/theme.dart';

void main(){WidgetsFlutterBinding.ensureInitialized();runApp(const ProviderScope(child:SpikeApp()));}

class SpikeApp extends ConsumerWidget{
  const SpikeApp({super.key});
  @override Widget build(BuildContext context,WidgetRef ref){final settings=ref.watch(appSettingsProvider);final rtl=settings.language=='ar';return MaterialApp.router(
    debugShowCheckedModeBanner:false,
    title:'Spike',
    theme:spikeTheme,
    darkTheme:spikeDarkTheme,
    themeMode:settings.themeMode,
    locale:Locale(settings.language),
    supportedLocales:const [Locale('ar'),Locale('en')],
    localizationsDelegates:const [GlobalMaterialLocalizations.delegate,GlobalWidgetsLocalizations.delegate,GlobalCupertinoLocalizations.delegate],
    routerConfig:appRouter,
    builder:(context,child)=>Directionality(textDirection:rtl?TextDirection.rtl:TextDirection.ltr,child:child??const SizedBox.shrink()),
  );}
}
