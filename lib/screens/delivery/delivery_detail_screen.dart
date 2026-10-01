import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class DeliveryDetailScreen extends StatefulWidget {
  final String orderId;

  const DeliveryDetailScreen({super.key, required this.orderId});

  @override
  State<DeliveryDetailScreen> createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  final TextEditingController _otpController = TextEditingController();
  File? _proofImage;
  bool _isLoading = false;

  // Prendre une photo de preuve avec la caméra
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _proofImage = File(pickedFile.path);
      });
    }
  }

  // Valider la livraison (OTP + Upload Image + Mise à jour Firestore)
  Future<void> _completeDelivery(String expectedOtp) async {
    if (_otpController.text.trim() != expectedOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code OTP incorrect. Demandez le code à 4 chiffres au client.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez prendre une photo comme preuve de livraison.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Televerser l'image sur Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('delivery_proofs')
          .child('${widget.orderId}.jpg');

      await ref.putFile(_proofImage!);
      final imageUrl = await ref.getDownloadURL();

      // 2. Mettre a jour la commande dans Firestore
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'status': 'Livré',
        'proofOfDeliveryUrl': imageUrl,
        'deliveredAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Livraison validée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context); // Retour a l'ecran principal livreur
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la validation : $e')),
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
        title: const Text('Détails de la Livraison'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Commande introuvable.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String expectedOtp = data['deliveryOtp'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Client & Adresse
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Client : ${data['customerName'] ?? 'N/A'}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Adresse : ${data['deliveryAddress'] ?? 'N/A'}'),
                        Text('Montant : ${data['amount'] ?? 0} KMF'),
                        Text('Statut : ${data['status']}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Section Preuve de livraison (Photo)
                const Text(
                  '1. Preuve de livraison (Photo)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Center(
                  child: _proofImage != null
                      ? Image.file(_proofImage!, height: 180, fit: BoxFit.cover)
                      : Container(
                          height: 150,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Icon(Icons.camera_alt,
                              size: 50, color: Colors.grey),
                        ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Prendre une photo'),
                  ),
                ),
                const SizedBox(height: 20),

                // Section Code OTP
                const Text(
                  '2. Code de confirmation OTP',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: 'Entrez le code OTP du client',
                    border: OutlineInputBorder(),
                    hintText: 'Ex: 1234',
                  ),
                ),
                const SizedBox(height: 20),

                // Bouton de confirmation finale
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _completeDelivery(expectedOtp),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Valider et Terminer la livraison',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}