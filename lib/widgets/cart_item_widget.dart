import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../models/product.dart';

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
    // Récupération des infos du produit via l'ID
    final product = demoProducts.firstWhere((p) => p.id == productId);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ListTile(
          leading: CircleAvatar(
  backgroundImage: product.images[0].startsWith('http')
      ? NetworkImage(product.images[0]) as ImageProvider
      : AssetImage(product.images[0]) as ImageProvider,
),
          title: Text(product.title),
          subtitle: Text(
            'Total: ${(product.price * quantity).toStringAsFixed(2)} €',
          ),
          trailing: Text('$quantity x'),
          // Optionnel : Ajouter un bouton pour supprimer directement ici
          onLongPress: () {
            Provider.of<CartProvider>(
              context,
              listen: false,
            ).removeItem(productId);
          },
        ),
      ),
    );
  }
}
