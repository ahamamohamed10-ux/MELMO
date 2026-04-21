import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: demoProducts.length,
      itemBuilder: (ctx, i) => ProductCard(product: demoProducts[i]),
    );
  }
}
