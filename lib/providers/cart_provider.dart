import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Modèle interne pour le panier
class CartItemData {
  final String id;
  final String title;
  final String imageUrl;
  final double price;
  final int quantity;

  CartItemData({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'imageUrl': imageUrl,
        'price': price,
        'quantity': quantity,
      };

  factory CartItemData.fromJson(Map<String, dynamic> json) => CartItemData(
        id: json['id'],
        title: json['title'] ?? '',
        imageUrl: json['imageUrl'] ?? '',
        price: (json['price'] as num).toDouble(),
        quantity: json['quantity'],
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

  // --- SAUVEGARDE ---
  Future<void> _saveCartData() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> tempMap = {};
    _items.forEach((key, value) {
      tempMap[key] = value.toJson();
    });
    String cartJson = json.encode(tempMap);
    await prefs.setString('user_cart', cartJson);
  }

  // --- CHARGEMENT ---
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

  // --- MÉTHODES DE GESTION CORRIGÉES ---

  void addItem(String productId, double price, String title, String imageUrl) {
    if (_items.containsKey(productId)) {
      _items.update(
          productId,
          (existing) => CartItemData(
                id: existing.id,
                title: existing.title,
                imageUrl: existing.imageUrl,
                price: existing.price,
                quantity: existing.quantity + 1,
              ));
    } else {
      _items[productId] = CartItemData(
        id: productId,
        title: title,
        imageUrl: imageUrl,
        price: price,
        quantity: 1,
      );
    }
    _saveCartData();
    notifyListeners();
  }

  void incrementQuantity(String productId) {
    if (_items.containsKey(productId)) {
      final item = _items[productId]!;
      addItem(productId, item.price, item.title, item.imageUrl);
    }
  }

  void decrementQuantity(String productId) {
    if (!_items.containsKey(productId)) return;
    if (_items[productId]!.quantity > 1) {
      _items.update(
          productId,
          (existing) => CartItemData(
                id: existing.id,
                title: existing.title,
                imageUrl: existing.imageUrl,
                price: existing.price,
                quantity: existing.quantity - 1,
              ));
    } else {
      _items.remove(productId);
    }
    _saveCartData();
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    _saveCartData();
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _saveCartData();
    notifyListeners();
  }
}