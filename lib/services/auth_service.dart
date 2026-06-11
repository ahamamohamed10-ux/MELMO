import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsign;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // ✅ Instanciation dynamique pure
  final dynamic _googleSignIn = gsign.GoogleSignIn();

  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      final dynamic googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final dynamic googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        if (!context.mounted) return userCredential;

        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName ?? 'Utilisateur MELMO',
          'role': 'client', 
          'createdAt': FieldValue.serverTimestamp(),
          'phoneNumber': user.phoneNumber ?? '',
        }, SetOptions(merge: true));
      }

      return userCredential;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur de connexion Google : $e")),
        );
      }
      return null;
    }
  }
}