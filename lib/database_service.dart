import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Key ImgBB API
  final String _imgBBKey = '4e6ee70986d4cefe4d3ec35327ac2b54';

  /// Uploads a single image to ImgBB using byte stream or file path
  Future<String?> uploadImage(dynamic imageFile) async {
    try {
      final uri = Uri.parse('https://api.imgbb.com/1/upload?key=$_imgBBKey');
      final request = http.MultipartRequest('POST', uri);

      if (imageFile is String) {
        request.files.add(await http.MultipartFile.fromPath('image', imageFile));
      } else if (imageFile is Uint8List) {
        request.files.add(http.MultipartFile.fromBytes('image', imageFile, filename: 'upload.jpg'));
      } else {
        // Fallback for dart:io File path extraction via dynamic access
        request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      }

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);
        return jsonResponse['data']['url'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint("Erreur ImgBB : $e");
      return null;
    }
  }

  /// Uploads multiple images concurrently in parallel for better performance
  Future<List<String>> uploadMultipleImages(List<dynamic> imageFiles) async {
    try {
      final uploadFutures = imageFiles.map((file) => uploadImage(file));
      final results = await Future.wait(uploadFutures);
      return results.whereType<String>().toList();
    } catch (e) {
      debugPrint("Erreur upload multiple : $e");
      return [];
    }
  }

  /// Adds a new product document to Firestore
  Future<void> addProduct({
    required String name,
    required double price,
    required String description,
    required List<String> imageUrls,
    required String collection, // <-- Ajouté
    required String category,
    List<String> colors = const [],
    List<String> sizes = const [],
    required double shippingFee,
    required String deliveryTime,
  }) async {
    try {
      await _db.collection('products').add({
        'title': name,
        'name': name,
        'price': price,
        'description': description,
        'images': imageUrls.isNotEmpty ? imageUrls : ['https://via.placeholder.com/150'],
        'collection': collection, // <-- Ajouté
        'category': category,
        'colors': colors,
        'sizes': sizes,
        'shippingFee': shippingFee,
        'deliveryTime': deliveryTime,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Erreur Firestore (addProduct) : $e");
      rethrow;
    }
  }

  /// Adds a review/comment under the product's 'reviews' subcollection
  Future<void> addComment({
    required String productId,
    required String userId,
    required String userName,
    required String commentText,
    required double rating,
  }) async {
    try {
      await _db
          .collection('products')
          .doc(productId)
          .collection('reviews')
          .add({
        'userId': userId,
        'userName': userName,
        'comment': commentText,
        'rating': rating,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Erreur ajout commentaire : $e");
      rethrow;
    }
  }

  /// Real-time stream of product reviews
  Stream<QuerySnapshot> getComments(String productId) {
    return _db
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Real-time stream of product catalog
  Stream<QuerySnapshot> getProducts() {
    return _db.collection('products').orderBy('createdAt', descending: true).snapshots();
  }
}