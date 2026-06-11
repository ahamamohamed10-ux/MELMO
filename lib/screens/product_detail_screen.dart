import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart';
import 'checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _selectedColorHex; // Stocke la couleur sélectionnée sous forme de texte Hex

  @override
  void initState() {
    super.initState();
    // Assigne la première couleur par défaut si la liste n'est pas vide
    if (widget.product.colors.isNotEmpty) {
      _selectedColorHex = widget.product.colors.first;
    }
  }

  // --- FONCTION ULTRA-SÉCURISÉE POUR CONVERTIR LE HEX EN OBJET COLOR ---
  Color _parseColor(String colorStr) {
    String cleanColor = colorStr.trim().replaceAll('#', '');
    
    try {
      // Si le format est court (ex: FFFFFF), on ajoute l'opacité complète FF
      if (cleanColor.length == 6) {
        cleanColor = 'FF$cleanColor';
      }
      // Supprime le préfixe 0x s'il est déjà présent dans la chaîne
      if (cleanColor.startsWith('0x') || cleanColor.startsWith('0X')) {
        cleanColor = cleanColor.substring(2);
      }
      
      return Color(int.parse(cleanColor, radix: 16));
    } catch (e) {
      // Évite le crash "FormatException" si le texte est invalide (ex: le mot "rouge")
      return Colors.grey;
    }
  }

  // --- FONCTION POUR LE ZOOM PLEIN ÉCRAN ---
  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(imageUrl.trim()),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> availableColors = widget.product.colors;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.product.title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- LE SLIDER D'IMAGES AVEC ZOOM ---
            SizedBox(
              height: 350,
              width: double.infinity,
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: widget.product.images.length,
                    itemBuilder: (context, index) {
                      final String imgUrl = widget.product.images[index].trim();
                      
                      Widget imageWidget = GestureDetector(
                        onTap: () => _showFullScreenImage(context, imgUrl),
                        child: Image.network(
                          imgUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
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
                            child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                          ),
                        ),
                      );

                      if (index == 0) {
                        return Hero(tag: widget.product.id, child: imageWidget);
                      }
                      return imageWidget;
                    },
                  ),
                  if (widget.product.images.length > 1)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.swipe, color: Colors.white, size: 16),
                            SizedBox(width: 5),
                            Text(
                              'Glissez pour voir plus',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // --- LES INFOS PRODUIT ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    '${widget.product.price.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontSize: 22,
                      color: Color(0xFFD4AF37), 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  // =========================================================================
                  // SECTION SÉLECTEUR DE COULEURS DE MOMART (SÉCURISÉE)
                  // =========================================================================
                  if (availableColors.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      "Couleurs disponibles",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 46,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: availableColors.length,
                        itemBuilder: (ctx, index) {
                          final colorHex = availableColors[index];
                          final colorObj = _parseColor(colorHex);
                          
                          if (_selectedColorHex == null && index == 0) {
                            _selectedColorHex = colorHex;
                          }
                          
                          final isSelected = _selectedColorHex == colorHex;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColorHex = colorHex;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 12),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: colorObj,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[300]!,
                                  width: isSelected ? 3 : 1,
                                ),
                                boxShadow: isSelected ? [
                                  BoxShadow(
                                    color: colorObj.withValues(alpha: (0.4 * 255).roundToDouble()),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  )
                                ] : [],
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      color: colorObj.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                                      size: 18,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description.isNotEmpty 
                        ? widget.product.description 
                        : "Aucune description disponible.",
                    style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                  ),
                  
                  const SizedBox(height: 100), // Espace de défilement pour le bas
                ],
              ),
            ),
          ],
        ),
      ),

      // --- BOUTONS ACTION D'ACHAT EN BAS ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 24, top: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            // ------ 🛒 BOUTON PANIER ------
            OutlinedButton(
              onPressed: () {
                final activeColor = _selectedColorHex ?? "Standard";

                Provider.of<CartProvider>(context, listen: false).addItem(
                  widget.product.id, 
                  widget.product.price,
                  widget.product.title,
                  widget.product.images.isNotEmpty ? widget.product.images[0].trim() : '',
                  activeColor,
                );
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${widget.product.title} ($activeColor) ajouté au panier'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Icon(Icons.add_shopping_cart, color: Color(0xFFD4AF37)),
            ),
            
            const SizedBox(width: 8),

            // ------ 💬 BOUTON QUESTIONS (NAVIGATION VERS MESSAGERIE) ------
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  final activeColor = _selectedColorHex ?? "Standard";
                  final String messageText = "Bonjour MoMart, je souhaite avoir plus d'informations sur le produit : ${widget.product.title} (Couleur : $activeColor)";
                  
                  Provider.of<NavigationProvider>(context, listen: false).changeTab(
                    2, 
                    initialMessage: messageText,
                  );
                  
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFFD4AF37), size: 18),
                label: const Text(
                  'Questions',
                  style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFDFBF7), 
                  elevation: 0,
                  side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            
            const SizedBox(width: 8),

            // ------ ⚡ BOUTON COMMANDER DIRECTEMENT ------
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: () {
                  final activeColor = _selectedColorHex ?? "Standard";

                  Provider.of<CartProvider>(context, listen: false).addItem(
                    widget.product.id, 
                    widget.product.price,
                    widget.product.title,
                    widget.product.images.isNotEmpty ? widget.product.images[0].trim() : '',
                    activeColor,
                  );
                  
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CheckoutScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text(
                  'Commander',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}