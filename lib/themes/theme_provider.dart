// ignore_for_file: unnecessary_import

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:talktime2/themes/darkmode.dart';
import 'package:talktime2/themes/lightmode.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData = lightMode;

  ThemeData get themeData => _themeData;

  bool get isDarkMode => _themeData == darkMode;

  set themeData(ThemeData themeData){
    _themeData = themeData;
    notifyListeners();
  }

  void toggleTheme(){
    if (_themeData == lightMode) {
      themeData = darkMode;
    }else {
      themeData = lightMode;
    }
  }
}
