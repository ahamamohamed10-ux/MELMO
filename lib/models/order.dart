import './product.dart';

class OrderItem {
  final String id;
  final double totalAmount;
  final List<Product> products;
  final DateTime dateTime;
  final String status;

  OrderItem({
    required this.id,
    required this.totalAmount,
    required this.products,
    required this.dateTime,
    this.status = 'En attente',
  });

  factory OrderItem.fromMap(Map<String, dynamic> data, String docId) {
    return OrderItem(
      id: docId,
      totalAmount: (data['amount'] as num).toDouble(),
      status: data['status'] ?? 'En attente',
      dateTime: DateTime.parse(data['dateTime']),
      products: (data['products'] as List).map((item) {
        return Product(
          id: item['id'],
          title: item['title'],
          price: (item['price'] as num).toDouble(),
          description: '', 
          category: 'Divers',
          images: [], // On utilise la liste vide car ton modèle Product attend 'images'
        );
      }).toList(),
    );
  }
}