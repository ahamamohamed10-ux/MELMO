import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart';
import 'checkout_screen.dart';
import '../widgets/delivery_info_tile.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _selectedColorHex;
  String? _selectedSize;

  @override
  void initState() {
    super.initState();
    if (widget.product.colors.isNotEmpty) {
      _selectedColorHex = widget.product.colors.first;
    }
    if (widget.product.sizes.isNotEmpty) {
      _selectedSize = widget.product.sizes.first;
    }
  }

  Color _parseColor(String colorStr) {
    String cleanColor = colorStr.trim().replaceAll('#', '');

    switch (cleanColor.toLowerCase()) {
      case 'rouge':
      case 'red':
        return Colors.red;
      case 'bleu':
      case 'blue':
        return Colors.blue;
      case 'noir':
      case 'black':
        return Colors.black;
      case 'blanc':
      case 'white':
        return Colors.grey[300]!;
      case 'vert':
      case 'green':
        return Colors.green;
      case 'jaune':
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'rose':
      case 'pink':
        return Colors.pink;
      case 'violet':
      case 'purple':
        return Colors.purple;
      case 'gris':
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'marron':
      case 'brown':
        return Colors.brown;
    }

    try {
      if (cleanColor.startsWith('0x') || cleanColor.startsWith('0X')) {
        cleanColor = cleanColor.substring(2);
      }
      if (cleanColor.length == 3) {
        cleanColor = cleanColor.split('').map((c) => '$c$c').join();
      }
      if (cleanColor.length == 6) {
        cleanColor = 'FF$cleanColor';
      }
      return Color(int.parse(cleanColor, radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

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

  Widget _buildRatingStars(double rating, {double size = 20}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, color: Colors.amber, size: size);
        } else if (index < rating && rating % 1 != 0) {
          return Icon(Icons.star_half, color: Colors.amber, size: size);
        } else {
          return Icon(Icons.star_border, color: Colors.grey, size: size);
        }
      }),
    );
  }

  void _showAddReviewDialog() {
    double userRating = 5.0;
    final nameController = TextEditingController();
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text("Laisser un avis"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              userRating = (index + 1).toDouble();
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Icon(
                              index < userRating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 32,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Votre nom",
                        hintText: "Ex: Amina M.",
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Votre commentaire",
                        hintText: "Donnez votre avis sur le produit...",
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("Annuler"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                  ),
                  onPressed: () async {
                    if (commentController.text.trim().isEmpty) return;

                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(ctx);

                    await FirebaseFirestore.instance
                        .collection('products')
                        .doc(widget.product.id)
                        .collection('reviews')
                        .add({
                      'userName': nameController.text.trim().isEmpty
                          ? "Client MoMart"
                          : nameController.text.trim(),
                      'rating': userRating,
                      'comment': commentController.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text("Merci pour votre avis !"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text("Publier", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> availableColors = widget.product.colors;
    final List<String> availableSizes = widget.product.sizes;

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
            // --- SLIDER D'IMAGES ---
            AspectRatio(
              aspectRatio: 1.1,
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

            // --- INFOS PRODUIT ---
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

                  // --- SECTION COULEURS ---
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
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: colorObj.withValues(alpha: 0.4),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : [],
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

                  // --- SECTION TAILLES ---
                  if (availableSizes.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      "Tailles disponibles",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      children: availableSizes.map((sizeStr) {
                        final isSelected = _selectedSize == sizeStr;
                        return ChoiceChip(
                          label: Text(sizeStr),
                          selected: isSelected,
                          selectedColor: const Color(0xFFD4AF37),
                          backgroundColor: Colors.grey[100],
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFFD4AF37) : Colors.grey[300]!,
                            ),
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedSize = sizeStr;
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],

                  // --- SECTION DESCRIPTION ---
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
                  const SizedBox(height: 20),
                   // Integrated here
                  DeliveryInfoTile(
              shippingFee: widget.product.shippingFee,
              estimatedDelivery: widget.product.estimatedDelivery,
              destinationName: widget.product.destinationName,
              returnPolicyDays: widget.product.returnPolicyDays,
            ),


                  // --- SECTION AVIS ET EVALUATIONS ---
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          "Avis et commentaires",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _showAddReviewDialog,
                        icon: const Icon(Icons.rate_review, color: Color(0xFFD4AF37), size: 16),
                        label: const Text(
                          "Donner un avis",
                          style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('products')
                        .doc(widget.product.id)
                        .collection('reviews')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            "Aucun avis pour l'instant. Soyez le premier à donner votre avis !",
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      double totalRating = 0;
                      for (var doc in docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        totalRating += (data['rating'] as num? ?? 5).toDouble();
                      }
                      double avgRating = totalRating / docs.length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildRatingStars(avgRating),
                              const SizedBox(width: 10),
                              Text(
                                "${avgRating.toStringAsFixed(1)} / 5",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "(${docs.length} avis)",
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final review = docs[index].data() as Map<String, dynamic>;
                              final rating = (review['rating'] as num? ?? 5).toDouble();
                              return Card(
                                color: Colors.grey[50],
                                elevation: 0,
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.grey[200]!),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            review['userName'] ?? "Anonyme",
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          _buildRatingStars(rating, size: 16),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        review['comment'] ?? "",
                                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),

      // --- BARRE DE COMMANDE EN BAS ---
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
            OutlinedButton(
              onPressed: () {
                final activeColor = _selectedColorHex ?? "Standard";
                final activeSize = _selectedSize ?? "";
                final variant = activeSize.isNotEmpty ? "$activeColor / $activeSize" : activeColor;

                Provider.of<CartProvider>(context, listen: false).addItem(
                  widget.product.id,
                  widget.product.price,
                  widget.product.title,
                  widget.product.images.isNotEmpty ? widget.product.images[0].trim() : '',
                  variant,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${widget.product.title} ($variant) ajouté au panier'),
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

            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  final activeColor = _selectedColorHex ?? "Standard";
                  final activeSize = _selectedSize ?? "";
                  final variantDetails = activeSize.isNotEmpty
                      ? "Couleur: $activeColor, Taille: $activeSize"
                      : "Couleur: $activeColor";

                  final String messageText =
                      "Bonjour MoMart, je souhaite avoir plus d'informations sur le produit : ${widget.product.title} ($variantDetails)";

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

            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: () {
                  final activeColor = _selectedColorHex ?? "Standard";
                  final activeSize = _selectedSize ?? "";
                  final variant = activeSize.isNotEmpty ? "$activeColor / $activeSize" : activeColor;

                  Provider.of<CartProvider>(context, listen: false).addItem(
                    widget.product.id,
                    widget.product.price,
                    widget.product.title,
                    widget.product.images.isNotEmpty ? widget.product.images[0].trim() : '',
                    variant,
                  );

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CheckoutScreen(
                        cart: Provider.of<CartProvider>(context, listen: false),
                      ),
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