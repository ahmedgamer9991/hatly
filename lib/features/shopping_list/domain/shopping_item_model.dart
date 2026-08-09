class ShoppingItemModel {
  final String id;
  final String name;
  final String category; // 'Supermarket', 'Pharmacy', 'Bakery', 'Butcher', 'Other'
  final String status; // 'pending', 'bought', 'outOfStock'
  final String? note;

  const ShoppingItemModel({
    required this.id,
    required this.name,
    this.category = 'Supermarket',
    this.status = 'pending',
    this.note,
  });

  factory ShoppingItemModel.fromMap(Map<String, dynamic> map) {
    return ShoppingItemModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? 'Supermarket',
      status: map['status'] as String? ?? 'pending',
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'status': status,
      'note': note,
    };
  }

  ShoppingItemModel copyWith({
    String? id,
    String? name,
    String? category,
    String? status,
    String? note,
  }) {
    return ShoppingItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      status: status ?? this.status,
      note: note ?? this.note,
    );
  }
}
