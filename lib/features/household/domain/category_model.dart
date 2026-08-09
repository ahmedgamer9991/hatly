import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String colorHex;
  final String iconName;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.iconName,
  });

  IconData get iconData {
    switch (iconName.toLowerCase()) {
      case 'shopping_cart':
      case 'cart':
      case 'supermarket':
        return Icons.shopping_cart_rounded;
      case 'local_pharmacy':
      case 'pharmacy':
      case 'medical_services':
      case 'pill':
        return Icons.local_pharmacy_rounded;
      case 'bakery_dining':
      case 'bakery':
      case 'cake':
      case 'bread':
        return Icons.bakery_dining_rounded;
      case 'restaurant':
      case 'butcher':
      case 'meat':
      case 'dining':
        return Icons.restaurant_rounded;
      case 'pets':
      case 'pet':
        return Icons.pets_rounded;
      case 'cleaning_services':
      case 'cleaning':
      case 'home':
        return Icons.cleaning_services_rounded;
      case 'fastfood':
      case 'snacks':
        return Icons.fastfood_rounded;
      case 'shopping_bag':
      case 'store':
      case 'clothes':
        return Icons.shopping_bag_rounded;
      case 'local_grocery_store':
      case 'grocery':
        return Icons.local_grocery_store_rounded;
      case 'sports':
      case 'fitness':
        return Icons.sports_soccer_rounded;
      case 'florist':
      case 'flower':
        return Icons.local_florist_rounded;
      case 'more_horiz':
      default:
        return Icons.category_rounded;
    }
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      colorHex: map['colorHex'] as String? ?? '#64DD91',
      iconName: map['iconName'] as String? ?? 'shopping_cart',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorHex': colorHex,
      'iconName': iconName,
    };
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? colorHex,
    String? iconName,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
    );
  }

  static List<CategoryModel> get defaultCategories => const [
        CategoryModel(
          id: 'supermarket',
          name: 'Supermarket',
          colorHex: '#64DD91',
          iconName: 'shopping_cart',
        ),
        CategoryModel(
          id: 'pharmacy',
          name: 'Pharmacy',
          colorHex: '#38BDF8',
          iconName: 'local_pharmacy',
        ),
        CategoryModel(
          id: 'bakery',
          name: 'Bakery',
          colorHex: '#FBBF24',
          iconName: 'bakery_dining',
        ),
        CategoryModel(
          id: 'butcher',
          name: 'Butcher',
          colorHex: '#F87171',
          iconName: 'restaurant',
        ),
        CategoryModel(
          id: 'other',
          name: 'Other',
          colorHex: '#CBD5E1',
          iconName: 'more_horiz',
        ),
      ];
}
