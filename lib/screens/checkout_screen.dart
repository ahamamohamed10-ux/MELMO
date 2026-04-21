import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  // Clé pour valider le formulaire
  final _formKey = GlobalKey<FormState>();
  
  // Variables pour stocker les saisies
  String _name = '';
  String _email = '';
  String _address = '';
  String _paymentMethod = 'Carte Bancaire';

  void _submitOrder() {
    // Vérification de la validité du formulaire
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // 1. On récupère le montant total avant de vider le panier
      final total = Provider.of<CartProvider>(context, listen: false).totalAmount;

      // 2. On vide le panier
      Provider.of<CartProvider>(context, listen: false).clear();

      // 3. Dialogue de confirmation utilisant toutes les variables
      showDialog(
        context: context,
        barrierDismissible: false, // Oblige à cliquer sur le bouton
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text('Commande validée !'),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                Text('Merci pour votre confiance, $_name !', 
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Text('Un récapitulatif de ${total.toStringAsFixed(2)} € a été envoyé à :'),
                Text(_email, style: const TextStyle(color: Colors.blue)),
                const SizedBox(height: 15),
                const Text('Adresse de livraison :'),
                Text(_address, style: const TextStyle(fontStyle: FontStyle.italic)),
                const SizedBox(height: 10),
                Text('Paiement par : $_paymentMethod'),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                // Retourne à l'écran principal (Home) et vide la pile de navigation
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Retour à la boutique'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finaliser la commande'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Vos informations',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Champ Nom
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nom complet',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) => (value == null || value.isEmpty) ? 'Veuillez entrer votre nom' : null,
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 15),

              // Champ Email
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Adresse Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || !value.contains('@')) return 'Email invalide (manque @)';
                  return null;
                },
                onSaved: (value) => _email = value!,
              ),
              const SizedBox(height: 15),

              // Champ Adresse
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Adresse de livraison',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) => (value == null || value.length < 10) ? 'Adresse trop courte' : null,
                onSaved: (value) => _address = value!,
              ),
              const SizedBox(height: 25),

              const Text(
                'Méthode de paiement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
  // Remplacement de 'value' par 'initialValue' pour suivre les standards 2026
  initialValue: _paymentMethod, 
  decoration: const InputDecoration(
    border: OutlineInputBorder(),
    prefixIcon: Icon(Icons.payment),
  ),
  items: ['Carte Bancaire', 'PayPal', 'Virement']
      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
      .toList(),
  onChanged: (val) {
    setState(() {
      _paymentMethod = val!;
    });
  },
),

              const SizedBox(height: 40),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _submitOrder,
                  child: const Text('Confirmer et Payer', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}