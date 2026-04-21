class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final List<String> images;
  final String category; // L'étiquette pour organiser tes articles

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.images,
    required this.category, // Ajouté ici
  });
}

final List<Product> demoProducts = [
  Product(
    id: '1',
    title: 'BANDANA hack',
    description: 'Enroulé autour du poignet, attaché à l\'anse d\'un sac à main, ou glissé dans une poche arrière.',
    price: 45.99,
    images: [
      'assets/images/bandana_hack.jpg',
      'assets/images/bandana1.jpg', 
      'assets/images/bandana2.jpg',
    ],
    category: 'Accessoires',
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
  ),
  Product(
    id: '3',
    title: 'spray bottle',
    description: 'Spray pour les cheveux, hydrate et nourrit.',
    price: 89.50,
    images: ['assets/images/spray_bottle.jpg'],
    category: 'Soin',
  ),
  Product(
    id: 'p1',
    title: 'CAP_soie',
    description: 'Magnifique cap en soie avec broderies dorées.',
    price: 85.0,
    images: ['assets/images/cap_fachion.jpg'],
    category: 'Vêtements',
  ),
  Product(
    id: 'p2',
    title: 'sacoche_men',
    description: 'sacoche artisanale faite main.',
    price: 45.0,
    images: ['assets/images/sacoche_men.jpg'],
    category: 'Accessoires',
  ),
  Product(
    id: 'p3',
    title: 'lunette_de_soleil',
    description: 'Confortable et élégante pour toutes les occasions.',
    price: 30.0,
    images: ['assets/images/lunette_soille.jpg'],
    category: 'Accessoires',
  ),
  Product(
    id: 'p4',
    title: 'men_boots',
    description: 'Bottes robustes et élégantes.',
    price: 30.0,
    images: ['assets/images/men_boots.jpg'],
    category: 'Chaussures',
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
  ),
];
