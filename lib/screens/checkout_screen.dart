import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../providers/cart_provider.dart'; 

enum PaymentMethod { mpesa, mvola, cashOnDelivery }

class CheckoutScreen extends StatefulWidget {
  final CartProvider cart;

  const CheckoutScreen({super.key, required this.cart});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  
  PaymentMethod _selectedMethod = PaymentMethod.mpesa;
  bool _isLoading = false;

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

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
          _phoneController.text = data['phone'];
        }
        if (_addressController.text.isEmpty && data['address'] != null) {
          _addressController.text = data['address'];
        }
      }
    }
  }

  String _formatMpesaPhone(String rawPhone) {
    String cleaned = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '254${cleaned.substring(1)}';
    } else if (cleaned.startsWith('+254')) {
      cleaned = cleaned.substring(1);
    }
    return cleaned;
  }

  String _formatMvolaPhone(String rawPhone) {
    String cleaned = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '261${cleaned.substring(1)}';
    } else if (cleaned.startsWith('+261')) {
      cleaned = cleaned.substring(1);
    }
    return cleaned;
  }

  Future<DocumentReference> _saveOrderToFirebase({
    required String address,
    required String txRef,
    required String paymentMethod,
    required String status,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    
    return await FirebaseFirestore.instance.collection('orders').add({
      'userId': user?.uid ?? 'guest',
      'customerName': _nameController.text.trim(),
      'customerEmail': user?.email ?? 'Non fourni',
      'customerPhone': _phoneController.text.trim(),
      'deliveryAddress': address,
      'amount': widget.cart.totalAmount,
      'paymentMethod': paymentMethod,
      'transactionReference': txRef,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
      'products': widget.cart.items.values.map((item) => {
        'id': item.id,
        'title': item.title,
        'quantity': item.quantity,
        'price': item.price,
      }).toList(),
    });
  }

  Future<void> _handleMpesaPayment() async {
    final phone = _formatMpesaPhone(_phoneController.text.trim());

    if (phone.length != 12 || !phone.startsWith('254')) {
      throw 'Numéro M-Pesa invalide. Utilisez un format comme 0712345678 ou 254712345678.';
    }

    final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('mpesaStkPush');
    final response = await callable.call(<String, dynamic>{
      'phoneNumber': phone,
      'amount': widget.cart.totalAmount.round(),
      'accountReference': 'MoMart Order',
    });

    final data = response.data as Map<String, dynamic>;

    if (data['success'] == true) {
      final checkoutRequestID = data['CheckoutRequestID'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      await _saveOrderToFirebase(
        address: _addressController.text.trim(),
        txRef: checkoutRequestID,
        paymentMethod: 'M-Pesa STK Push',
        status: 'En attente de confirmation PIN',
      );

      _showPaymentDialog(
        title: 'STK Push Envoyé',
        message: 'Un message M-Pesa a été envoyé sur le téléphone $phone. Saisissez votre code PIN M-Pesa pour valider.',
      );
    } else {
      throw data['message'] ?? 'Échec de la requête M-Pesa.';
    }
  }

  Future<void> _handleMvolaPayment() async {
    final phone = _formatMvolaPhone(_phoneController.text.trim());

    if (phone.length != 12 || !phone.startsWith('261')) {
      throw 'Numéro MVola invalide. Utilisez un format Telma (ex: 0341234567 ou 261341234567).';
    }

    final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('mvolaPay');
    final response = await callable.call(<String, dynamic>{
      'phoneNumber': phone,
      'amount': widget.cart.totalAmount.round(),
      'description': 'Achat MoMart',
    });

    final data = response.data as Map<String, dynamic>;

    if (data['success'] == true) {
      final serverCorrelationId = data['serverCorrelationId'] ?? DateTime.now().millisecondsSinceEpoch.toString();

      await _saveOrderToFirebase(
        address: _addressController.text.trim(),
        txRef: serverCorrelationId,
        paymentMethod: 'MVola Mobile Money',
        status: 'En attente de confirmation MVola',
      );

      _showPaymentDialog(
        title: 'Demande MVola Envoyée',
        message: 'Veuillez valider la notification de paiement envoyée sur votre compte MVola ($phone).',
      );
    } else {
      throw data['message'] ?? 'Échec de la transaction MVola.';
    }
  }

  Future<void> _handleCashOnDelivery() async {
    final txRef = 'COD-${DateTime.now().millisecondsSinceEpoch}';
    
    await _saveOrderToFirebase(
      address: _addressController.text.trim(),
      txRef: txRef,
      paymentMethod: 'Paiement à la livraison',
      status: 'À payer à la livraison',
    );

    _showPaymentDialog(
      title: 'Commande Confirmée',
      message: 'Votre commande a bien été enregistrée ! Vous payerez à la livraison.',
    );
  }

  Future<void> _processCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      switch (_selectedMethod) {
        case PaymentMethod.mpesa:
          await _handleMpesaPayment();
          break;
        case PaymentMethod.mvola:
          await _handleMvolaPayment();
          break;
        case PaymentMethod.cashOnDelivery:
          await _handleCashOnDelivery();
          break;
      }
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
        setState(() => _isLoading = false);
      }
    }
  }

  void _showPaymentDialog({required String title, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              widget.cart.clear();
              Navigator.of(ctx).pop();
              
              if (!mounted) return;
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation de la Commande'),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Traitement du paiement en cours...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total à payer :',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${widget.cart.totalAmount.toStringAsFixed(2)} KES / Ar',
                              style: const TextStyle(
                                fontSize: 20, 
                                fontWeight: FontWeight.bold, 
                                color: Colors.green
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text('Informations de livraison', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Entrez votre nom' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Adresse de livraison',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Entrez l\'adresse de livraison' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: _selectedMethod == PaymentMethod.mpesa
                            ? 'Téléphone M-Pesa (ex: 0712345678)'
                            : _selectedMethod == PaymentMethod.mvola
                                ? 'Téléphone MVola (ex: 0341234567)'
                                : 'Téléphone de contact',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Entrez le numéro de téléphone' : null,
                    ),
                    const SizedBox(height: 24),

                    const Text('Mode de Paiement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    RadioGroup<PaymentMethod>(
                      groupValue: _selectedMethod,
                      onChanged: (PaymentMethod? val) {
                        if (val != null) {
                          setState(() => _selectedMethod = val);
                        }
                      },
                      child: Column(
                        children: [
                          ListTile(
                            title: const Text('M-Pesa (Kenya / STK Push)'),
                            subtitle: const Text('Notification automatique sur votre téléphone'),
                            leading: Radio<PaymentMethod>(
                              value: PaymentMethod.mpesa,
                            ),
                          ),
                          ListTile(
                            title: const Text('MVola (Madagascar / Telma)'),
                            subtitle: const Text('Paiement direct via MVola API'),
                            leading: Radio<PaymentMethod>(
                              value: PaymentMethod.mvola,
                            ),
                          ),
                          ListTile(
                            title: const Text('Paiement à la livraison'),
                            subtitle: const Text('Réglez en espèces à la réception'),
                            leading: Radio<PaymentMethod>(
                              value: PaymentMethod.cashOnDelivery,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _processCheckout,
                        child: Text(
                          _selectedMethod == PaymentMethod.cashOnDelivery
                              ? 'Confirmer la commande'
                              : 'Payer maintenant',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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