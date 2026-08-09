import 'package:flutter_test/flutter_test.dart';
import 'package:hatly/features/shopping_list/domain/shopping_item_model.dart';
import 'package:hatly/features/shopping_list/domain/shopping_list_model.dart';

void main() {
  group('ShoppingListModel Unit Tests', () {
    test('ShoppingListModel serialization and item updates', () {
      final now = DateTime.now();
      final item1 = const ShoppingItemModel(
        id: 'ITEM_1',
        name: 'حليب',
        category: 'Supermarket',
        status: 'bought',
      );
      final item2 = const ShoppingItemModel(
        id: 'ITEM_2',
        name: 'بانادول',
        category: 'Pharmacy',
        status: 'pending',
      );

      final list = ShoppingListModel(
        id: 'LIST_100',
        householdId: 'HH_1',
        title: 'مشتريات كارفور',
        createdBy: 'MOTHER_UID',
        assignedTo: 'Sons',
        assignedToName: 'الأبناء / Sons',
        status: 'active',
        createdAt: now,
        updatedAt: now,
        items: [item1, item2],
      );

      expect(list.id, equals('LIST_100'));
      expect(list.items.length, equals(2));
      expect(list.assignedTo, equals('Sons'));

      final toMap = list.toMap();
      expect(toMap['title'], equals('مشتريات كارفور'));
      expect((toMap['items'] as List).length, equals(2));
    });
  });
}
