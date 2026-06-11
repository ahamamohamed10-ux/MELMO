import 'package:flutter/material.dart';

class NavigationProvider with ChangeNotifier {
  int _selectedIndex = 0; // Onglet Accueil par défaut
  String? _pendingProductMessage;

  int get selectedIndex => _selectedIndex;
  String? get pendingProductMessage => _pendingProductMessage;

  // --- Aliases to fix home_screen.dart errors ---
  int get currentTab => _selectedIndex; // Maps currentTab to selectedIndex
  String? get initialMessage => _pendingProductMessage; // Maps initialMessage to pendingProductMessage

  // Change l'onglet actif et permet de passer un message en option
  void changeTab(int index, {String? initialMessage}) {
    _selectedIndex = index;
    _pendingProductMessage = initialMessage;
    notifyListeners();
  }

  // Permet d'effacer le message une fois qu'il a été lu par l'écran de chat
  void clearPendingMessage() {
    _pendingProductMessage = null;
    notifyListeners(); // Added notifyListeners so the UI knows it changed
  }

  // Alias to fix the home_screen.dart error
  void clearInitialMessage() {
    clearPendingMessage();
  }
}