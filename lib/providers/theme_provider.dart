import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  // Fonction pour changer le thème
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners(); // Prévient toute l'app du changement
  }
}