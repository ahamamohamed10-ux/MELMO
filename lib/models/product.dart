import 'package:flutter/material.dart';

/// Fonction utilitaire pour convertir une chaîne Hexadécimale (ex: "#D4AF37") en objet Color Flutter
Color hexToColor(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final List<String> images;
  final String category; 
  final List<String> colors; // Liste des codes couleurs Hexadécimaux disponibles
  final List<String> sizes; // Tailles disponibles pour le produit

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.images,
    required this.category,
    this.colors = const [], 
    this.sizes = const [], // Par défaut, pas de taille imposée
  });
}

final List<Product> demoProducts = [
  Product(
    id: '1',
    title: 'Bandana',
    description: 'Enroulé autour du poignet, attaché à l\'anse d\'un sac à main, ou glissé dans une poche arrière.',
    price: 45.99,
    images: [
      'assets/images/bandana_hack.jpg',
      'assets/images/bandana1.jpg', 
      'assets/images/bandana2.jpg',
    ],
    category: 'Accessoires',
    colors: ['#000000', '#FF0000', '#0000FF', '#FFFFFF'], // Noir, Rouge, Bleu, Blanc
  ),
  Product(
    id: '2',
    title: 'collier de perles',
    description: 'Collier de perles naturelles, symbole de grâce et d\'élégance.',
    price: 120.00,
    images: [
      'assets/images/colier2.jpg',
      'assets/images/colier1.jpg',
      'assets/images/colier_perl.jpg',
      'https://i.ibb.co/d4F49WZ5/Shell-necklace.jpg',
    ],
    category: 'Bijoux',
    colors: ['#FFFDD0', '#D4AF37', '#E6E6FA'], // Crème, Doré, Lavande
  ),
  Product(
    id: '3',
    title: 'spray bottle',
    description: 'Spray pour les cheveux, hydrate et nourrit.',
    price: 89.50,
    images: ['assets/images/spray_bottle.jpg'],
    category: 'Soin',
    colors: [], // Pas de couleur pour cet article
  ),
  Product(
    id: 'p1',
    title: 'CAP_soie',
    description: 'Magnifique cap en soie avec broderies dorées.',
    price: 85.0,
    images: ['assets/images/cap_fachion.jpg'],
    category: 'Vêtements',
    colors: ['#D4AF37', '#000000', '#800020'], // Doré, Noir, Bourgogne
  ),
  Product(
    id: 'p2',
    title: 'sacoche_men',
    description: 'sacoche artisanale faite main.',
    price: 45.0,
    images: ['assets/images/sacoche_men.jpg'],
    category: 'Accessoires',
    colors: ['#8B4513', '#000000', '#A0522D'], // Marron, Noir, Cuir sienne
  ),
  Product(
    id: 'p3',
    title: 'lunette_de_soleil',
    description: 'Confortable et élégante pour toutes les occasions.',
    price: 30.0,
    images: ['assets/images/lunette_soille.jpg'],
    category: 'Accessoires',
    colors: ['#000000', '#D4AF37', '#8B4513'], // Noir, Doré, Écaille
  ),
  Product(
    id: 'p4',
    title: 'men_boots',
    description: 'Bottes robustes et élégantes.',
    price: 30.0,
    images: ['assets/images/men_boots.jpg'],
    category: 'Chaussures',
    colors: ['#000000', '#8B4513'], // Noir, Brun
  ),
  Product(
    id: 'p5',
    title: 'spray_plastic_bottle',
    description: 'Bouteille spray en plastique recyclable.',
    price: 30.0,
    images: [
      'https://i.ibb.co/mFJzNMk6/1-Pcs-500-ml-17-oz-Empty-Plastic-Spray-Bottles-Refillable-Adjustable-Mist-Sprayer-Bottles-for.jpg',
    ],
    category: 'Soin',
    colors: [],
  ),
];
