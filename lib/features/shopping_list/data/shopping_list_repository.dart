import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/shopping_item_model.dart';
import '../domain/shopping_list_model.dart';

class ShoppingListRepository {
  final FirebaseFirestore firestore;

  ShoppingListRepository({required this.firestore});

  /// Create a new shopping list document in Firestore.
  Future<void> createList(ShoppingListModel list) async {
    final docRef = firestore.collection('shopping_lists').doc();
    final listWithId = list.copyWith(id: docRef.id);
    await docRef.set(listWithId.toMap());
  }

  /// Watch active shopping lists for a specific household in real-time.
  Stream<List<ShoppingListModel>> watchActiveHouseholdLists(String householdId) {
    return firestore
        .collection('shopping_lists')
        .where('householdId', isEqualTo: householdId)
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ShoppingListModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Watch completed/archived shopping lists for a specific household.
  Stream<List<ShoppingListModel>> watchCompletedHouseholdLists(String householdId) {
    return firestore
        .collection('shopping_lists')
        .where('householdId', isEqualTo: householdId)
        .where('status', isEqualTo: 'completed')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ShoppingListModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Watch an individual shopping list document in real-time.
  Stream<ShoppingListModel?> watchList(String listId) {
    return firestore
        .collection('shopping_lists')
        .doc(listId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return ShoppingListModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  /// Real-time update of an individual item status (pending / bought / outOfStock) and note.
  Future<void> updateItemStatus({
    required String listId,
    required String itemId,
    required String status,
    String? note,
  }) async {
    final docRef = firestore.collection('shopping_lists').doc(listId);
    final snapshot = await docRef.get();

    if (!snapshot.exists || snapshot.data() == null) return;

    final list = ShoppingListModel.fromMap(snapshot.data()!, snapshot.id);
    final updatedItems = list.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(
          status: status,
          note: note ?? item.note,
        );
      }
      return item;
    }).toList();

    await docRef.update({
      'items': updatedItems.map((i) => i.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Add a new item to an active shopping list in real-time.
  Future<void> addItemToList({
    required String listId,
    required ShoppingItemModel item,
  }) async {
    final docRef = firestore.collection('shopping_lists').doc(listId);
    final snapshot = await docRef.get();

    if (!snapshot.exists || snapshot.data() == null) return;

    final list = ShoppingListModel.fromMap(snapshot.data()!, snapshot.id);
    final updatedItems = List<ShoppingItemModel>.from(list.items)..add(item);

    await docRef.update({
      'items': updatedItems.map((i) => i.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove an item from an active shopping list in real-time.
  Future<void> removeItemFromList({
    required String listId,
    required String itemId,
  }) async {
    final docRef = firestore.collection('shopping_lists').doc(listId);
    final snapshot = await docRef.get();

    if (!snapshot.exists || snapshot.data() == null) return;

    final list = ShoppingListModel.fromMap(snapshot.data()!, snapshot.id);
    final updatedItems = list.items.where((i) => i.id != itemId).toList();

    await docRef.update({
      'items': updatedItems.map((i) => i.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Mark list as completed
  Future<void> completeList(String listId) async {
    await firestore.collection('shopping_lists').doc(listId).update({
      'status': 'completed',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a shopping list document from Firestore.
  Future<void> deleteList(String listId) async {
    await firestore.collection('shopping_lists').doc(listId).delete();
  }

  /// Reassign a shopping list to a new recipient or subgroup in real-time.
  Future<void> updateListAssignment({
    required String listId,
    required String assignedTo,
    required String assignedToName,
  }) async {
    await firestore.collection('shopping_lists').doc(listId).update({
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
