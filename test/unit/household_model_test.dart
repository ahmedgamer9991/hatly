import 'package:flutter_test/flutter_test.dart';
import 'package:hatly/features/household/domain/household_model.dart';

void main() {
  group('HouseholdModel Unit Tests', () {
    test('HouseholdModel.fromMap correctly parses subgroups and members', () {
      final now = DateTime.now();
      final map = {
        'name': 'عائلة الصباح',
        'inviteCode': 'HAT-9X82-K4',
        'adminId': 'ADMIN_1',
        'createdAt': now,
        'memberIds': ['ADMIN_1', 'SON_1', 'SON_2'],
        'pendingUserIds': ['PENDING_1'],
        'subgroups': {
          'Parents': ['ADMIN_1'],
          'Sons': ['SON_1', 'SON_2'],
        },
      };

      final household = HouseholdModel.fromMap(map, 'HH_777');

      expect(household.id, equals('HH_777'));
      expect(household.name, equals('عائلة الصباح'));
      expect(household.inviteCode, equals('HAT-9X82-K4'));
      expect(household.memberIds.length, equals(3));
      expect(household.pendingUserIds.length, equals(1));
      expect(household.subgroups['Sons'], containsAll(['SON_1', 'SON_2']));
    });
  });
}
