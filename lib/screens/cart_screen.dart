import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart'; 
import 'package:flutterwave_standard/flutterwave.dart';
import '../providers/cart_provider.dart';
// 🟢 Importation de ton nouveau service M-Pesa
import '../services/mpesa_service.dart'; 

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

class OrderButton extends StatefulWidget {
  final CartProvider cart;
  const OrderButton({super.key, required this.cart});

  @override
  State<OrderButton> createState() => _OrderButtonState();
}

class _OrderButtonState extends State<OrderButton> {
  var _isLoading = false;
  final MpesaService _mpesaService = MpesaService(); // 🟢 Instance de ton service

  /// 🟢 MODIFICATION : Affiche une feuille de choix pour le mode de paiement
  void _showPaymentSelection(Map<String, dynamic> userData, String address) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Choisir le mode de paiement",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              // Option 1 : M-Pesa Direct via Cloud Functions
              ListTile(
                leading: const Icon(Icons.phone_android, color: Colors.green, size: 28),
                title: const Text("M-Pesa Express (STK Push)", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Pop-up automatique sur votre téléphone"),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleMpesaDirectPayment(userData, address);
                },
              ),
              const Divider(),
              // Option 2 : Flutterwave (Cartes, etc.)
              ListTile(
                leading: const Icon(Icons.credit_card, color: Color(0xFFD4AF37), size: 28),
                title: const Text("Carte bancaire / Autres via Flutterwave"),
                subtitle: const Text("Visa, Mastercard, Airtel Money"),
                onTap: () {
                  Navigator.pop(ctx);
                  _handleFlutterwavePayment(userData, address);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 🟢 NOUVEAU : Traitement direct M-Pesa via ta Firebase Cloud Function
  Future<void> _handleMpesaDirectPayment(Map<String, dynamic> userData, String address) async {
    setState(() => _isLoading = true);
    final String cleanPhone = (userData['phone'] ?? "").toString().replaceAll('+', '').trim();

    if (cleanPhone.isEmpty) {
      _showErrorSnackBar("Numéro de téléphone requis pour M-Pesa.");
      setState(() => _isLoading = false);
      return;
    }

    // Le montant converti en entier (par exemple pour l'API)
    final int amountAsInt = widget.cart.totalAmount.round();

    final result = await _mpesaService.initierPaiement(
      phoneNumber: cleanPhone, // Format attendu : 2547XXXXXXXX
      amount: amountAsInt > 0 ? amountAsInt : 1,
    );

    if (result['success'] == true) {
      final String transactionRef = const Uuid().v4();
      await _saveOrderToFirebase(userData, address, transactionRef, "M-Pesa Direct (Cloud Function)");
      
      if (!mounted) return;
      widget.cart.clear(); 
      _showSuccessDialog("Demande de paiement envoyée ! Veuillez saisir votre code PIN M-Pesa sur votre téléphone.");
    } else {
      _showErrorSnackBar(result['message']);
    }

    setState(() => _isLoading = false);
  }

  /// Traitement classique Flutterwave original
  Future<void> _handleFlutterwavePayment(Map<String, dynamic> userData, String address) async {
    setState(() => _isLoading = true);
    final String transactionRef = const Uuid().v4(); 

    final Customer customer = Customer(
      name: userData['name'] ?? "Client MoMart",
      phoneNumber: userData['phone'] ?? "0000000000",
      email: userData['email'] ?? "client@momart.com",
    );

    final Customization customization = Customization(
      title: "Paiement MoMart",
      description: "Validation de votre panier",
      logo: "assets/images/logo2.png",
    );

    final Flutterwave flutterwave = Flutterwave(
      publicKey: "FLWPUBK_TEST-XXXXX-X", // ⚠️ À remplacer par ta clé de test
      currency: "EUR", 
      amount: widget.cart.totalAmount.toStringAsFixed(2),
      customer: customer,
      txRef: transactionRef,
      customization: customization,
      paymentOptions: "card, mpesa, airtelmoney", 
      redirectUrl: "https://www.google.com", 
      isTestMode: true,
    );

    try {
      final ChargeResponse response = await flutterwave.charge(context);

      if (response.status == "success" || response.success == true) {
        await _saveOrderToFirebase(userData, address, transactionRef, "Flutterwave (Carte / Mobile)");
        
        if (!mounted) return;
        widget.cart.clear(); 
        _showSuccessDialog("Votre paiement a été validé avec succès !");
      } else {
        _showErrorSnackBar("Le paiement a été annulé ou rejeté.");
      }
    } catch (error) {
      debugPrint("Erreur Flutterwave: $error");
      _showErrorSnackBar("Impossible de finaliser la transaction.");
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveOrderToFirebase(Map<String, dynamic> userData, String address, String txRef, String paymentMethod) async {
    await FirebaseFirestore.instance.collection('orders').add({
      'amount': widget.cart.totalAmount,
      'dateTime': DateTime.now().toIso8601String(),
      'status': 'Payé',
      'transactionReference': txRef,
      'paymentMethod': paymentMethod,
      'customerName': userData['name'] ?? 'Inconnu',
      'customerEmail': userData['email'] ?? 'Non fourni',
      'deliveryAddress': address,
      'products': widget.cart.items.values.map((item) => {
        'title': item.title,
        'quantity': item.quantity,
        'price': item.price,
      }).toList(),
    });
  }

  Future<void> _processOrder() async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc('user_1').get();
      final userData = userDoc.data();
      final String address = (userData != null && userData['address'] != null) 
          ? (userData['address'] as String).trim() 
          : 'Adresse non fournie';

      if (!userDoc.exists || address == 'Adresse non fournie') {
        if (!mounted) return;
        _showWarningSnackBar('Veuillez renseigner votre adresse dans votre profil.');
        return; 
      }

      // Ouvre le menu de sélection du mode de paiement
      _showPaymentSelection(userData!, address);

    } catch (error) {
      debugPrint("Erreur Firestore : $error");
    }
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  void _showWarningSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.orange));
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text("Commande Traitée"),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); 
            },
            child: const Text("Fermer", style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50, 
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD4AF37), 
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[400],
          elevation: 0, 
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: (widget.cart.totalAmount <= 0 || _isLoading) ? null : _processOrder,
        child: _isLoading 
          ? const SizedBox(
              width: 24, 
              height: 24, 
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
            ) 
          : const Text(
              'Commander', 
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
      ),
    );
  }
}