import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import 'cart_screen.dart';
import 'catalog_screen.dart';
import 'profile_screen.dart';
import 'product_detail_screen.dart';
import 'package:melmo/screens/add_product_screen.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart'; // Import indispensable pour la synchronisation

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Liste des pages de l'application
  final List<Widget> _pages = [
    const HomeBody(),
    const CatalogScreen(),
    const MessagesScreen(), 
    const ProfileScreen(),   
  ];

  @override
  Widget build(BuildContext context) {
    // Écoute du provider de navigation globale
    final navProvider = Provider.of<NavigationProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Image.asset(
          'assets/images/logo2.png',
          height: 45,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Text(
            "MoMart",
            style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
          ),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Stack(
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
              );
            },
          ),
        ],
      ),
      
      // Utilisation de l'index synchronisé du NavigationProvider
      body: _pages[navProvider.currentTab],
      
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
        onTap: (index) => navProvider.changeTab(index), // Met à jour le provider au clic
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed, 
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled), 
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view), 
            label: 'Catalogue',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('3'), 
              backgroundColor: Colors.red,
              child: Icon(Icons.chat_bubble_outline),
            ), 
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline), 
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// HOMEBODY (CONSERVÉ À L'IDENTIQUE)
// =========================================================================
class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  String _searchQuery = '';
  String _selectedCategory = 'Tout';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeBannerSlider(),
          _buildFeaturesBar(),
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
          _buildCategoryGrid(),
          const Padding(
            padding: EdgeInsets.fromLTRB(15, 20, 15, 10),
            child: Text(
              "Featured Products",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
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
                return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text("Aucun document trouvé dans la collection 'products'"),
                ));
              }
              
              final filtered = snapshot.data!.docs.map((doc) {
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
                  colors: data['colors'] != null ? List<String>.from(data['colors']) : [], // <-- ASSUREZ-VOUS DE BIEN TRAITER LA LISTE DE COULEURS
                );
              }).where((p) {
                final matchesSearch = p.title.toLowerCase().contains(_searchQuery.toLowerCase());
                final matchesCategory = _selectedCategory == 'Tout' || p.category == _selectedCategory;
                return matchesSearch && matchesCategory;
              }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Text("Aucun produit ne correspond à la recherche ou catégorie"),
                ));
              }

              return GridView.builder(
                shrinkWrap: true, 
                physics: const NeverScrollableScrollPhysics(), 
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
        ],
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = 'Robes'),
              child: Container(
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/women.jpg'), 
                    fit: BoxFit.cover,
                  ),
                ),
                padding: const EdgeInsets.all(15),
                alignment: Alignment.bottomLeft,
                child: const Text(
                  "Women's\nStyle",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 5)],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 220,
              child: Column(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = 'Tout'),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(15),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/handbag.jpg'), 
                            fit: BoxFit.cover,
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        alignment: Alignment.bottomLeft,
                        child: const Text(
                          "Handbag",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = 'Bijoux'),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(15),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/watch.jpg'), 
                            fit: BoxFit.cover,
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        alignment: Alignment.bottomLeft,
                        child: const Text(
                          "Watch",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesBar() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!, width: 1),
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _featureItem(Icons.local_shipping_outlined, "Livraison\nGratuite"),
          _featureItem(Icons.security_outlined, "Paiement\nSécurisé"),
          _featureItem(Icons.verified_outlined, "Qualité\nGarantie"),
        ],
      ),
    );
  }

  Widget _featureItem(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFD4AF37), size: 24),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
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
                      product.images.isNotEmpty ? product.images[0] : '',
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
                  Positioned(
                    top: 5,
                    right: 5,
                    child: IconButton(
                      icon: const Icon(Icons.favorite_border, color: Colors.white, size: 22),
                      onPressed: () {},
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
                          fontSize: 16
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_shopping_cart, size: 20, color: Colors.black54),
                        onPressed: () {
                          String imageUrl = product.images.isNotEmpty ? product.images[0] : '';
                          Provider.of<CartProvider>(context, listen: false).addItem(
                            product.id,
                            product.price,
                            product.title,
                            imageUrl,
                            product.colors.isNotEmpty ? product.colors.first : "Standard", // <-- AJOUTE CE 5ème ARGUMENT ICI AUSSI
                            
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

class HomeBannerSlider extends StatefulWidget {
  const HomeBannerSlider({super.key});

  @override
  State<HomeBannerSlider> createState() => _HomeBannerSliderState();
}

class _HomeBannerSliderState extends State<HomeBannerSlider> {
  final PageController _bannerController = PageController();
  int _currentBannerPage = 0;
  Timer? _bannerTimer;

  final List<String> _bannerImages = [
    'assets/images/banner_model.jpg',
    'assets/images/banner2.jpg', 
    'assets/images/banner3.jpg', 
  ];

  @override
  void initState() {
    super.initState();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentBannerPage < _bannerImages.length - 1) {
        _currentBannerPage++;
      } else {
        _currentBannerPage = 0;
      }

      if (_bannerController.hasClients) {
        _bannerController.animateToPage(
          _currentBannerPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      width: double.infinity,
      child: Stack(
        children: [
          PageView.builder(
            controller: _bannerController,
            itemCount: _bannerImages.length,
            onPageChanged: (index) {
              setState(() {
                _currentBannerPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  image: DecorationImage(
                    image: AssetImage(_bannerImages[index]),
                    fit: BoxFit.cover,
                    alignment: Alignment.topRight,
                  ),
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.white.withValues(alpha: 0.85),
                  Colors.white.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 45,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Season Sale",
                  style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 5),
                const Text(
                  "MELMO\nFASHION",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text("Min. 35-70% Off", style: TextStyle(color: Colors.black54, fontSize: 14)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: const Text("SHOP NOW", style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: const Text("READ MORE", style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 15,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _bannerImages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: _currentBannerPage == index ? 20 : 8,
                  decoration: BoxDecoration(
                    color: _currentBannerPage == index ? const Color(0xFFD4AF37) : Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// MESSAGES SCREEN COMPATIBLE AVEC LE NAVIGATION_PROVIDER
// =========================================================================
class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? 'guest_user';
  String get _userEmail => _auth.currentUser?.email ?? 'client@test.com';

  @override
  void initState() {
    super.initState();
    // Utilisation de WidgetsBinding pour intercepter le texte initial après le premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navProvider = Provider.of<NavigationProvider>(context, listen: false);
      if (navProvider.initialMessage != null && navProvider.initialMessage!.isNotEmpty) {
        setState(() {
          _messageController.text = navProvider.initialMessage!;
        });
        // On nettoie le message initial du provider pour éviter qu'il ne réapparaisse
        navProvider.clearInitialMessage();
      }
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final chatDocRef = _firestore.collection('chats').doc(_userId);

    await chatDocRef.collection('messages').add({
      'text': text,
      'senderId': _userId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await chatDocRef.set({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'clientEmail': _userEmail,
      'userId': _userId,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .doc(_userId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 50, color: Colors.grey[400]),
                        const SizedBox(height: 10),
                        const Text(
                          "Discutez directement avec l'administration !",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final messageText = data['text'] ?? '';
                    final isMe = data['senderId'] == _userId;

                    return _buildBubble(messageText, isMe);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFD4AF37) : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Text(
          text,
          style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Écrire un message...',
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFFD4AF37)),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}