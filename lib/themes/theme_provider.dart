import 'package:flutter/material.dart';
import 'package:music_app/themes/dark_mode.dart';
import 'package:music_app/themes/light_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier{
  //initially light mode
  ThemeData _themeData = lightMode;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;


  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  //get theme
  ThemeData get themeData => _themeData;

  //is dark mode
  bool get isDarkMode => _themeData == darkMode;

  //set theme
  set themeData(ThemeData themeData){
    _themeData = themeData;
    _saveThemeToPrefs(); // Save change

    //updata UI
    notifyListeners();
  }

    //toggle theme
    void toggleTheme(){
      if(_themeData == lightMode){
        themeData = darkMode;
      }
      else{
        themeData = lightMode; 
      }
    }

    // Save theme preference
  Future<void> _saveThemeToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  // Load theme preference
  Future<void> _loadThemeFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? false;
  _themeData = isDark ? darkMode : lightMode;
  _isInitialized = true;
  notifyListeners();
}

  }
