import 'shopping_item_model.dart';

class ShoppingListModel {
  final String id;
  final String householdId;
  final String title;
  final String createdBy;
  final String assignedTo; // 'All', 'Sons', 'Parents', or userUid
  final String assignedToName; // Display target name
  final String status; // 'active', 'completed'
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ShoppingItemModel> items;

  const ShoppingListModel({
    required this.id,
    required this.householdId,
    required this.title,
    required this.createdBy,
    required this.assignedTo,
    required this.assignedToName,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  factory ShoppingListModel.fromMap(Map<String, dynamic> map, String id) {
    final rawItems = map['items'] as List? ?? [];
    final parsedItems = rawItems
        .map((e) => ShoppingItemModel.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return ShoppingListModel(
      id: id,
      householdId: map['householdId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      assignedTo: map['assignedTo'] as String? ?? 'All',
      assignedToName: map['assignedToName'] as String? ?? 'الجميع / All',
      status: map['status'] as String? ?? 'active',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is DateTime
              ? map['createdAt'] as DateTime
              : (map['createdAt'] as dynamic).toDate() as DateTime)
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is DateTime
              ? map['updatedAt'] as DateTime
              : (map['updatedAt'] as dynamic).toDate() as DateTime)
          : DateTime.now(),
      items: parsedItems,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'householdId': householdId,
      'title': title,
      'createdBy': createdBy,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'items': items.map((e) => e.toMap()).toList(),
    };
  }

  ShoppingListModel copyWith({
    String? id,
    String? householdId,
    String? title,
    String? createdBy,
    String? assignedTo,
    String? assignedToName,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ShoppingItemModel>? items,
  }) {
    return ShoppingListModel(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      title: title ?? this.title,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items ?? this.items,
    );
  }
}
