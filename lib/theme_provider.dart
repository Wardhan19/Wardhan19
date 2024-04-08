import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isNightMode = true;

  bool get isNightMode => _isNightMode;

  ThemeProvider() {
    _loadNightMode();
  }

  _loadNightMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isNightMode = (prefs.getBool('nightMode') ?? false);
    notifyListeners();
  }

  toggleNightMode() async {
    _isNightMode = !_isNightMode;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('nightMode', _isNightMode);
    notifyListeners();
  }
}