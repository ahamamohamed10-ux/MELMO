import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_chat_list_screen.dart';
import 'add_product_screen.dart';
import 'admin_orders_screen.dart'; // Tu as déjà ce fichier dans tes dossiers !

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          "Panel Administrateur",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            // 1. Bouton Gestion des Messages
            _buildMenuCard(
              context,
              title: "Discussions",
              icon: Icons.chat_bubble_outline,
              color: Colors.blue,
              destination: const AdminChatListScreen(),
            ),
            // 2. Bouton Gestion des Commandes
            _buildMenuCard(
              context,
              title: "Commandes",
              icon: Icons.shopping_bag_outlined,
              color: const Color(0xFFD4AF37), // Couleur Or MoMart
              destination: const AdminOrdersScreen(),
            ),
            // 3. Bouton Ajouter un Produit
            _buildMenuCard(
              context,
              title: "Ajouter Produit",
              icon: Icons.add_box_outlined,
              color: Colors.green,
              destination: const AddProductScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (ctx) => destination),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black..withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}