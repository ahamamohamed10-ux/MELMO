import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class CartItemWidget extends StatelessWidget {
  final String productId;
  final int quantity;

  const CartItemWidget({
    super.key,
    required this.productId,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Récupération du panier complet depuis le CartProvider
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    // 2. Extraction des données spécifiques de cet article
    final cartItem = cartProvider.items[productId];

    // Sécurité au cas où l'article n'existe pas dans le dictionnaire
    if (cartItem == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ListTile(
          // Affichage dynamique de l'image stockée dans le panier
          leading: CircleAvatar(
            backgroundColor: Colors.grey[200],
            backgroundImage: cartItem.imageUrl.startsWith('http')
                ? NetworkImage(cartItem.imageUrl) as ImageProvider
                : AssetImage(cartItem.imageUrl) as ImageProvider,
          ),
          
          // Nom du produit
          title: Text(
            cartItem.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          
          // Sous-titre avec uniquement le prix total calculé
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              'Total: ${(cartItem.price * quantity).toStringAsFixed(2)} €',
              style: const TextStyle(
                color: Color(0xFFD4AF37),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          // Quantité commandée
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$quantity x',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          
          // Un appui long permet de retirer l'article du panier
          onLongPress: () {
            cartProvider.removeItem(productId);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${cartItem.title} retiré du panier'),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}