import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  
  // Contrôleurs pour lier les données au profil MoMart
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  String _paymentMethod = 'Paiement à la livraison';

  @override
  void initState() {
    super.initState();
    _prefillUserInfo();
  }

  // Récupération automatique des infos du profil
  Future<void> _prefillUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _emailController.text = user.email ?? '';

    try {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists && mounted) {
        setState(() {
          _nameController.text = userDoc.data()?['name'] ?? '';
          _addressController.text = userDoc.data()?['address'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Erreur pré-remplissage : $e");
    }
  }

  // Soumission de la commande vers Firestore
  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isProcessing = true);
    final cart = Provider.of<CartProvider>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;

    try {
      // 1. Enregistrement dans la collection 'orders'
      await FirebaseFirestore.instance.collection('orders').add({
        'userId': user?.uid,
        'customerName': _nameController.text.trim(),
        'customerEmail': _emailController.text.trim(),
        'deliveryAddress': _addressController.text.trim(),
        'paymentMethod': _paymentMethod,
        'items': cart.items.values.map((item) => {
          'id': item.id,
          'title': item.title,
          'price': item.price,
          'quantity': item.quantity,
        }).toList(),
        'totalAmount': cart.totalAmount,
        'status': 'En attente',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Vider le panier
      final totalPaye = cart.totalAmount;
      cart.clear();

      // 3. Dialogue de succès
      if (mounted) {
        _showSuccessDialog(totalPaye);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la commande : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(double total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 50),
            SizedBox(height: 10),
            Text('Commande Validée !'),
          ],
        ),
        content: Text(
          'Merci pour votre confiance !\nVotre commande de ${total.toStringAsFixed(2)} € est en cours de préparation.',
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('RETOUR À LA BOUTIQUE', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Finaliser la commande', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isProcessing 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Où devons-nous livrer ?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  _buildInput(controller: _nameController, label: 'Nom complet', icon: Icons.person),
                  const SizedBox(height: 15),
                  _buildInput(controller: _emailController, label: 'Email de contact', icon: Icons.email, type: TextInputType.emailAddress),
                  const SizedBox(height: 15),
                  _buildInput(controller: _addressController, label: 'Adresse précise (Ville, Quartier...)', icon: Icons.location_on, lines: 3),
                  
                  const SizedBox(height: 30),
                  const Text('Mode de paiement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(
                    initialValue: _paymentMethod, // ✅ Corrigé : 'value' au lieu de 'initialValue'
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      prefixIcon: const Icon(Icons.account_balance_wallet, color: Color(0xFFD4AF37)),
                    ),
                    items: ['Paiement à la livraison', 'Mobile Money', 'Carte Bancaire']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (val) => setState(() => _paymentMethod = val!),
                  ),

                  // Espace de marge pour le scroll
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          
      // =========================================================================
      // BOUTON FIXE EN BAS (Bottom Sticky Bar)
      // =========================================================================
      bottomNavigationBar: _isProcessing 
        ? const SizedBox.shrink() // Cache le bouton si on charge la commande
        : Container(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 12),
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
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37), // Couleur Or MoMart
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                onPressed: _submitOrder,
                child: const Text(
                  'CONFIRMER MA COMMANDE', 
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    TextInputType type = TextInputType.text, 
    int lines = 1
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFD4AF37)),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'Veuillez remplir ce champ' : null,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}