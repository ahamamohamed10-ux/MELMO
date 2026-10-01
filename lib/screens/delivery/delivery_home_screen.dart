import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'delivery_detail_screen.dart';

class DeliveryHomeScreen extends StatelessWidget {
  const DeliveryHomeScreen({super.key});

  Future<void> _acceptOrder(BuildContext context, String orderId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'deliveryUid': currentUser.uid,
        'status': 'En cours',
      });

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande acceptée ! Retrouvez-la dans "Mes livraisons".')),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Espace Livreur'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => FirebaseAuth.instance.signOut(),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Disponibles', icon: Icon(Icons.list_alt)),
              Tab(text: 'Mes Livraisons', icon: Icon(Icons.directions_bike)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // 1. Liste des commandes "En attente"
            _buildOrderList(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('status', isEqualTo: 'En attente')
                  .snapshots(),
              isAvailableList: true,
            ),
            // 2. Liste des commandes de ce livreur "En cours"
            _buildOrderList(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('deliveryUid', isEqualTo: currentUser?.uid)
                  .where('status', isEqualTo: 'En cours')
                  .snapshots(),
              isAvailableList: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList({required Stream<QuerySnapshot> stream, required bool isAvailableList}) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              isAvailableList
                  ? 'Aucune commande disponible.'
                  : 'Aucune livraison en cours.',
            ),
          );
        }

        final orders = snapshot.data!.docs;

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final orderDoc = orders[index];
            final data = orderDoc.data() as Map<String, dynamic>;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(
                  data['customerName'] ?? 'Client inconnu',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Adresse: ${data['deliveryAddress'] ?? 'N/A'}\nMontant: ${data['amount'] ?? 0} KMF'),
                isThreeLine: true,
                trailing: isAvailableList
                    ? ElevatedButton(
                        onPressed: () => _acceptOrder(context, orderDoc.id),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('Accepter'),
                      )
                    : IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeliveryDetailScreen(orderId: orderDoc.id),
                            ),
                          );
                        },
                      ),
              ),
            );
          },
        );
      },
    );
  }
}