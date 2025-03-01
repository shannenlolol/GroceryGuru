import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shopping_item.dart';
import '../models/compare_item.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser!.uid;

  // Save a shopping item
  Future<void> saveShoppingItem(ShoppingItem item) async {
    DocumentReference docRef = await _db
        .collection('users')
        .doc(userId)
        .collection('shoppingItems')
        .add(item.toMap());

    //  Fix: Update the item to include the Firestore-generated ID
    await docRef.update({'id': docRef.id});
  }

  // Get shopping items (stream)
  Stream<List<ShoppingItem>> streamShoppingItems() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('shoppingItems')
        .snapshots()
        .map((snapshot) {
      print(" Firestore Data Count: ${snapshot.docs.length}"); //  Debug print
      if (snapshot.docs.isEmpty) {
        print("Firestore returned EMPTY data!");
      }

      return snapshot.docs.map((doc) {
        final data = doc.data();
        print("Raw Firestore Doc Data: $data"); //  Debug print

        final item = ShoppingItem.fromDocument(doc);
        print("Parsed ShoppingItem: ${item.toMap()}"); //  Debug print
        return item;
      }).toList();
    });
  }

  //  Update shopping item (edit name & category)
  Future<void> updateShoppingItemDetails(
      String docId, String newName, String newCategory) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('shoppingItems')
        .doc(docId)
        .update({
      'name': newName,
      'category': newCategory,
    });
  }

  //  Update shopping item checkbox (isChecked)
  Future<void> updateShoppingItem(String docId, bool isChecked) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('shoppingItems')
        .doc(docId)
        .update({'isChecked': isChecked});
  }

  //  Delete a shopping item
  Future<void> deleteShoppingItem(String docId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('shoppingItems')
        .doc(docId)
        .delete();
  }

  // Save compare item
// Save a compare item under the correct item group
  Future<void> saveCompareItem(CompareItem item) async {
    final groupRef = _db
        .collection('users')
        .doc(userId)
        .collection('comparisonGroups')
        .doc(item.name);

    //  Ensure the group document exists by adding a placeholder field
    await groupRef.set({'exists': true}, SetOptions(merge: true));

    final docRef = await groupRef.collection('items').add(item.toMap());

    await docRef.update({'id': docRef.id});

    print(" Saved CompareItem: ${item.toMap()} under ${item.name}");
  }

// Get comparison groups (items grouped under their names)
  Stream<Map<String, List<CompareItem>>> streamCompareItems() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('comparisonGroups')
        .snapshots()
        .asyncMap((snapshot) async {
      Map<String, List<CompareItem>> groupedItems = {};

      for (var doc in snapshot.docs) {
        final itemsSnapshot =
            await doc.reference.collection('items').snapshots().first;

        print("Firestore Group Found: ${doc.id}");
        print(" Items in Group: ${itemsSnapshot.docs.length}");

        groupedItems[doc.id] = itemsSnapshot.docs.map((itemDoc) {
          print("Item Data: ${itemDoc.data()}");
          return CompareItem.fromDocument(itemDoc);
        }).toList();
      }

      print(" Final Loaded Comparison Groups: ${groupedItems.keys.toList()}");
      return groupedItems;
    });
  }

  Future<void> deleteCompareItem(String itemName, String itemId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('comparisonGroups')
        .doc(itemName)
        .collection('items')
        .doc(itemId)
        .delete();

    print("Deleted CompareItem: $itemId under $itemName");
  }

//  Update an existing comparison item
  Future<void> updateCompareItem(
      String oldItemName,
      String itemId,
      String newItemName,
      String brand,
      double totalPrice,
      double quantity) async {
    if (oldItemName != newItemName) {
      //  Move item to new group (delete from old, add to new)
      await deleteCompareItem(oldItemName, itemId);
      final newItem = CompareItem(
        id: '',
        brand: brand,
        name: newItemName,
        totalPrice: totalPrice,
        quantity: quantity,
      );
      await saveCompareItem(newItem);
    } else {
      //  Just update details in the same group
      await _db
          .collection('users')
          .doc(userId)
          .collection('comparisonGroups')
          .doc(oldItemName)
          .collection('items')
          .doc(itemId)
          .update({
        'brand': brand,
        'totalPrice': totalPrice,
        'quantity': quantity,
      });
    }

    print("✏️ Updated CompareItem: $itemId (Now under $newItemName)");
  }

  Future<void> deleteComparisonGroup(String itemName) async {
    final groupRef = _db
        .collection('users')
        .doc(userId)
        .collection('comparisonGroups')
        .doc(itemName);

    final itemsSnapshot = await groupRef.collection('items').get();

    //  Delete all items in the group first
    for (var doc in itemsSnapshot.docs) {
      await doc.reference.delete();
    }

    //  Now delete the comparison group itself
    await groupRef.delete();

    print("Deleted Comparison Group: $itemName and all its items");
  }
}
