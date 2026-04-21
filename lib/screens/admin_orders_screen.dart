import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  bool _isAuthorized = false;
  final TextEditingController _pinController = TextEditingController();
  final String _adminPin = "1806"; 
 
  void _checkPin() {
    if (_pinController.text == _adminPin) {
      setState(() => _isAuthorized = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Code PIN incorrect"), 
          backgroundColor: Colors.red,
        ),
      );
      _pinController.clear();
    }
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': newStatus});
    } catch (e) {
      debugPrint("Erreur : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthorized) {
      return _buildLockScreen();
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestion MoMart'),
          backgroundColor: Colors.red.shade800,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => setState(() => _isAuthorized = false),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.shopping_bag), text: "Ventes"),
              Tab(icon: Icon(Icons.inventory), text: "Stocks"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrdersList(),   
            _buildProductsList(), 
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('dateTime', descending: true)
          .snapshots(),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final orders = snapshot.data!.docs;

        if (orders.isEmpty) {
          return const Center(child: Text("Aucune commande pour le moment"));
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (ctx, i) {
            final order = orders[i];
            final data = order.data() as Map<String, dynamic>;
            
            String formattedDate = "Date inconnue";
            if (data['dateTime'] != null) {
              try {
                formattedDate = DateFormat('dd/MM/yyyy HH:mm')
                    .format(DateTime.parse(data['dateTime']));
              } catch (e) {
                formattedDate = "Format invalide";
              }
            }

            return Card(
              margin: const EdgeInsets.all(10),
              elevation: 3,
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      'Client: ${data['customerName'] ?? 'Inconnu'}', 
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('Total: ${data['amount']} €\n$formattedDate'),
                    trailing: Chip(
                      label: Text(
                        data['status'] ?? 'En attente', 
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: _getStatusColor(data['status']),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextButton.icon(
                          onPressed: () => _updateStatus(order.id, 'Expédié'), 
                          icon: const Icon(Icons.local_shipping, size: 20), 
                          label: const Text("Expédier"),
                        ),
                        TextButton.icon(
                          onPressed: () => _updateStatus(order.id, 'Livré'), 
                          icon: const Icon(Icons.check_circle, size: 20), 
                          label: const Text("Livré"),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red), 
                          onPressed: () => _confirmDelete(order.id, 'orders'),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (ctx, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final products = snapshot.data!.docs;

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (ctx, i) {
            final prod = products[i];
            final data = prod.data() as Map<String, dynamic>;
            
            String? imageUrl;
            if (data['images'] != null && (data['images'] as List).isNotEmpty) {
              imageUrl = data['images'][0];
            } else if (data['imageUrl'] != null) {
              imageUrl = data['imageUrl'];
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: imageUrl != null 
                    ? Image.network(
                        imageUrl, 
                        width: 50, 
                        height: 50, 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                      )
                    : const Icon(Icons.image_not_supported, size: 40),
                ),
                title: Text(data['title'] ?? 'Sans nom', maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  "${data['price']} €", 
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editProductPrice(prod.id, (data['price'] ?? 0).toDouble()),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(prod.id, 'products'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editProductPrice(String id, double oldPrice) {
    final controller = TextEditingController(text: oldPrice.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Changer le prix"),
        content: TextField(
          controller: controller, 
          keyboardType: const TextInputType.numberWithOptions(decimal: true), 
          decoration: const InputDecoration(suffixText: "€", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                FirebaseFirestore.instance.collection('products').doc(id).update({
                  'price': double.parse(controller.text)
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text("Mettre à jour"),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id, String collection) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Voulez-vous vraiment supprimer cet élément ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection(collection).doc(id).delete();
              Navigator.pop(ctx);
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == 'Expédié') return Colors.blue.shade100;
    if (status == 'Livré') return Colors.green.shade200;
    return Colors.orange.shade100;
  }

  Widget _buildLockScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png', height: 120),
                const SizedBox(height: 30),
                const Text(
                  "ADMINISTRATION", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: _pinController, 
                  obscureText: true, 
                  keyboardType: TextInputType.number, 
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 10),
                  decoration: const InputDecoration(
                    hintText: "****",
                    hintStyle: TextStyle(letterSpacing: 10, color: Colors.grey),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity, 
                  height: 55, 
                  child: ElevatedButton(
                    onPressed: _checkPin, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black, 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ), 
                    child: const Text(
                      "DÉVERROUILLER", 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
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
