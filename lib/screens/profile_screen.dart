import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/theme_provider.dart';
import './orders_screen.dart';
import './admin_orders_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  
  // 🔑 VARIABLES DE SÉCURITÉ
  // On met le même email dans les deux pour que le bouton s'affiche pour toi
  final String adminEmail = "ahamamohamed10@gmail.com"; 
  final String currentUserEmail = "ahamamohamed10@gmail.com"; 

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // On récupère les infos de l'utilisateur (ici ID fixe 'user_1' pour ton test)
      var doc = await FirebaseFirestore.instance.collection('users').doc('user_1').get();
      if (doc.exists && mounted) {
        setState(() {
          _nameController.text = doc.data()?['name'] ?? '';
          _phoneController.text = doc.data()?['phone'] ?? '';
          _addressController.text = doc.data()?['address'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Erreur de chargement : $e");
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc('user_1').set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'email': currentUserEmail, // On stocke l'email pour la sécurité
        'updatedAt': Timestamp.now(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil MoMart mis à jour !')),
      );
    } catch (e) {
      debugPrint("Erreur de sauvegarde : $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const CircleAvatar(
                radius: 45,
                backgroundColor: Colors.orange,
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 25),
              
              // --- OPTIONS ---
              Card(
                child: SwitchListTile(
                  title: const Text('Mode Sombre'),
                  secondary: const Icon(Icons.dark_mode),
                  value: themeProvider.isDarkMode,
                  onChanged: (val) => themeProvider.toggleTheme(),
                ),
              ),
              const SizedBox(height: 20),
              
              // --- FORMULAIRE ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom Complet', 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (v) => v!.isEmpty ? 'Nom requis' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone', 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Adresse de livraison', 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 25),
              
              // --- BOUTON SAUVEGARDE ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('SAUVEGARDER LES INFOS', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              
              const Divider(height: 50),
              
              // --- HISTORIQUE ---
              ListTile(
                leading: const Icon(Icons.shopping_bag_outlined),
                title: const Text('Mes commandes'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const OrdersScreen()),
                  );
                },
              ),
              
              // 🛡️ ACCÈS ADMIN (Visible uniquement pour toi)
              if (currentUserEmail == adminEmail) ...[
                const SizedBox(height: 10),
                Card(
                  color: Colors.red.shade50,
                  child: ListTile(
                    leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
                    title: const Text(
                      'Panel Administrateur', 
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
                    ),
                    subtitle: const Text('Gérer les stocks et les ventes MoMart'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const AdminOrdersScreen()),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}