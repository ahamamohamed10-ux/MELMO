import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Fonction utilitaire sécurisée pour convertir une chaîne Hexadécimale en objet Color Flutter
Color hexToColor(String hexString) {
  try {
    String cleanHex = hexString.replaceAll('#', '').trim();
    if (cleanHex.length == 6) {
      cleanHex = 'FF$cleanHex';
    }
    if (cleanHex.length == 8) {
      return Color(int.parse(cleanHex, radix: 16));
    }
  } catch (e) {
    debugPrint('Erreur de conversion de couleur Hex "$hexString": $e');
  }
  return Colors.transparent; // Couleur de repli en cas d'erreur
}

class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final List<String> images;
  final String category;
  final String collection;
  final List<String> colors; // Codes hexadécimaux (ex: "#FF0000")
  final List<String> sizes;  // Tailles (ex: ['S', 'M', 'L'])
  final double shippingFee;
  final String estimatedDelivery;
  final String destinationName;
  final int returnPolicyDays;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.images,
    required this.category,
    required this.collection,
    this.colors = const [],
    this.sizes = const [],
    this.shippingFee = 0.0,
    this.estimatedDelivery = '2 - 4 jours',
    this.destinationName = 'AUX COMORES',
    this.returnPolicyDays = 14,
  });

  /// Extraction sécurisée d'une liste de chaînes depuis une donnée dynamique
  static List<String> _parseStringList(dynamic rawList) {
    if (rawList is List) {
      return rawList
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  /// Conversion sécurisée du prix en double
  static double _parsePrice(dynamic rawPrice) {
    if (rawPrice is num) {
      return rawPrice.toDouble();
    } else if (rawPrice is String) {
      return double.tryParse(rawPrice) ?? 0.0;
    }
    return 0.0;
  }

  /// Factory constructor pour instancier un Produit depuis Firestore
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Product(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      price: _parsePrice(data['price']),
      images: _parseStringList(data['images']),
      category: data['category']?.toString() ?? '',
      collection: data['collection']?.toString() ?? '',
      colors: _parseStringList(data['colors']),
      sizes: _parseStringList(data['sizes']),
      shippingFee: (data['shippingFee'] as num?)?.toDouble() ?? 0.0,
      estimatedDelivery: data['deliveryTime'] as String? ?? '2 - 4 jours',
      destinationName: data['destinationName'] as String? ?? 'AUX COMORES',
      returnPolicyDays: (data['returnPolicyDays'] as num?)?.toInt() ?? 14,
    );
  }

  /// Convertir l'objet Produit en Map pour la sauvegarde Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'images': images,
      'category': category,
      'collection': collection,
      'colors': colors,
      'sizes': sizes,
    };
  }
}