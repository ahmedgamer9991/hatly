import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hatly/features/household/domain/category_model.dart';

void main() {
  group('CategoryModel Unit Tests', () {
    test('defaultCategories provides initial core categories', () {
      final defaults = CategoryModel.defaultCategories;
      expect(defaults.length, 5);
      expect(defaults.map((c) => c.id).toList(), [
        'supermarket',
        'pharmacy',
        'bakery',
        'butcher',
        'other',
      ]);
    });

    test('fromMap and toMap serialization roundtrip', () {
      final map = {
        'id': 'cat_veg_1',
        'name': 'Vegetables',
        'colorHex': '#10B981',
        'iconName': 'local_grocery_store',
      };

      final model = CategoryModel.fromMap(map);
      expect(model.id, 'cat_veg_1');
      expect(model.name, 'Vegetables');
      expect(model.colorHex, '#10B981');
      expect(model.iconName, 'local_grocery_store');

      final serialized = model.toMap();
      expect(serialized, map);
    });

    test('copyWith updates specified fields only', () {
      const model = CategoryModel(
        id: 'cat_1',
        name: 'Bakery',
        colorHex: '#FBBF24',
        iconName: 'bakery_dining',
      );

      final updated = model.copyWith(
        name: 'Fresh Bakery',
        colorHex: '#F59E0B',
      );

      expect(updated.id, 'cat_1');
      expect(updated.name, 'Fresh Bakery');
      expect(updated.colorHex, '#F59E0B');
      expect(updated.iconName, 'bakery_dining');
    });

    group('iconData exhaustiveness & fallback mapping', () {
      test('Maps supermarket / cart aliases to shopping_cart_rounded', () {
        for (final alias in ['shopping_cart', 'cart', 'supermarket']) {
          final cat = CategoryModel(
            id: '1',
            name: 'Test',
            colorHex: '',
            iconName: alias,
          );
          expect(cat.iconData, Icons.shopping_cart_rounded);
        }
      });

      test('Maps pharmacy aliases to local_pharmacy_rounded', () {
        for (final alias in ['local_pharmacy', 'pharmacy', 'medical_services', 'pill']) {
          final cat = CategoryModel(
            id: '1',
            name: 'Test',
            colorHex: '',
            iconName: alias,
          );
          expect(cat.iconData, Icons.local_pharmacy_rounded);
        }
      });

      test('Maps bakery aliases to bakery_dining_rounded', () {
        for (final alias in ['bakery_dining', 'bakery', 'cake', 'bread']) {
          final cat = CategoryModel(
            id: '1',
            name: 'Test',
            colorHex: '',
            iconName: alias,
          );
          expect(cat.iconData, Icons.bakery_dining_rounded);
        }
      });

      test('Maps butcher & meat aliases to restaurant_rounded', () {
        for (final alias in ['restaurant', 'butcher', 'meat', 'dining']) {
          final cat = CategoryModel(
            id: '1',
            name: 'Test',
            colorHex: '',
            iconName: alias,
          );
          expect(cat.iconData, Icons.restaurant_rounded);
        }
      });

      test('Maps grocery, clothes, fastfood, pet, sports, florist correctly', () {
        expect(
          const CategoryModel(id: '1', name: 'T', colorHex: '', iconName: 'pets').iconData,
          Icons.pets_rounded,
        );
        expect(
          const CategoryModel(id: '1', name: 'T', colorHex: '', iconName: 'cleaning').iconData,
          Icons.cleaning_services_rounded,
        );
        expect(
          const CategoryModel(id: '1', name: 'T', colorHex: '', iconName: 'snacks').iconData,
          Icons.fastfood_rounded,
        );
        expect(
          const CategoryModel(id: '1', name: 'T', colorHex: '', iconName: 'clothes').iconData,
          Icons.shopping_bag_rounded,
        );
        expect(
          const CategoryModel(id: '1', name: 'T', colorHex: '', iconName: 'sports').iconData,
          Icons.sports_soccer_rounded,
        );
        expect(
          const CategoryModel(id: '1', name: 'T', colorHex: '', iconName: 'florist').iconData,
          Icons.local_florist_rounded,
        );
      });

      test('Falls back securely to category_rounded on unrecognized or empty icon string', () {
        const unknownCat = CategoryModel(
          id: '1',
          name: 'Custom',
          colorHex: '',
          iconName: 'unrecognized_custom_icon_99',
        );
        expect(unknownCat.iconData, Icons.category_rounded);

        const emptyCat = CategoryModel(
          id: '2',
          name: 'Custom',
          colorHex: '',
          iconName: '',
        );
        expect(emptyCat.iconData, Icons.category_rounded);
      });
    });
  });
}
