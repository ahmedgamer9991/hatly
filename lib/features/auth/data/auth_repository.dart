import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  AuthRepository({
    required this.auth,
    required this.firestore,
  });

  /// Stream of Firebase Authentication state changes.
  Stream<User?> get authStateChanges => auth.authStateChanges();

  /// Get currently signed-in Firebase user.
  User? get currentUser => auth.currentUser;

  /// Stream of user profile from Firestore.
  Stream<UserModel?> watchUserProfile(String uid) {
    return firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  /// Sign in with email and password. Ensures Firestore user profile exists.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    if (credential.user != null) {
      final uid = credential.user!.uid;
      final docRef = firestore.collection('users').doc(uid);
      final doc = await docRef.get();

      if (!doc.exists ||
          doc.data()?['name'] == null ||
          doc.data()?['email'] == null) {
        final fallbackName = credential.user!.displayName != null &&
                credential.user!.displayName!.isNotEmpty
            ? credential.user!.displayName!
            : email.trim().split('@')[0];

        await docRef.set({
          'uid': uid,
          'name': fallbackName,
          'email': email.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }

    return credential;
  }

  /// Sign up with email, password, and display name.
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim();

    final credential = await auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );

    if (credential.user != null) {
      final uid = credential.user!.uid;

      // 1. Update Firebase Auth display name
      try {
        await credential.user!.updateDisplayName(cleanName);
      } catch (_) {}

      // 2. Save complete user profile in Firestore users collection
      try {
        await firestore.collection('users').doc(uid).set({
          'uid': uid,
          'name': cleanName,
          'email': cleanEmail,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        // Fallback retry if token propagation was pending right after account creation
        await Future.delayed(const Duration(milliseconds: 500));
        await firestore.collection('users').doc(uid).set({
          'uid': uid,
          'name': cleanName,
          'email': cleanEmail,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }

    return credential;
  }

  /// Update user profile display name & email in Firestore & Firebase Auth.
  Future<void> updateUserProfile({
    required String uid,
    required String name,
    String? email,
  }) async {
    final cleanName = name.trim();

    final Map<String, dynamic> updates = {
      'name': cleanName,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (email != null && email.trim().isNotEmpty) {
      updates['email'] = email.trim();
    }

    await firestore
        .collection('users')
        .doc(uid)
        .set(updates, SetOptions(merge: true));

    if (auth.currentUser != null && auth.currentUser!.uid == uid) {
      await auth.currentUser!.updateDisplayName(cleanName);
    }
  }

  /// Sign out the current user and clear their FCM device token.
  Future<void> signOut() async {
    final uid = auth.currentUser?.uid;
    if (uid != null) {
      try {
        await firestore.collection('users').doc(uid).update({
          'fcmToken': FieldValue.delete(),
        });
      } catch (_) {}
    }
    await auth.signOut();
  }
}
