import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  const AppSettings({this.themeMode=ThemeMode.light,this.language='ar',this.currency='USD'});
  final ThemeMode themeMode;
  final String language;
  final String currency;
  AppSettings copyWith({ThemeMode? themeMode,String? language,String? currency})=>AppSettings(themeMode:themeMode??this.themeMode,language:language??this.language,currency:currency??this.currency);
}

class AppSettingsController extends StateNotifier<AppSettings>{
  AppSettingsController():super(const AppSettings()){_load();}
  static const _theme='spike_theme',_language='spike_language',_currency='spike_currency';
  Future<void> _load()async{final p=await SharedPreferences.getInstance();state=AppSettings(themeMode:p.getString(_theme)=='dark'?ThemeMode.dark:ThemeMode.light,language:p.getString(_language)??'ar',currency:(p.getString(_currency)??'USD').toUpperCase());}
  Future<void> setTheme(ThemeMode value)async{state=state.copyWith(themeMode:value);final p=await SharedPreferences.getInstance();await p.setString(_theme,value==ThemeMode.dark?'dark':'light');}
  Future<void> setLanguage(String value)async{if(!['ar','en'].contains(value))return;state=state.copyWith(language:value);final p=await SharedPreferences.getInstance();await p.setString(_language,value);}
  Future<void> setCurrency(String value)async{final code=value.toUpperCase();state=state.copyWith(currency:code);final p=await SharedPreferences.getInstance();await p.setString(_currency,code);}
}

final appSettingsProvider=StateNotifierProvider<AppSettingsController,AppSettings>((ref)=>AppSettingsController());
