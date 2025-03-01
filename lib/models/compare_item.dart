import 'package:cloud_firestore/cloud_firestore.dart';

class CompareItem {
  String id;
  String brand;
  String name;
  double totalPrice;
  double quantity; // e.g. liters, kg

  CompareItem({
    required this.id,
    required this.brand,
    required this.name,
    required this.totalPrice,
    required this.quantity,
  });

  double get unitPrice => totalPrice / quantity;

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'name': name,
      'totalPrice': totalPrice,
      'quantity': quantity,
    };
  }

  factory CompareItem.fromDocument(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CompareItem(
      id: doc.id,
      brand: data['brand'] ?? '',
      name: data['name'] ?? '',
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      quantity: (data['quantity'] ?? 1).toDouble(),
    );
  }
}
