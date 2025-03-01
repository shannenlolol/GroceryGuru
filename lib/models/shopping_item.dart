import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ShoppingItem {
  final String id;
  final String name;
  final String category;
  final bool isChecked;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.isChecked,
  });

  //  Fix: Ensure Firestore document ID is used
  factory ShoppingItem.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShoppingItem(
      id: doc.id, //  Ensure Firestore-generated ID is used
      name: data['name'] ?? '',
      category: data['category'] ?? '',
      isChecked: data['isChecked'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'isChecked': isChecked,
      'id': id
    };
  }
}
