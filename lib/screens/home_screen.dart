import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shimmer/shimmer.dart';
import '../models/product.dart';
import 'cart_screen.dart';
import 'catalog_screen.dart';
import 'profile_screen.dart';
import 'product_detail_screen.dart';
import 'package:melmo/screens/add_product_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Liste des pages pour la navigation du bas
  final List<Widget> _pages = [
    const HomeBody(),
    const CatalogScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // ✅ LOGO MOMART INTÉGRÉ ICI
        title: Image.asset(
          'assets/images/logo.png',
          height: 45,
          fit: BoxFit.contain,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (ctx) => const CartScreen()),
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      // ✅ BOUTON AJOUTER PRODUIT (Visible uniquement pour ton email)
      floatingActionButton: FirebaseAuth.instance.currentUser?.email == "ahamamohamed10@gmail.com"
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFD4AF37), // Couleur Or
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const AddProductScreen()),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Catalogue'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}

class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  String _searchQuery = '';
  String _selectedCategory = 'Tout'; 
  final List<String> _categories = ['Tout', 'Boubous', 'Bijoux', 'Pantalons', 'Robes'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // BARRE DE RECHERCHE
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un article...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),

        // LISTE DES CATÉGORIES
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: _categories.length,
            itemBuilder: (ctx, i) {
              final cat = _categories[i];
              final isSelected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    cat, 
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 15),

        // GRILLE DES PRODUITS
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Aucun produit disponible"));
              }
              
              final filtered = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Product(
                  id: doc.id,
                  title: data['title'] ?? '',
                  description: data['description'] ?? '',
                  price: (data['price'] ?? 0).toDouble(),
                  images: List<String>.from(data['images'] ?? [data['imageUrl'] ?? '']),
                  category: data['category'] ?? 'Tout',
                );
              }).where((p) {
                final matchesSearch = p.title.toLowerCase().contains(_searchQuery.toLowerCase());
                final matchesCategory = _selectedCategory == 'Tout' || p.category == _selectedCategory;
                return matchesSearch && matchesCategory;
              }).toList();

              return GridView.builder(
                padding: const EdgeInsets.all(15),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, 
                  childAspectRatio: 0.72, 
                  crossAxisSpacing: 15, 
                  mainAxisSpacing: 15
                ),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) => _buildProductItem(filtered[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductItem(Product product) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (ctx) => ProductDetailScreen(product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, spreadRadius: 2)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec Shimmer
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.network(
                  product.images[0],
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(color: Colors.white),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[100],
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
              ),
            ),
            // Infos Produit
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
                      fontSize: 16
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
