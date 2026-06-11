import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_auth/firebase_auth.dart'; // ✅ Requis pour la déconnexion
import 'admin_chat_screen.dart';
import 'add_product_screen.dart'; // ✅ Écran de création connecté

class AdminChatListScreen extends StatelessWidget {
  const AdminChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Discussions Clients", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        // =========================================================================
        // ✅ BOUTON DE RETOUR VERS LE PANEL PRINCIPAL
        // =========================================================================
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          tooltip: "Retour au panel",
          onPressed: (){
            Navigator.of(context).pop(); // Ferme la liste et retourne au Panel Admin
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('chats').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Aucune discussion en cours.", style: TextStyle(color: Colors.grey)),
            );
          }

          final chatDocs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chatDocs.length,
            itemBuilder: (context, index) {
              final chatData = chatDocs[index].data() as Map<String, dynamic>;
              final String clientEmail = chatData['clientEmail'] ?? 'Client Anonyme';
              final String lastMessage = chatData['lastMessage'] ?? 'Aucun message';

              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.black87, 
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(clientEmail, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminChatScreen(
                        clientId: chatDocs[index].id, 
                        clientEmail: clientEmail,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      // =========================================================================
      // BOUTON D'AJOUT DE PRODUIT (En bas à droite)
      // =========================================================================
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD4AF37), // Couleur Or MoMart
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () {
          // 1. On ouvre l'écran d'ajout de produit
          Navigator.of(context).push(
            MaterialPageRoute(builder: (ctx) => const AddProductScreen()),
          );

          // 2. Petit message de confirmation discret en bas
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Ouverture du formulaire d'ajout..."),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }
}