import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart';
import 'add_product_screen.dart';
import 'cart_screen.dart';
import 'catalog_screen.dart';
import 'messages_screen.dart';
import 'product_detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Tout';
  String _selectedCollection = 'Tout';

  static const List<String> _categoriesList = [
    'Tout',
    'Téléphones',
    'Écouteurs',
    'Bijoux',
    'Sacs',
    'Montres',
    'Femmes accessoires',
    'Robes',
  ];

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    final bool isCatalogTab = navProvider.currentTab == 1;

    final List<Widget> pages = [
      HomeBody(
        searchQuery: _searchQuery,
        selectedCategory: _selectedCategory,
        selectedCollection: _selectedCollection,
        onResetCollection: () => setState(() => _selectedCollection = 'Tout'),
        onCategoryChanged: (category) {
          setState(() {
            _selectedCategory = category;
            _selectedCollection = 'Tout';
          });
        },
        onCollectionSelected: (collection) {
          setState(() {
            _selectedCollection = collection;
            _selectedCategory = 'Tout';
          });
        },
      ),
      const CatalogScreen(),
      const MessagesScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: isCatalogTab
            ? const SizedBox.shrink()
            : _SearchTextField(
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
        bottom: isCatalogTab
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: _CategoryFilterBar(
                  categories: _categoriesList,
                  selectedCategory: _selectedCategory,
                  selectedCollection: _selectedCollection,
                  onSelected: (cat) {
                    setState(() {
                      _selectedCategory = cat;
                      _selectedCollection = 'Tout';
                    });
                  },
                ),
              ),
        actions: const [_CartIconButton()],
      ),
      body: pages[navProvider.currentTab],
      floatingActionButton: FirebaseAuth.instance.currentUser?.email == "ahamamohamed10@gmail.com"
          ? FloatingActionButton(
              backgroundColor: const Color(0xFFD4AF37),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (ctx) => const AddProductScreen()),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navProvider.currentTab,
        onTap: (index) => navProvider.changeTab(index),
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Accueil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            label: 'Catalogue',
          ),
          BottomNavigationBarItem(
            icon: _UnreadMessagesBadge(currentUserId: currentUserId),
            label: 'Messages',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// --- BODY & PRODUCT GRID ---

class HomeBody extends StatelessWidget {
  final String searchQuery;
  final String selectedCategory;
  final String selectedCollection;
  final Function(String) onCategoryChanged;
  final Function(String) onCollectionSelected;
  final VoidCallback onResetCollection;

  const HomeBody({
    super.key,
    required this.searchQuery,
    required this.selectedCategory,
    required this.selectedCollection,
    required this.onCategoryChanged,
    required this.onCollectionSelected,
    required this.onResetCollection,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedCollection != 'Tout')
            _ActiveCollectionHeader(
              collection: selectedCollection,
              onReset: onResetCollection,
            ),
          _CollectionBanners(
            onCollectionSelected: onCollectionSelected,
            onCategoryChanged: onCategoryChanged,
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      "Erreur Firebase : ${snapshot.error}",
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30.0),
                    child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text("Aucun produit trouvé"),
                  ),
                );
              }

              final products = snapshot.data!.docs
                  .map((doc) => Product.fromFirestore(doc))
                  .toList();
              final filtered = products.filter(
                query: searchQuery,
                category: selectedCategory,
                collection: selectedCollection,
              );

              if (filtered.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text("Aucun produit ne correspond"),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(15),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) => _ProductTile(product: filtered[i]),
              );
            },
          ),
        ],
      ),
    );
  }
}

// --- EXTENSIONS & MODULAR COMPONENTS ---

extension ProductQueryExtension on List<Product> {
  List<Product> filter({
    required String query,
    required String category,
    required String collection,
  }) {
    final lowerQuery = query.toLowerCase();
    return where((p) {
      final matchesSearch = p.title.toLowerCase().contains(lowerQuery);
      final matchesCategory = category == 'Tout' || p.category == category;
      final matchesCollection = collection == 'Tout' || p.collection == collection;
      return matchesSearch && matchesCategory && matchesCollection;
    }).toList();
  }
}

extension ProductFirestore on Product {
  static Product fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    var imgs = data['images'];
    List<String> imagesList = imgs is List
        ? List<String>.from(imgs)
        : [(data['imageUrl'] ?? '')];

    return Product(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      images: imagesList,
      category: data['category'] ?? 'Tout',
      collection: data['collection'] ?? 'Tout',
      colors: data['colors'] != null ? List<String>.from(data['colors']) : [],
      sizes: data['sizes'] != null ? List<String>.from(data['sizes']) : [],
    );
  }
}

class _SearchTextField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchTextField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher un article...',
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey[500]),
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 22),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final String selectedCollection;
  final ValueChanged<String> onSelected;

  const _CategoryFilterBar({
    required this.categories,
    required this.selectedCategory,
    required this.selectedCollection,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 15),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((cat) {
            final isSelected = selectedCategory == cat && selectedCollection == 'Tout';
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                selectedColor: const Color(0xFFD4AF37),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  if (selected) onSelected(cat);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CartIconButton extends StatelessWidget {
  const _CartIconButton();

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Colors.black,
                  size: 26,
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (ctx) => const CartScreen()),
                ),
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '${cart.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _UnreadMessagesBadge extends StatelessWidget {
  final String currentUserId;

  const _UnreadMessagesBadge({required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(currentUserId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('senderId', isNotEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        return Badge(
          isLabelVisible: unreadCount > 0,
          label: Text(
            '$unreadCount',
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.red,
          child: const Icon(Icons.chat_bubble_outline),
        );
      },
    );
  }
}

class _ActiveCollectionHeader extends StatelessWidget {
  final String collection;
  final VoidCallback onReset;

  const _ActiveCollectionHeader({required this.collection, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Collection : $collection",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFD4AF37)),
          ),
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.close, size: 16, color: Colors.grey),
            label: const Text("Effacer", style: TextStyle(color: Colors.grey, fontSize: 12)),
          )
        ],
      ),
    );
  }
}

class _CollectionBanners extends StatelessWidget {
  final ValueChanged<String> onCollectionSelected;
  final ValueChanged<String> onCategoryChanged;

  const _CollectionBanners({
    required this.onCollectionSelected,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: AspectRatio(
        aspectRatio: 16 / 8,
        child: Row(
          children: [
            Expanded(
              child: _CategoryCard(
                title: "Gadgets\nÉlectroniques",
                imageUrl: 'assets/images/gadgets.jpg',
                onTap: () => onCollectionSelected('Gadgets Électroniques'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _CategoryCard(
                      title: "Sacs à main",
                      imageUrl: 'assets/images/handbag.jpg',
                      onTap: () => onCategoryChanged('Sacs'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _CategoryCard(
                      title: "Montres",
                      imageUrl: 'assets/images/watch.jpg',
                      onTap: () => onCategoryChanged('Montres'),
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

class _CategoryCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 10,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;

  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context) {
    final String mainImage = product.images.isNotEmpty ? product.images[0] : '';

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
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: Image.network(
                      mainImage,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        color: Colors.grey[100],
                        child: const Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        "NEW",
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category.toUpperCase(),
                    style: TextStyle(color: Colors.grey[500], fontSize: 10, letterSpacing: 1),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${product.price.toStringAsFixed(0)} €',
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart, size: 20, color: Colors.black54),
                        onPressed: () {
                          Provider.of<CartProvider>(context, listen: false).addItem(
                            product.id,
                            product.price,
                            product.title,
                            mainImage,
                            product.colors.isNotEmpty ? product.colors.first : "Standard",
                          );

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.title} ajouté au panier !'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: const Color(0xFFD4AF37),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        },
                      ),
                    ],
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