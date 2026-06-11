import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String _searchQuery = '';

  // Liste de tes collections réelles avec leurs images correspondantes dans tes assets
  final List<Map<String, String>> _collections = [
    {
      'name': 'Women clothing',
      'image': 'assets/images/women.jpg',
    },
    {
      'name': 'Men clothing',
      'image': 'assets/images/shene.jpg',
    },
    {
      'name': 'Vêtements pour enfants',
      'image': 'assets/images/Babys.jpg',
    },
    {
      'name': 'Handbag',
      'image': 'assets/images/handbag.jpg',
    },
    {
      'name': 'Home accessories',
      'image': 'assets/images/ecouteur.jpg',
    },
    {
      'name': 'Phones & gadgets',
      'image': 'assets/images/phone.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Filtrage dynamique des collections selon la saisie dans la barre de recherche
    final filteredCollections = _collections
        .where((collection) => collection['name']!
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. BARRE DE RECHERCHE EN HAUT
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Rechercher une collection...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 5),
            child: Text(
              "Nos Collections",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Text(
              "Découvrez nos articles exclusifs par catégorie",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
          const SizedBox(height: 15),

          // 2. GRILLE DES COLLECTIONS FILTRÉES
          Expanded(
            child: filteredCollections.isEmpty
                ? const Center(
                    child: Text(
                      "Aucune collection ne correspond à votre recherche",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 colonnes
                      childAspectRatio: 0.85, // Ratio largeur/hauteur des cartes
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: filteredCollections.length,
                    itemBuilder: (ctx, i) {
                      final collection = filteredCollections[i];
                      return _buildCollectionCard(
                          collection['name']!, collection['image']!);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Widget pour chaque carte de collection
  Widget _buildCollectionCard(String name, String imagePath) {
    return GestureDetector(
      onTap: () {
        // Redirection vers l'écran de la collection filtrée
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => CollectionProductsScreen(categoryName: name),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              // Image de fond de la collection
              Image.asset(
                imagePath,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.category, color: Colors.grey, size: 40),
                ),
              ),
              // Dégradé sombre pour rendre le texte bien lisible
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              // Nom de la collection centré en bas
              Positioned(
                bottom: 15,
                left: 15,
                right: 15,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        "VOIR TOUT",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================================
// ÉCRAN SECONDAIRE CORRIGÉ : Récupère et transmet désormais le champ colors
// =========================================================================
class CollectionProductsScreen extends StatelessWidget {
  final String categoryName;

  const CollectionProductsScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          categoryName,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Une erreur est survenue"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aucun produit disponible"));
          }

          // Filtrage des produits selon la catégorie cliquée
          final filteredProducts = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            var imgs = data['images'];
            List<String> imagesList = imgs is List ? List<String>.from(imgs) : [data['imageUrl'] ?? ''];

            return Product(
              id: doc.id,
              title: data['title'] ?? '',
              description: data['description'] ?? '',
              price: (data['price'] ?? 0).toDouble(),
              images: imagesList,
              category: data['category'] ?? 'Tout',
              
              // =========================================================================
              // EXTRACTION DU TABLEAU DE COULEURS DEPUIS FIRESTORE
              // =========================================================================
              colors: data['colors'] != null ? List<String>.from(data['colors']) : [],
            );
          }).where((p) => p.category.toLowerCase() == categoryName.toLowerCase()).toList();

          if (filteredProducts.isEmpty) {
            return Center(
              child: Text(
                "Aucun produit dans la collection $categoryName",
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          // Grille des produits de la collection
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (ctx, i) {
              final product = filteredProducts[i];
              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => ProductDetailScreen(product: product)),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                          child: Image.network(
                            product.images.isNotEmpty ? product.images[0] : '',
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: Colors.grey[100],
                              child: const Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${product.price.toStringAsFixed(0)} €',
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}