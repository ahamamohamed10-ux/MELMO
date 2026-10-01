import './product.dart';

class OrderItem {
  final String id;
  final double totalAmount;
  final List<Product> products;
  final DateTime dateTime;
  final String status;
  
  // Nouveaux champs pour la livraison
  final String customerName;
  final String deliveryAddress;
  final String deliveryOtp;
  final String? deliveryUid;
  final String? proofOfDeliveryUrl;

  OrderItem({
    required this.id,
    required this.totalAmount,
    required this.products,
    required this.dateTime,
    this.status = 'En attente',
    required this.customerName,
    required this.deliveryAddress,
    required this.deliveryOtp,
    this.deliveryUid,
    this.proofOfDeliveryUrl,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data, String docId) {
    return OrderItem(
      id: docId,
      totalAmount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'En attente',
      dateTime: data['dateTime'] != null
          ? DateTime.parse(data['dateTime'])
          : DateTime.now(),
      customerName: data['customerName'] ?? 'Client inconnu',
      deliveryAddress: data['deliveryAddress'] ?? 'Adresse non spécifiée',
      deliveryOtp: data['deliveryOtp'] ?? '',
      deliveryUid: data['deliveryUid'],
      proofOfDeliveryUrl: data['proofOfDeliveryUrl'],
      products: (data['products'] as List? ?? []).map((item) {
        return Product(
          id: item['id'] ?? '',
          title: item['title'] ?? '',
          price: (item['price'] as num?)?.toDouble() ?? 0.0,
          description: '', 
          category: 'Divers',
          collection: item['collection'] ?? 'Divers',
          images: [],
        );
      }).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': totalAmount,
      'status': status,
      'dateTime': dateTime.toIso8601String(),
      'customerName': customerName,
      'deliveryAddress': deliveryAddress,
      'deliveryOtp': deliveryOtp,
      'deliveryUid': deliveryUid,
      'proofOfDeliveryUrl': proofOfDeliveryUrl,
      'products': products.map((p) => {
        'id': p.id,
        'title': p.title,
        'price': p.price,
        'collection': p.collection,
      }).toList(),
    };
  }
}