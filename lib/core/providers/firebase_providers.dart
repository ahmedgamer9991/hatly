import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for [FirebaseAuth] instance.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Provider for [FirebaseFirestore] instance.
final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Provider for [FirebaseMessaging] instance.
final firebaseMessagingProvider = Provider<FirebaseMessaging?>((ref) {
  try {
    return FirebaseMessaging.instance;
  } catch (_) {
    // Return null if push notifications are not supported (e.g. on web/desktop without configuration)
    return null;
  }
});
