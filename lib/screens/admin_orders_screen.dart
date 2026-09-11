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

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

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
      debugPrint("Erreur lors de la mise à jour du statut : $e");
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

  /// Onglet 1 : Gestion des Ventes / Commandes
  Widget _buildOrdersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('dateTime', descending: true)
          .snapshots(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Aucune commande pour le moment"));
        }

        final orders = snapshot.data!.docs;

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (ctx, i) {
            final order = orders[i];
            final data = order.data() as Map<String, dynamic>;

            String formattedDate = "Date inconnue";
            if (data['dateTime'] != null) {
              try {
                final parsedDate = data['dateTime'] is Timestamp
                    ? (data['dateTime'] as Timestamp).toDate()
                    : DateTime.parse(data['dateTime'].toString());
                formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(parsedDate);
              } catch (_) {
                formattedDate = "Format invalide";
              }
            }

            final List items = data['items'] ?? [];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              elevation: 3,
              child: ExpansionTile(
                title: Text(
                  'Client: ${data['customerName'] ?? 'Inconnu'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Total: ${data['amount']} €\nDate: $formattedDate'),
                trailing: Chip(
                  label: Text(
                    data['status'] ?? 'En attente',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: _getStatusColor(data['status']),
                ),
                children: [
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Articles commandés :",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        ...items.map<Widget>((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "${item['quantity'] ?? 1}x ${item['title'] ?? 'Produit'}",
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ),
                                if (item['selectedSize'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Chip(
                                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                                      label: Text("Taille: ${item['selectedSize']}", style: const TextStyle(fontSize: 10)),
                                    ),
                                  ),
                                Text("${item['price'] ?? 0} €"),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
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
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Onglet 2 : Gestion des Produits et Stocks
  Widget _buildProductsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Aucun produit disponible"));
        }

        final products = snapshot.data!.docs;

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (ctx, i) {
            final prod = products[i];
            final data = prod.data() as Map<String, dynamic>;

            // 1. Titre du produit
            final String title = data['title'] ?? data['name'] ?? 'Sans nom';

            // 2. Extraire la liste 'sizes' en toute sécurité
            List<String> sizes = [];
            if (data['sizes'] != null) {
              if (data['sizes'] is List) {
                sizes = (data['sizes'] as List)
                    .map((e) => e.toString().trim().toUpperCase())
                    .where((e) => e.isNotEmpty)
                    .toList();
              }
            }

            // 3. Date de création (createdAt)
            String formattedDate = "";
            if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
              final DateTime date = (data['createdAt'] as Timestamp).toDate();
              formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
            }

            // 4. Image
            String? imageUrl;
            if (data['images'] != null && (data['images'] as List).isNotEmpty) {
              imageUrl = data['images'][0];
            } else if (data['imageUrl'] != null) {
              imageUrl = data['imageUrl'];
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: (imageUrl != null && imageUrl.isNotEmpty)
                        ? Image.network(
                            imageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 40),
                          )
                        : const Icon(Icons.image_not_supported, size: 40),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        "${data['price']} €",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // AFFICHAGE DES TAILLES (Rouge et très visible)
                      if (sizes.isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              "Tailles : ",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: sizes.map((size) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.red.shade400),
                                  ),
                                  child: Text(
                                    size,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade900,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        )
                      else
                        const Text(
                          "Pas de taille enregistrée",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                      // AFFICHAGE DE LA DATE
                      if (formattedDate.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          "Ajouté le : $formattedDate",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editProductPrice(
                          prod.id,
                          (data['price'] ?? 0).toDouble(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(prod.id, 'products'),
                      ),
                    ],
                  ),
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
          decoration: const InputDecoration(
            suffixText: "€",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              final newPrice = double.tryParse(controller.text);
              if (newPrice != null) {
                FirebaseFirestore.instance.collection('products').doc(id).update({
                  'price': newPrice,
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "DÉVERROUILLER",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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