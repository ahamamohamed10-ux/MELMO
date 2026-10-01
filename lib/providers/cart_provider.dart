import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modèle représentant un article du panier avec gestion des variantes (couleurs)
class CartItemData {
  final String id; // ID unique de la ligne (ex: productId_selectedColor)
  final String title;
  final String imageUrl;
  final double price;
  final int quantity;
  final String selectedColor; // Code hexadécimal ou nom de la couleur

  CartItemData({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.selectedColor,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'imageUrl': imageUrl,
        'price': price,
        'quantity': quantity,
        'selectedColor': selectedColor,
      };

  factory CartItemData.fromJson(Map<String, dynamic> json) => CartItemData(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        imageUrl: json['imageUrl'] ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        quantity: json['quantity'] ?? 1,
        selectedColor: json['selectedColor'] ?? 'Standard',
      );
}

class CartProvider with ChangeNotifier {
  Map<String, CartItemData> _items = {};

  Map<String, CartItemData> get items => _items;

  CartProvider() {
    _loadCartData();
  }

  /// Calcul du montant total du panier
  double get totalAmount {
    double total = 0.0;
    _items.forEach((id, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  /// Nombre de lignes différentes dans le panier
  int get itemCount => _items.length;

  /// Nombre total d'unités d'articles (somme des quantités)
  int get totalItemCount {
    int count = 0;
    _items.forEach((key, item) {
      count += item.quantity;
    });
    return count;
  }

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
      try {
        Map<String, dynamic> decoded = json.decode(savedCart);
        _items = decoded.map(
          (key, value) => MapEntry(key, CartItemData.fromJson(value)),
        );
        notifyListeners();
      } catch (e) {
        debugPrint('Erreur lors du chargement du panier local : $e');
      }
    }
  }

  // --- AJOUT D'UN ARTICLE AVEC COULEUR ---
  void addItem(String productId, double price, String title, String imageUrl, String colorHex) {
    final String cartItemId = "${productId}_$colorHex";

    if (_items.containsKey(cartItemId)) {
      _items.update(
        cartItemId,
        (existing) => CartItemData(
          id: existing.id,
          title: existing.title,
          imageUrl: existing.imageUrl,
          price: existing.price,
          quantity: existing.quantity + 1,
          selectedColor: existing.selectedColor,
        ),
      );
    } else {
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

  // --- INCRÉMENTATION DE LA QUANTITÉ ---
  void incrementQuantity(String cartItemId) {
    if (_items.containsKey(cartItemId)) {
      final item = _items[cartItemId]!;
      final productId = cartItemId.split('_')[0];
      addItem(productId, item.price, item.title, item.imageUrl, item.selectedColor);
    }
  }

  // --- DÉCRÉMENTATION DE LA QUANTITÉ ---
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
        ),
      );
    } else {
      _items.remove(cartItemId);
    }
    _saveCartData();
    notifyListeners();
  }

  // --- SUPPRESSION D'UNE LIGNE DU PANIER ---
  void removeItem(String cartItemId) {
    _items.remove(cartItemId);
    _saveCartData();
    notifyListeners();
  }

  // --- VIDER LE PANIER ---
  Future<void> clear() async {
    _items.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_cart');
    notifyListeners();
  }
}