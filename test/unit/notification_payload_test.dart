import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Notification System Unit Tests', () {
    test('FCM Household topic sanitization strips invalid characters', () {
      String sanitizeTopic(String householdId) {
        return 'household_${householdId.replaceAll(RegExp(r'[^a-zA-Z0-9-_]'), '_')}';
      }

      expect(sanitizeTopic('house-123_abc'), 'household_house-123_abc');
      expect(sanitizeTopic('house@#\$%123!'), 'household_house____123_');
      expect(sanitizeTopic('my household name'), 'household_my_household_name');
    });

    test('Local notification deterministic ID generation stays within 32-bit positive integer range', () {
      int generateNotifId(String title, String body) {
        return ('$title:$body'.hashCode) & 0x7FFFFFFF;
      }

      final id1 = generateNotifId('New List', 'Groceries for Mom');
      final id2 = generateNotifId('New List', 'Groceries for Mom');
      final id3 = generateNotifId('Update List', 'Milk was bought');

      expect(id1, id2); // Consistent hash for same content
      expect(id1 >= 0, isTrue); // Positive integer
      expect(id1 <= 0x7FFFFFFF, isTrue); // Within 32-bit signed int max
      expect(id1 != id3, isTrue);
    });

    test('FCM v1 payload structure matches Google specs', () {
      Map<String, dynamic> buildMessagePayload({
        required String title,
        required String body,
        required String householdId,
        String? recipientToken,
        String? senderUid,
      }) {
        final Map<String, dynamic> messagePayload = {
          "notification": {
            "title": title,
            "body": body,
          },
          "data": {
            "title": title,
            "body": body,
            "senderUid": senderUid ?? "",
            "type": "shopping_update",
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
          },
          "android": {
            "priority": "HIGH",
            "direct_boot_ok": true,
            "notification": {
              "channel_id": "hatly_high_importance_channel",
              "sound": "default",
              "notification_priority": "PRIORITY_MAX",
            },
          },
        };

        if (recipientToken != null && recipientToken.isNotEmpty) {
          messagePayload["token"] = recipientToken;
        } else {
          final topic =
              'household_${householdId.replaceAll(RegExp(r'[^a-zA-Z0-9-_]'), '_')}';
          messagePayload["topic"] = topic;
        }

        return {"message": messagePayload};
      }

      // 1. Direct Token Payload
      final tokenPayload = buildMessagePayload(
        title: 'New List 🛒',
        body: 'Weekend Groceries',
        householdId: 'h1',
        recipientToken: 'fcm_token_xyz_123',
        senderUid: 'user_sender_99',
      );

      expect(tokenPayload['message']['token'], 'fcm_token_xyz_123');
      expect(tokenPayload['message']['topic'], isNull);
      expect(tokenPayload['message']['data']['senderUid'], 'user_sender_99');
      expect(tokenPayload['message']['android']['priority'], 'HIGH');
      expect(tokenPayload['message']['android']['direct_boot_ok'], isTrue);

      // JSON serializability check
      final encoded = jsonEncode(tokenPayload);
      expect(encoded.contains('"token":"fcm_token_xyz_123"'), isTrue);

      // 2. Topic Fallback Payload
      final topicPayload = buildMessagePayload(
        title: 'List Update',
        body: 'Apples bought',
        householdId: 'family-group-2026',
        recipientToken: null,
      );

      expect(topicPayload['message']['topic'], 'household_family-group-2026');
      expect(topicPayload['message']['token'], isNull);
    });
  });
}
