import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
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
  String? _profileImageUrl; // Stocke l'URL de l'image ImgBB
  
  final String adminEmail = "ahamamohamed10@gmail.com"; 
  User? get user => FirebaseAuth.instance.currentUser;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;
    try {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          _nameController.text = doc.data()?['name'] ?? '';
          _phoneController.text = doc.data()?['phone'] ?? '';
          _addressController.text = doc.data()?['address'] ?? '';
          _profileImageUrl = doc.data()?['photoUrl']; // On récupère l'image enregistrée
        });
      }
    } catch (e) {
      debugPrint("Erreur de chargement : $e");
    }
  }

  // --- NOUVELLE FONCTION : IMAGE PICKER + IMGBB ---
  Future<void> _pickAndUploadImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile == null) return;

    setState(() => _isSaving = true);

    try {
      // 1. Préparation de l'envoi vers ImgBB
      const String apiKey = "4e6ee70986d4cefe4d3ec35327ac2b54"; // 🔑 METS TA CLÉ ICI
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey'),
      );
      request.files.add(await http.MultipartFile.fromPath('image', pickedFile.path));

      // 2. Envoi
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);
        String newImageUrl = json['data']['url'];

        // 3. Sauvegarde de l'URL dans Firestore
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
          'photoUrl': newImageUrl,
        });

        setState(() {
          _profileImageUrl = newImageUrl;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo mise à jour avec succès !')),
          );
        }
      }
    } catch (e) {
      debugPrint("Erreur upload ImgBB : $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || user == null) return;
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'email': user!.email,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil MoMart mis à jour !'),
          backgroundColor: Color(0xFFD4AF37),
        ),
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
    final bool isAdmin = user?.email == adminEmail;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFFD4AF37),
                          child: CircleAvatar(
                            radius: 47,
                            backgroundColor: Colors.white,
                            // Affiche l'image ImgBB si elle existe, sinon l'icône grise
                            backgroundImage: _profileImageUrl != null 
                                ? NetworkImage(_profileImageUrl!) 
                                : null,
                            child: _profileImageUrl == null 
                                ? const Icon(Icons.person, size: 50, color: Colors.grey) 
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isSaving ? null : _pickAndUploadImage, // CLIC ICI
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                              child: _isSaving 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(user?.email ?? "", style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              const Text("Informations Personnelles", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              _buildTextField(
                controller: _nameController,
                label: "Nom Complet",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _phoneController,
                label: "Téléphone",
                icon: Icons.phone_android,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _addressController,
                label: "Adresse de livraison",
                icon: Icons.location_on_outlined,
                maxLines: 2,
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 2,
                  ),
                  child: _isSaving 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('ENREGISTRER LES MODIFICATIONS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 35),
              const Text("Paramètres & Sécurité", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              _buildMenuTile(
                icon: Icons.shopping_bag_outlined,
                title: "Mes commandes",
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const OrdersScreen())),
              ),
              
              _buildThemeSwitch(themeProvider),

              if (isAdmin) ...[
                const SizedBox(height: 10),
                _buildMenuTile(
                  icon: Icons.admin_panel_settings,
                  title: "Panel Administrateur",
                  subtitle: "Gérer MoMart",
                  color: Colors.red.shade700,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const AdminOrdersScreen())),
                ),
              ],
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS DE STYLE (Gardés tels quels) ---

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFD4AF37)),
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }

  Widget _buildThemeSwitch(ThemeProvider themeProvider) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
      child: SwitchListTile(
        title: const Text("Mode Sombre", style: TextStyle(fontWeight: FontWeight.w500)),
        secondary: const Icon(Icons.dark_mode_outlined),
        activeThumbColor: const Color(0xFFD4AF37),
        value: themeProvider.isDarkMode,
        onChanged: (val) => themeProvider.toggleTheme(),
      ),
    );
  }
}