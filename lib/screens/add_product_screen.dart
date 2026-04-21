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
  final DatabaseService _db = DatabaseService();

  final List<String> _categories = ['Tout', 'Boubous', 'Bijoux', 'Pantalons', 'Robes'];
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nom de l'article", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
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
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Prix (€)", border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _handlePublish, // Appel d'une fonction séparée
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

  // --- FONCTION DE PUBLICATION NETTOYÉE ---
  Future<void> _handlePublish() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir le nom et le prix")),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // 1. Opérations asynchrones (ImgBB + Firestore)
      List<String> links = await _db.uploadMultipleImages(_selectedImages);
      await _db.addProduct(
        name: _nameController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        description: _descController.text,
        imageUrls: links,
        category: _selectedCategory,
      );

      // 2. LA VÉRIFICATION CRITIQUE
      if (!mounted) return;

      // 3. ACTIONS UTILISANT LE CONTEXT (Navigator / SnackBar)
      // On les enchaîne immédiatement après le check 'mounted'
      setState(() => _isLoading = false);
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Produit publié !"), backgroundColor: Colors.green),
      );

    } catch (e) {
      // 4. GESTION D'ERREUR SÉCURISÉE
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e")),
      );
    }
  }
}
