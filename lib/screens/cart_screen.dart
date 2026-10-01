import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'checkout_screen.dart';


class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final cartItemIds = cart.items.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7), 
      appBar: AppBar(
        title: const Text(
          'Mon Panier MoMart', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: cartItemIds.isEmpty
                ? const Center(child: Text('Votre panier est vide 🛒', style: TextStyle(fontSize: 16)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    itemCount: cartItemIds.length,
                    itemBuilder: (ctx, i) {
                      final prodId = cartItemIds[i];
                      final cartData = cart.items[prodId]!;

                      return Card(
                        elevation: 0.5,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        color: const Color(0xFFF7F0E6), 
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 55,
                                height: 55,
                                child: cartData.imageUrl.startsWith('http')
                                    ? Image.network(cartData.imageUrl, fit: BoxFit.cover)
                                    : Image.asset(cartData.imageUrl, fit: BoxFit.cover),
                              ),
                            ),
                            title: Text(
                              cartData.title, 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => cart.decrementQuantity(prodId),
                                    child: const Icon(Icons.remove_circle_outline, color: Colors.orange, size: 24),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      '${cartData.quantity}', 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => cart.incrementQuantity(prodId),
                                    child: const Icon(Icons.add_circle_outline, color: Colors.green, size: 24),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${(cartData.price * cartData.quantity).toStringAsFixed(2)} €',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                                GestureDetector(
                                  onTap: () => cart.removeItem(prodId),
                                  child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -4))
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      Text(
                        '${cart.totalAmount.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 22, 
                          fontWeight: FontWeight.bold, 
                          color: Color(0xFFD4AF37), 
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  OrderButton(cart: cart), 
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderButton extends StatelessWidget {
  final CartProvider cart;

  const OrderButton({
    super.key,
    required this.cart,
  });

  void _openCheckout(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(cart: cart),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4AF37),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: cart.totalAmount <= 0
            ? null
            : () => _openCheckout(context),
        icon: const Icon(Icons.shopping_cart_checkout),
        label: const Text(
          'Commander',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}