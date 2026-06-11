import 'package:flutter/material.dart';
import 'dart:io'; 
import 'package:image_picker/image_picker.dart';
import '../database_service.dart'; 

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _colorsController = TextEditingController(); // <-- AJOUTÉ : Contrôleur pour les couleurs
  final DatabaseService _db = DatabaseService();

  final List<String> _categories = [
    'Tout', 'Vêtements pour femmes', 'Bijoux', 'Vêtements pour hommes', 
    'Robes', 'Vêtements pour enfants', 'Handbag', 'Home accessories', 
    'Phones & gadgets', 'Femmes accessoires'
  ];
  String _selectedCategory = 'Tout'; 

  List<File> _selectedImages = []; 
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _selectedImages = pickedFiles.map((xFile) => File(xFile.path)).toList();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _colorsController.dispose(); // <-- AJOUTÉ : Nettoyage du contrôleur
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Ajouter un article"),
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // --- LE CONTENEUR DE SÉLECTION D'IMAGES ---
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: _selectedImages.isNotEmpty
                      ? ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(_selectedImages[index], width: 140, fit: BoxFit.cover),
                              ),
                            );
                          },
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                            Text("Ajouter des photos", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              
              // --- CHAMP NOM ---
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nom de l'article", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              
              // --- SÉLECTEUR CATÉGORIE ---
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: "Catégorie",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category, color: Color(0xFFD4AF37)),
                ),
                items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 15),
              
              // --- CHAMP PRIX ---
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Prix (€)", border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              
              // --- CHAMP DESCRIPTION ---
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 15),

              // =========================================================================
              // NOUVEAU CHAMP ADJACENT : SAISIE DES COULEURS EN HEXADÉCIMAL
              // =========================================================================
              TextFormField(
                controller: _colorsController,
                decoration: InputDecoration(
                  labelText: "Couleurs disponibles (Codes Hex séparés par des virgules)",
                  hintText: "Ex: #000000, #FFFFFF, #D4AF37",
                  prefixIcon: const Icon(Icons.palette_outlined, color: Color(0xFFD4AF37)),
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                  ),
                ),
                keyboardType: TextInputType.text,
              ),
              // =========================================================================
              
              const SizedBox(height: 30),
              
              // --- BOUTON DE PUBLICATION ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _handlePublish,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Publier l'article", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- FONCTION DE PUBLICATION MODIFIÉE ---
  Future<void> _handlePublish() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir le nom et le prix")),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // 1. Découpage et formatage du texte des couleurs en List<String> propre
      List<String> parsingColors = [];
      if (_colorsController.text.isNotEmpty) {
        parsingColors = _colorsController.text
            .split(',')                     // Découpe à chaque virgule
            .map((c) => c.trim())           // Enlève les espaces inutiles autour du code
            .where((c) => c.isNotEmpty)     // Filtre les chaînes vides accidentelles
            .toList();
      }

      // 2. Opérations asynchrones (ImgBB + Firestore)
      List<String> links = await _db.uploadMultipleImages(_selectedImages);
      
      // Envoi des données à la base de données (Inclusion du paramètre colors)
      await _db.addProduct(
        name: _nameController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        description: _descController.text,
        imageUrls: links,
        category: _selectedCategory,
        colors: parsingColors, // <-- TRANSMISSION DE LA LISTE DE COULEURS
      );

      // 3. LA VÉRIFICATION CRITIQUE DU CONTEXT
      if (!mounted) return;

      // 4. ACTIONS DE SORTIE
      setState(() => _isLoading = false);
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Produit publié !"), backgroundColor: Colors.green),
      );

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }
}