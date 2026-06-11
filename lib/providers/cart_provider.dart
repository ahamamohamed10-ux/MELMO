import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Modèle interne pour le panier mis à jour avec les couleurs
class CartItemData {
  final String id; // ID unique de la ligne (productId_selectedColor)
  final String title;
  final String imageUrl;
  final double price;
  final int quantity;
  final String selectedColor; // <-- AJOUTÉ : Sauvegarde de la couleur hexadécimale

  CartItemData({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.selectedColor, // <-- Requis
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'imageUrl': imageUrl,
        'price': price,
        'quantity': quantity,
        'selectedColor': selectedColor, // <-- Sauvegarde dans SharedPreferences
      };

  factory CartItemData.fromJson(Map<String, dynamic> json) => CartItemData(
        id: json['id'],
        title: json['title'] ?? '',
        imageUrl: json['imageUrl'] ?? '',
        price: (json['price'] as num).toDouble(),
        quantity: json['quantity'],
        selectedColor: json['selectedColor'] ?? 'Standard', // Valeur par défaut si absent
      );
}

class CartProvider with ChangeNotifier {
  Map<String, CartItemData> _items = {};

  Map<String, CartItemData> get items => _items;

  CartProvider() {
    _loadCartData();
  }

  double get totalAmount {
    double total = 0.0;
    _items.forEach((id, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  int get itemCount => _items.length;

  // --- SAUVEGARDE EN LOCAL ---
  Future<void> _saveCartData() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> tempMap = {};
    _items.forEach((key, value) {
      tempMap[key] = value.toJson();
    });
    String cartJson = json.encode(tempMap);
    await prefs.setString('user_cart', cartJson);
  }

  // --- CHARGEMENT DE LA MÉMOIRE LOCALE ---
  Future<void> _loadCartData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('user_cart')) return;

    final savedCart = prefs.getString('user_cart');
    if (savedCart != null) {
      Map<String, dynamic> decoded = json.decode(savedCart);
      _items = decoded.map(
          (key, value) => MapEntry(key, CartItemData.fromJson(value)));
      notifyListeners();
    }
  }

  // --- AJOUT D'UN ARTICLE MODIFIÉ AVEC LA COULEUR ---
  void addItem(String productId, double price, String title, String imageUrl, String colorHex) {
    // Génération d'une clé unique combinant l'article et sa variante couleur
    final String cartItemId = "${productId}_$colorHex";

    if (_items.containsKey(cartItemId)) {
      // Si la même variante de couleur existe, on incrémente
      _items.update(
          cartItemId,
          (existing) => CartItemData(
                id: existing.id,
                title: existing.title,
                imageUrl: existing.imageUrl,
                price: existing.price,
                quantity: existing.quantity + 1,
                selectedColor: existing.selectedColor,
              ));
    } else {
      // Sinon, on crée une nouvelle ligne distincte pour cette couleur
      _items[cartItemId] = CartItemData(
        id: cartItemId,
        title: title,
        imageUrl: imageUrl,
        price: price,
        quantity: 1,
        selectedColor: colorHex,
      );
    }
    _saveCartData();
    notifyListeners();
  }

  // --- INCREMENTATION VIA L'ID DE LIGNE UNIQUE ---
  void incrementQuantity(String cartItemId) {
    if (_items.containsKey(cartItemId)) {
      final item = _items[cartItemId]!;
      // Extraction de l'ID produit d'origine (ce qui se trouve avant le '_')
      final productId = cartItemId.split('_')[0];
      
      addItem(productId, item.price, item.title, item.imageUrl, item.selectedColor);
    }
  }

  // --- DECREMENTATION ---
  void decrementQuantity(String cartItemId) {
    if (!_items.containsKey(cartItemId)) return;
    
    if (_items[cartItemId]!.quantity > 1) {
      _items.update(
          cartItemId,
          (existing) => CartItemData(
                id: existing.id,
                title: existing.title,
                imageUrl: existing.imageUrl,
                price: existing.price,
                quantity: existing.quantity - 1,
                selectedColor: existing.selectedColor,
              ));
    } else {
      _items.remove(cartItemId);
    }
    _saveCartData();
    notifyListeners();
  }

  // --- SUPPRESSION ---
  void removeItem(String cartItemId) {
    _items.remove(cartItemId);
    _saveCartData();
    notifyListeners();
  }

  // --- VIDER LE PANIER ---
  void clear() {
    _items.clear();
    _saveCartData();
    notifyListeners();
  }
}