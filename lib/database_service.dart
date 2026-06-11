import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Ta clé API ImgBB
  final String _imgBBKey = '4e6ee70986d4cefe4d3ec35327ac2b54'; 

  Future<String?> uploadImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload?key=$_imgBBKey'),
      );
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      var response = await request.send();
      
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseData);
        return jsonResponse['data']['url'];
      }
      return null;
    } catch (e) {
      debugPrint("Erreur ImgBB : $e");
      return null;
    }
  }

  Future<List<String>> uploadMultipleImages(List<File> imageFiles) async {
    List<String> urls = [];
    for (File file in imageFiles) {
      String? url = await uploadImage(file);
      if (url != null) urls.add(url);
    }
    return urls;
  }

  // --- MÉTHODE MISE À JOUR AVEC LE PARAMÈTRE COLORS ---
  Future<void> addProduct({
    required String name,
    required double price,
    required String description,
    required List<String> imageUrls,
    required String category,
    List<String> colors = const [], // <-- AJOUTÉ : Paramètre de liste optionnel (vide par défaut)
  }) async {
    try {
      await _db.collection('products').add({
        'title': name,
        'name': name,
        'price': price,
        'description': description,
        'images': imageUrls.isNotEmpty ? imageUrls : ['https://via.placeholder.com/150'],
        'category': category,
        'colors': colors, // <-- AJOUTÉ : Enregistrement de ta liste de variantes sur Firestore !
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Erreur Firestore : $e");
    }
  }

  Stream<QuerySnapshot> getProducts() {
    return _db.collection('products').orderBy('createdAt', descending: true).snapshots();
  }
}