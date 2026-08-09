import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/firebase_providers.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(
    firestore: ref.watch(firebaseFirestoreProvider),
    messaging: ref.watch(firebaseMessagingProvider),
  );
});

class NotificationService {
  final FirebaseFirestore firestore;
  final FirebaseMessaging? messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationService({
    required this.firestore,
    this.messaging,
  });

  /// Initialize local notification channels & FCM permissions
  Future<void> initialize() async {
    try {
      // 1. Request Push Notification permissions on mobile if messaging is available
      if (messaging != null) {
        final settings = await messaging!.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        debugPrint('FCM Notification permission status: ${settings.authorizationStatus}');
      }

      // 2. Initialize Local Notifications Plugin
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings();

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
      );

      // Create high-importance Android Notification Channel
      const androidChannel = AndroidNotificationChannel(
        'hatly_high_importance_channel',
        'Hatly Shopping Notifications',
        description: 'Notifications for new and updated shopping lists.',
        importance: Importance.max,
      );

      final androidImpl = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImpl != null) {
        await androidImpl.createNotificationChannel(androidChannel);
        // Request runtime POST_NOTIFICATIONS permission on Android 13+
        await androidImpl.requestNotificationsPermission();
      }

      // 3. Listen to Foreground FCM Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          final notifId = message.messageId != null
              ? message.messageId.hashCode
              : (notification.title ?? '').hashCode;

          showLocalNotification(
            id: notifId & 0x7FFFFFFF,
            title: notification.title ?? 'Hatly Notification 🛒',
            body: notification.body ?? '',
          );
        }
      });
    } catch (e) {
      debugPrint('NotificationService initialize error: $e');
    }
  }

  /// Show a native system notification banner on the device (Deduplicated by ID)
  Future<void> showLocalNotification({
    int? id,
    required String title,
    required String body,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'hatly_high_importance_channel',
        'Hatly Shopping Notifications',
        channelDescription: 'Notifications for new and updated shopping lists.',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      final notifId = id ?? (('$title:$body'.hashCode) & 0x7FFFFFFF);

      await _localNotifications.show(
        id: notifId,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// Save FCM device token for user in Firestore and listen for token refreshes
  Future<void> saveUserFcmToken(String uid, {String? existingToken}) async {
    try {
      if (messaging != null) {
        final token = await messaging!.getToken();
        if (token != null && token.isNotEmpty && token != existingToken) {
          debugPrint('====================================================');
          debugPrint('🔑 DEVICE FCM TOKEN saved for UID $uid: $token');
          debugPrint('====================================================');
          await firestore.collection('users').doc(uid).set({
            'fcmToken': token,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        // Listen for dynamic FCM token refreshes and auto-update Firestore
        messaging!.onTokenRefresh.listen((newToken) async {
          if (newToken.isNotEmpty && newToken != token) {
            debugPrint('🔑 DEVICE FCM TOKEN Refreshed for UID $uid: $newToken');
            await firestore.collection('users').doc(uid).set({
              'fcmToken': newToken,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        });
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Subscribe user device to Household FCM Topic
  Future<void> subscribeToHouseholdTopic(String householdId) async {
    try {
      if (messaging != null && householdId.isNotEmpty) {
        final sanitizedTopic = 'household_${householdId.replaceAll(RegExp(r'[^a-zA-Z0-9-_]'), '_')}';
        await messaging!.subscribeToTopic(sanitizedTopic);
        debugPrint('Subscribed to FCM household topic: $sanitizedTopic');
      }
    } catch (e) {
      debugPrint('Error subscribing to FCM topic: $e');
    }
  }

  /// Resolve target FCM Tokens for recipient (Single User, Subgroup, or All Family), strictly excluding senderUid.
  Future<List<String>> _resolveTargetFcmTokens({
    required String recipientUidOrSubgroup,
    required String? householdId,
    required String? senderUid,
  }) async {
    final Set<String> targetTokens = {};
    try {
      final recipientRaw = recipientUidOrSubgroup.trim();
      final recipientClean = recipientRaw.toLowerCase();

      debugPrint('🔔 Resolving target tokens for recipient: "$recipientRaw", householdId: $householdId, senderUid: $senderUid');

      final Set<String> targetUids = {};

      if (householdId != null && householdId.isNotEmpty) {
        final householdDoc =
            await firestore.collection('households').doc(householdId).get();

        if (householdDoc.exists && householdDoc.data() != null) {
          final data = householdDoc.data()!;
          final List<dynamic> memberIds = data['memberIds'] as List<dynamic>? ?? [];
          final Map<String, dynamic> rawSubgroups =
              data['subgroups'] as Map<String, dynamic>? ?? {};

          // Check if recipient is "All Family"
          if (recipientClean == 'all' ||
              recipientClean == 'everyone' ||
              recipientClean == 'household' ||
              recipientClean == 'all family') {
            for (final id in memberIds) {
              final uidStr = id.toString().trim();
              if (senderUid == null || uidStr != senderUid) {
                targetUids.add(uidStr);
              }
            }
          } else {
            // Check if recipient matches a Subgroup name (e.g. "Sons", "Parents", "Sons Subgroup")
            bool matchedSubgroup = false;
            rawSubgroups.forEach((subgroupKey, memberList) {
              final keyClean = subgroupKey.toString().trim().toLowerCase();
              if (recipientClean == keyClean ||
                  recipientClean == '$keyClean subgroup' ||
                  recipientClean.startsWith(keyClean) ||
                  keyClean.startsWith(recipientClean)) {
                matchedSubgroup = true;
                if (memberList is List) {
                  for (final id in memberList) {
                    final uidStr = id.toString().trim();
                    if (senderUid == null || uidStr != senderUid) {
                      targetUids.add(uidStr);
                    }
                  }
                }
              }
            });

            // If not a subgroup or 'all', treat as a specific User UID or User Name
            if (!matchedSubgroup) {
              if (senderUid == null || recipientRaw != senderUid) {
                targetUids.add(recipientRaw);
              }
            }
          }
        }
      } else {
        // No household ID -> treat as single User UID
        if (senderUid == null || recipientRaw != senderUid) {
          targetUids.add(recipientRaw);
        }
      }

      debugPrint('🔔 Resolved target UIDs: $targetUids');

      // Fetch fcmTokens for all target UIDs
      for (final uid in targetUids) {
        try {
          final uDoc = await firestore.collection('users').doc(uid).get();
          if (uDoc.exists && uDoc.data() != null) {
            final token = uDoc.data()!['fcmToken'] as String?;
            if (token != null && token.isNotEmpty) {
              targetTokens.add(token);
            }
          } else {
            // Fallback query users collection by name
            final query = await firestore
                .collection('users')
                .where('name', isEqualTo: uid)
                .limit(1)
                .get();
            if (query.docs.isNotEmpty) {
              final token = query.docs.first.data()['fcmToken'] as String?;
              if (token != null && token.isNotEmpty) {
                targetTokens.add(token);
              }
            }
          }
        } catch (e) {
          debugPrint('Error fetching FCM token for UID $uid: $e');
        }
      }
    } catch (e) {
      debugPrint('Error resolving target FCM tokens: $e');
    }

    debugPrint('🔔 Final resolved target FCM tokens count: ${targetTokens.length}');
    return targetTokens.toList();
  }

  /// FCM HTTP v1 Service Account Push Dispatcher (Instant High Priority)
  Future<void> sendFcmV1Push({
    required String title,
    required String body,
    required String householdId,
    String? recipientToken,
    String? senderUid,
    Map<String, dynamic>? serviceAccountJson,
  }) async {
    try {
      if (serviceAccountJson == null) return;

      final accountCredentials =
          ServiceAccountCredentials.fromJson(serviceAccountJson);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      final client = await clientViaServiceAccount(accountCredentials, scopes);
      final projectId =
          serviceAccountJson['project_id'] as String? ?? 'hatly-app-2026';

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

      final payload = {"message": messagePayload};

      final response = await client.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode(payload),
      );

      debugPrint('FCM HTTP v1 Status Code: ${response.statusCode}');
      debugPrint('FCM HTTP v1 Response: ${response.body}');

      // Fallback: If target token returned 404 UNREGISTERED (stale token), send via household topic fallback
      if (response.statusCode == 404 &&
          recipientToken != null &&
          householdId.isNotEmpty) {
        debugPrint('⚠️ Target token UNREGISTERED (404). Falling back to household topic push...');
        final fallbackPayload = Map<String, dynamic>.from(messagePayload);
        fallbackPayload.remove("token");
        fallbackPayload["topic"] =
            'household_${householdId.replaceAll(RegExp(r'[^a-zA-Z0-9-_]'), '_')}';

        await client.post(
          Uri.parse(
              'https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
          headers: {'content-type': 'application/json'},
          body: jsonEncode({"message": fallbackPayload}),
        );
      }

      client.close();
    } catch (e) {
      debugPrint('FCM HTTP v1 Push error: $e');
    }
  }

  Map<String, dynamic>? _getServiceAccountJson() {
    final privateKey = dotenv.env['FCM_PRIVATE_KEY'];
    final projectId = dotenv.env['FCM_PROJECT_ID'];
    final clientEmail = dotenv.env['FCM_CLIENT_EMAIL'];
    final privateKeyId = dotenv.env['FCM_PRIVATE_KEY_ID'];
    final clientId = dotenv.env['FCM_CLIENT_ID'];

    if (privateKey == null || privateKey.isEmpty || clientEmail == null || clientEmail.isEmpty) {
      return null;
    }

    return {
      "type": "service_account",
      "project_id": projectId ?? "hatly-app-2026",
      "private_key_id": privateKeyId ?? "",
      "private_key": privateKey.replaceAll(r'\n', '\n'),
      "client_email": clientEmail,
      "client_id": clientId ?? "",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/${Uri.encodeComponent(clientEmail)}",
      "universe_domain": "googleapis.com"
    };
  }

  /// Push a real-time list update notification to assigned family member(s).
  Future<void> sendListUpdateNotification({
    required String listId,
    required String listTitle,
    required String recipientUidOrSubgroup,
    required String recipientName,
    String? householdId,
    String? senderUid,
  }) async {
    try {
      // 1. Update shopping_lists document timestamp and metadata
      await firestore.collection('shopping_lists').doc(listId).update({
        'lastUpdatedMessage': 'List updated by family owner',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Write notification entry in Firestore notifications collection
      final docRef = firestore.collection('notifications').doc();
      final title = 'Shopping List Updated 🛒';
      final body = 'The list "$listTitle" has been updated by the family owner.';

      await docRef.set({
        'id': docRef.id,
        'listId': listId,
        'title': title,
        'body': body,
        'recipient': recipientUidOrSubgroup,
        'recipientName': recipientName,
        'householdId': householdId ?? '',
        'senderUid': senderUid ?? '',
        'type': 'list_updated',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // 3. Resolve FCM tokens for intended recipients (strictly excluding senderUid / Owner!)
      final targetTokens = await _resolveTargetFcmTokens(
        recipientUidOrSubgroup: recipientUidOrSubgroup,
        householdId: householdId,
        senderUid: senderUid,
      );

      final serviceAccountJson = _getServiceAccountJson();
      if (serviceAccountJson != null) {
        // 4. Dispatch direct high-priority FCM v1 Push to each target recipient token
        for (final token in targetTokens) {
          sendFcmV1Push(
            title: title,
            body: body,
            householdId: householdId ?? '',
            recipientToken: token,
            senderUid: senderUid,
            serviceAccountJson: serviceAccountJson,
          );
        }
      }
    } catch (e) {
      debugPrint('Error in sendListUpdateNotification: $e');
    }
  }

  /// Push a real-time list creation notification to assigned family member(s).
  Future<void> sendListCreatedNotification({
    required String listTitle,
    required String recipientUidOrSubgroup,
    required String recipientName,
    String? householdId,
    String? senderUid,
  }) async {
    try {
      final docRef = firestore.collection('notifications').doc();
      final title = 'New Shopping List! 🛒';
      final body = 'New list "$listTitle" was created for $recipientName';

      await docRef.set({
        'id': docRef.id,
        'title': title,
        'body': body,
        'recipient': recipientUidOrSubgroup,
        'recipientName': recipientName,
        'householdId': householdId ?? '',
        'senderUid': senderUid ?? '',
        'type': 'list_created',
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // Resolve FCM tokens for intended recipients (strictly excluding senderUid / Owner!)
      final targetTokens = await _resolveTargetFcmTokens(
        recipientUidOrSubgroup: recipientUidOrSubgroup,
        householdId: householdId,
        senderUid: senderUid,
      );

      final serviceAccountJson = _getServiceAccountJson();
      if (serviceAccountJson != null) {
        // Dispatch direct high-priority FCM v1 Push to each target recipient token
        for (final token in targetTokens) {
          sendFcmV1Push(
            title: title,
            body: body,
            householdId: householdId ?? '',
            recipientToken: token,
            senderUid: senderUid,
            serviceAccountJson: serviceAccountJson,
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending list created notification: $e');
    }
  }
}
