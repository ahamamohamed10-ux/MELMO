import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _colorsController = TextEditingController();
  final TextEditingController _sizesController = TextEditingController();
  final TextEditingController _shippingFeeController = TextEditingController(text: '0.00');
  final TextEditingController _deliveryTimeController = TextEditingController(text: '2 - 4 jours');
  final DatabaseService _db = DatabaseService();

  // Liste des collections exactes de ton onglet Catalogue
  final List<String> _collections = [
    'Women clothing',
    'Men clothing',
    'Vêtements pour enfants',
    'Handbag',
    'Home accessories',
    'Phones & gadgets',
  ];
  String _selectedCollection = 'Women clothing';

  // Liste des sous-catégories
  final List<String> _categories = [
    'Tout',
    'Robes',
    'Bijoux',
    'Écouteurs',
    'Téléphones',
    'Femmes accessoires',
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
    _colorsController.dispose();
    _sizesController.dispose();
    _shippingFeeController.dispose();
    _deliveryTimeController.dispose();
    super.dispose();
  }

  Future<void> _handlePublish() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez sélectionner au moins une photo pour l'article"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<String> parsingColors = [];
      if (_colorsController.text.isNotEmpty) {
        parsingColors = _colorsController.text
            .split(',')
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty)
            .toList();
      }

      List<String> parsingSizes = [];
      if (_sizesController.text.isNotEmpty) {
        parsingSizes = _sizesController.text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }

      List<String> links = await _db.uploadMultipleImages(_selectedImages);

      await _db.addProduct(
        name: _nameController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        description: _descController.text.trim(),
        imageUrls: links,
        collection: _selectedCollection,
        category: _selectedCategory,
        colors: parsingColors,
        sizes: parsingSizes,
        shippingFee: double.tryParse(_shippingFeeController.text) ?? 0.0,
        deliveryTime: _deliveryTimeController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Produit publié avec succès sur MoMart !"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur lors de la publication : $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Ajouter un article", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
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
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Nom de l'article", border: OutlineInputBorder()),
                  validator: (val) => val == null || val.isEmpty ? "Veuillez entrer un nom" : null,
                ),
                const SizedBox(height: 15),

                // Sélection de la Collection du Catalogue
                DropdownButtonFormField<String>(
                  initialValue: _selectedCollection,
                  decoration: const InputDecoration(
                    labelText: "Collection globale",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.collections, color: Color(0xFFD4AF37)),
                  ),
                  items: _collections.map((col) => DropdownMenuItem(value: col, child: Text(col))).toList(),
                  onChanged: (val) => setState(() => _selectedCollection = val!),
                ),
                const SizedBox(height: 15),

                // Sélection de la Sous-catégorie
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: "Catégorie spécifique",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category, color: Color(0xFFD4AF37)),
                  ),
                  items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val!),
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: "Prix (€)", border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                  validator: (val) => val == null || val.isEmpty ? "Veuillez entrer un prix" : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _colorsController,
                  decoration: const InputDecoration(
                    labelText: "Couleurs (ex: #FF0000, #000000, #FFFFFF)",
                    hintText: "Séparées par des virgules",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.color_lens, color: Color(0xFFD4AF37)),
                  ),
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _sizesController,
                  decoration: const InputDecoration(
                    labelText: "Tailles (ex: S, M, L, XL ou 40, 41, 42)",
                    hintText: "Séparées par des virgules",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.straighten, color: Color(0xFFD4AF37)),
                  ),
                ),
                const SizedBox(height: 15),

                // --- CHAMPS DE LIVRAISON ---
                TextFormField(
                  controller: _shippingFeeController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: "Frais de livraison (€)",
                    hintText: "0.00 pour livraison gratuite",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_shipping, color: Color(0xFFD4AF37)),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return "Veuillez indiquer les frais de livraison";
                    if (double.tryParse(val) == null) return "Veuillez entrer un prix valide";
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                TextFormField(
                  controller: _deliveryTimeController,
                  decoration: const InputDecoration(
                    labelText: "Délai de livraison estimé",
                    hintText: "Ex: 2 - 4 jours",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time, color: Color(0xFFD4AF37)),
                  ),
                  validator: (val) => val == null || val.isEmpty ? "Veuillez indiquer le délai de livraison" : null,
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
      ),
    );
  }
}