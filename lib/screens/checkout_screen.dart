import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  final CartProvider cart;

  const CheckoutScreen({
    super.key,
    required this.cart,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // Numéro WhatsApp du vendeur MELMO
  static const String _whatsappNumber = '254755312957';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      _nameController.text = user.displayName ?? '';

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        if (_phoneController.text.isEmpty && data['phone'] != null) {
          _phoneController.text = data['phone'].toString();
        }

        if (_addressController.text.isEmpty && data['address'] != null) {
          _addressController.text = data['address'].toString();
        }
      }
    }
  }

  Future<DocumentReference> _saveOrderToFirebase() async {
    final user = FirebaseAuth.instance.currentUser;

    final orderReference =
        'WA-${DateTime.now().millisecondsSinceEpoch}';

    return await FirebaseFirestore.instance.collection('orders').add({
      'userId': user?.uid ?? 'guest',
      'customerName': _nameController.text.trim(),
      'customerEmail': user?.email ?? 'Non fourni',
      'customerPhone': _phoneController.text.trim(),
      'deliveryAddress': _addressController.text.trim(),
      'amount': widget.cart.totalAmount,
      'paymentMethod': 'WhatsApp',
      'transactionReference': orderReference,
      'status': 'En attente de confirmation',
      'createdAt': FieldValue.serverTimestamp(),
      'products': widget.cart.items.values.map((item) {
        return {
          'id': item.id,
          'title': item.title,
          'quantity': item.quantity,
          'price': item.price,
        };
      }).toList(),
    });
  }

  String _buildWhatsAppMessage(String orderReference) {
    final buffer = StringBuffer();

    buffer.writeln('🛍️ *NOUVELLE COMMANDE MELMO*');
    buffer.writeln('');
    buffer.writeln('📋 *Référence :* $orderReference');
    buffer.writeln('👤 *Client :* ${_nameController.text.trim()}');
    buffer.writeln('📱 *Téléphone :* ${_phoneController.text.trim()}');
    buffer.writeln(
      '📍 *Adresse :* ${_addressController.text.trim()}',
    );
    buffer.writeln('');
    buffer.writeln('🛒 *Produits :*');

    for (final item in widget.cart.items.values) {
      buffer.writeln(
        '• ${item.title} × ${item.quantity} '
        '— ${item.price.toStringAsFixed(2)}',
      );
    }

    buffer.writeln('');
    buffer.writeln(
      '💰 *TOTAL : ${widget.cart.totalAmount.toStringAsFixed(2)}*',
    );
    buffer.writeln('');
    buffer.writeln(
      '💳 *Paiement :* À confirmer avec le vendeur',
    );
    buffer.writeln('');
    buffer.writeln('Merci de confirmer ma commande. 🙏');

    return buffer.toString();
  }

  Future<void> _orderViaWhatsApp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre panier est vide.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final orderReference =
          'WA-${DateTime.now().millisecondsSinceEpoch}';

      // 1. Enregistrer la commande dans Firebase
      await _saveOrderToFirebase();

      // 2. Préparer le message WhatsApp
      final message = _buildWhatsAppMessage(orderReference);

      final uri = Uri.parse(
        'https://wa.me/$_whatsappNumber?text=${Uri.encodeComponent(message)}',
      );

      // 3. Ouvrir WhatsApp
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw 'Impossible d\'ouvrir WhatsApp.';
      }

      // 4. Vider le panier après l'ouverture de WhatsApp
      widget.cart.clear();

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur : $error'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finaliser la commande'),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Préparation de votre commande...',
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total :',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.cart.totalAmount.toStringAsFixed(2),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Informations de livraison',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Entrez votre nom';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        hintText: 'Ex : +269...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Entrez votre numéro de téléphone';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Adresse de livraison',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Entrez votre adresse de livraison';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.chat,
                                  color: Colors.green,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Commander via WhatsApp',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Votre commande sera envoyée au vendeur '
                              'sur WhatsApp. Le vendeur vous contactera '
                              'pour confirmer la commande, la livraison '
                              'et le paiement.',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _orderViaWhatsApp,
                        icon: const Icon(Icons.chat),
                        label: const Text(
                          'Commander via WhatsApp',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Center(
                      child: Text(
                        'Le paiement sera confirmé avec le vendeur.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}