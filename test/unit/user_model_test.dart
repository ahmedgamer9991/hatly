import 'package:flutter_test/flutter_test.dart';
import 'package:hatly/features/auth/domain/user_model.dart';

void main() {
  group('UserModel Unit Tests', () {
    test('UserModel.fromMap and toMap roundtrip', () {
      final map = {
        'name': 'أم علي',
        'email': 'mother@example.com',
        'householdId': 'HH_123',
        'fcmToken': 'TOKEN_ABC',
      };

      final user = UserModel.fromMap(map, 'USER_99');

      expect(user.uid, equals('USER_99'));
      expect(user.name, equals('أم علي'));
      expect(user.email, equals('mother@example.com'));
      expect(user.householdId, equals('HH_123'));
      expect(user.fcmToken, equals('TOKEN_ABC'));

      final toMapResult = user.toMap();
      expect(toMapResult['uid'], equals('USER_99'));
      expect(toMapResult['name'], equals('أم علي'));
      expect(toMapResult['email'], equals('mother@example.com'));
      expect(toMapResult['householdId'], equals('HH_123'));
    });

    test('UserModel.copyWith updates specified fields', () {
      const original = UserModel(
        uid: 'USER_1',
        name: 'Ahmed',
        email: 'ahmed@example.com',
      );

      final updated = original.copyWith(householdId: 'NEW_HH');

      expect(updated.uid, equals('USER_1'));
      expect(updated.name, equals('Ahmed'));
      expect(updated.householdId, equals('NEW_HH'));
    });
  });
}
