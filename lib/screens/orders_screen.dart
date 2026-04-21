import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes Commandes')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('dateTime', descending: true)
            .snapshots(),
        builder: (ctx, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Aucune commande trouvée.'));
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (ctx, i) {
              final orderData = orders[i].data() as Map<String, dynamic>;
              final List products = orderData['products'] as List;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: ExpansionTile(
                  title: Text(
                    'Total: ${orderData['amount'].toStringAsFixed(2)} €',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(orderData['dateTime'])),
                  ),
                  trailing: _buildStatusBadge(orderData['status'] ?? 'En attente'),
                  children: [
                    const Divider(),
                    ...products.map((prod) => ListTile(
                          title: Text(prod['title']),
                          trailing: Text('${prod['quantity']}x ${prod['price']} €'),
                        )),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'Expédié': color = Colors.blue; break;
      case 'Livré': color = Colors.green; break;
      default: color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
