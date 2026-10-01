import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsign;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Instanciation de GoogleSignIn
  final dynamic _googleSignIn = gsign.GoogleSignIn();

  Future<UserCredential?> signInWithGoogle(BuildContext context) async {
    try {
      final dynamic googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // L'utilisateur a annulé la connexion

      final dynamic googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        if (!context.mounted) return userCredential;

        final userDocRef = _firestore.collection('users').doc(user.uid);
        final userDoc = await userDocRef.get();

        if (!userDoc.exists) {
          // Premier enregistrement : assignation du rôle 'client' par défaut
          await userDocRef.set({
            'uid': user.uid,
            'email': user.email ?? '',
            'name': user.displayName ?? 'Utilisateur MELMO',
            'role': 'client', // Rôle attribué uniquement lors du premier login
            'phone': user.phoneNumber ?? '',
            'address': '',
            'photoUrl': user.photoURL ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Si l'utilisateur existe déjà, on met à jour les infos sans toucher au 'role'
          await userDocRef.update({
            'email': user.email ?? '',
            'name': user.displayName ?? 'Utilisateur MELMO',
            'photoUrl': user.photoURL ?? '',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
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

  // Déconnexion
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}