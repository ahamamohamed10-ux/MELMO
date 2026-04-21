import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // AJOUTÉ
import '../models/product.dart';
import '../screens/product_detail_screen.dart';
import '../providers/cart_provider.dart'; // AJOUTÉ

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // On récupère la première image de la liste pour l'aperçu
    final String coverImage = product.images.isNotEmpty ? product.images[0] : '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: coverImage.startsWith('http')
              ? Image.network(
                  coverImage,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image),
                )
              : Image.asset(
                  coverImage,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image),
                ),
        ),
        title: Text(
          product.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${product.price.toStringAsFixed(2)} €',
          style: TextStyle(color: Theme.of(context).primaryColor),
        ),
        // --- MODIFICATION : Remplacement de la flèche par un bouton panier ---
        trailing: IconButton(
          icon: Icon(Icons.add_shopping_cart, color: Theme.of(context).primaryColor),
          onPressed: () {
            // On envoie les 4 infos nécessaires au CartProvider
            Provider.of<CartProvider>(context, listen: false).addItem(
              product.id,
              product.price,
              product.title,
              coverImage,
            );

            // Petit message de confirmation
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${product.title} ajouté au panier !'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}
