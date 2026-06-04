import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeNotifier = ValueNotifier<Locale>(const Locale('en'));

Future<void> loadSavedLocale() async {
  final prefs = await SharedPreferences.getInstance();
  final code = prefs.getString('locale_code') ?? 'en';
  localeNotifier.value = Locale(code);
}

Future<void> saveLocale(String languageCode) async {
  localeNotifier.value = Locale(languageCode);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('locale_code', languageCode);
}
