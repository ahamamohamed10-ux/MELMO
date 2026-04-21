import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; 
import '../providers/cart_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final cartItemIds = cart.items.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Panier MoMart'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Liste des produits dans le panier
          Expanded(
            child: cartItemIds.isEmpty
                ? const Center(child: Text('Votre panier est vide 🛒'))
                : ListView.builder(
                    itemCount: cartItemIds.length,
                    itemBuilder: (ctx, i) {
                      final prodId = cartItemIds[i];
                      final cartData = cart.items[prodId]!;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: cartData.imageUrl.startsWith('http')
                                  ? Image.network(cartData.imageUrl, fit: BoxFit.cover)
                                  : Image.asset(cartData.imageUrl, fit: BoxFit.cover),
                            ),
                          ),
                          title: Text(cartData.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                                onPressed: () => cart.decrementQuantity(prodId),
                              ),
                              Text('${cartData.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                onPressed: () => cart.incrementQuantity(prodId),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${(cartData.price * cartData.quantity).toStringAsFixed(2)} €'),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () => cart.removeItem(prodId),
                                child: const Icon(Icons.delete_outline, color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Zone du Total et Bouton de validation
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration( // Ajout du const ici pour corriger l'erreur
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(
                      '${cart.totalAmount.toStringAsFixed(2)} €',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                OrderButton(cart: cart),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OrderButton extends StatefulWidget {
  final CartProvider cart;
  const OrderButton({super.key, required this.cart});

  @override
  State<OrderButton> createState() => _OrderButtonState();
}

class _OrderButtonState extends State<OrderButton> {
  var _isLoading = false;

  // --- ENVOI VERS WHATSAPP ---
  Future<void> _sendToWhatsApp(Map<String, dynamic>? userData, String address) async {
    const String numero = "254792891643"; // Ton numéro configuré
    
    String message = "🚀 *Nouvelle Commande MoMart*\n\n";
    message += "Client: ${userData?['name'] ?? 'Inconnu'}\n";
    message += "Adresse: $address\n\n";
    message += "Articles :\n";
    
    // Boucle for recommandée par Dart pour la performance
    for (var item in widget.cart.items.values) {
      message += "• ${item.title} (x${item.quantity}) - ${(item.price * item.quantity).toStringAsFixed(2)} €\n";
    }
    
    message += "\n*Total à payer : ${widget.cart.totalAmount.toStringAsFixed(2)} €*";

    final Uri url = Uri.parse("https://wa.me/$numero?text=${Uri.encodeComponent(message)}");
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Erreur WhatsApp: $e");
    }
  }

  // --- ENREGISTREMENT FIREBASE + APPEL WHATSAPP ---
  Future<void> _processOrder() async {
    setState(() => _isLoading = true);

    try {
      // Récupération de l'adresse utilisateur dans Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc('user_1').get();
      final userData = userDoc.data();
      final String address = (userData != null && userData['address'] != null) 
          ? (userData['address'] as String).trim() 
          : 'Adresse non fournie';

      if (!userDoc.exists || address == 'Adresse non fournie') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez compléter votre adresse dans le profil.'), 
            backgroundColor: Colors.orange
          ),
        );
        setState(() => _isLoading = false);
        return; 
      }

      // 1. Sauvegarde dans Firestore pour ton suivi admin
      await FirebaseFirestore.instance.collection('orders').add({
        'amount': widget.cart.totalAmount,
        'dateTime': DateTime.now().toIso8601String(),
        'status': 'En attente',
        'customerName': userData?['name'] ?? 'Inconnu',
        'deliveryAddress': address,
        'products': widget.cart.items.values.map((item) => {
          'title': item.title,
          'quantity': item.quantity,
          'price': item.price,
        }).toList(),
      });

      // 2. Lancement de WhatsApp
      await _sendToWhatsApp(userData, address);

      if (!mounted) return;
      widget.cart.clear(); // On vide le panier après succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande validée !')),
      );
    } catch (error) {
      debugPrint("Erreur : $error");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        // Utilisation de label au lieu de child pour corriger l'erreur ElevatedButton.icon
        icon: _isLoading 
          ? const SizedBox(
              width: 20, 
              height: 20, 
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            ) 
          : const Icon(Icons.send), 
        label: const Text(
          'VALIDER ET COMMANDER', 
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF25D366), // Vert WhatsApp
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: (widget.cart.totalAmount <= 0 || _isLoading) ? null : _processOrder,
      ),
    );
  }
}
