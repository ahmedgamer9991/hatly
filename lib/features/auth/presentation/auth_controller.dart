import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../household/presentation/household_controller.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

/// Provider for [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

/// StreamProvider listening to Firebase Auth state changes.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// StreamProvider watching the current logged-in user's Firestore profile.
/// Includes synchronous self-healing fallback to resolve Household ID before emitting stream events.
final userProfileProvider = StreamProvider<UserModel?>((ref) async* {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) {
    yield null;
    return;
  }

  final repository = ref.watch(authRepositoryProvider);
  final firestore = ref.watch(firebaseFirestoreProvider);

  try {
    await for (var userModel in repository.watchUserProfile(authUser.uid)) {
      if (ref.read(authStateProvider).value == null) {
        yield null;
        return;
      }

      if (userModel == null) {
        // Self-heal: Create Firestore user profile document if missing
        try {
          final fallbackName =
              (authUser.displayName != null && authUser.displayName!.isNotEmpty)
                  ? authUser.displayName!
                  : (authUser.email != null && authUser.email!.isNotEmpty
                      ? authUser.email!.split('@')[0]
                      : 'Family Member');
          final fallbackEmail = authUser.email ?? '';

          await firestore.collection('users').doc(authUser.uid).set({
            'uid': authUser.uid,
            'name': fallbackName,
            'email': fallbackEmail,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          final freshDoc =
              await firestore.collection('users').doc(authUser.uid).get();
          if (freshDoc.exists && freshDoc.data() != null) {
            userModel = UserModel.fromMap(freshDoc.data()!, freshDoc.id);
          }
        } catch (_) {}
      }

      // If userModel exists but has no householdId, check if user belongs to any household in Firestore BEFORE yielding!
      if (userModel != null &&
          (userModel.householdId == null || userModel.householdId!.isEmpty)) {
        try {
          final query = await firestore
              .collection('households')
              .where('memberIds', arrayContains: authUser.uid)
              .limit(1)
              .get();

          if (query.docs.isNotEmpty) {
            final householdId = query.docs.first.id;
            // Self-heal user profile doc in Firestore with householdId
            await firestore.collection('users').doc(authUser.uid).set({
              'householdId': householdId,
            }, SetOptions(merge: true));

            userModel = userModel.copyWith(householdId: householdId);
          }
        } catch (_) {}
      }

      yield userModel;
    }
  } catch (e) {
    yield null;
  }
});

/// Provider checking if initial app data has finished loading (ONLY triggers on cold boot, not stream refreshes).
final appInitialDataLoaderProvider = Provider<AsyncValue<bool>>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) {
    return const AsyncValue.data(false);
  }

  final userProfileState = ref.watch(userProfileProvider);
  final householdState = ref.watch(currentHouseholdProvider);

  // Return loading until BOTH userProfile AND currentHousehold initial stream values are fully resolved
  if (!userProfileState.hasValue || !householdState.hasValue) {
    return const AsyncValue.loading();
  }

  return const AsyncValue.data(true);
});

/// StateNotifier for managing auth actions (sign in, sign up, sign out, profile updates).
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository repository;

  AuthController({required this.repository})
      : super(const AsyncValue.data(null));

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repository.signInWithEmail(
          email: email,
          password: password,
        ));
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repository.signUpWithEmail(
          email: email,
          password: password,
          name: name,
        ));
  }

  Future<void> updateProfile(String name) async {
    final user = repository.currentUser;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.updateUserProfile(
        uid: user.uid,
        name: name,
      ),
    );
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repository.signOut());
  }
}

/// StateNotifierProvider for [AuthController].
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(
    repository: ref.watch(authRepositoryProvider),
  );
});
