import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/household_repository.dart';
import '../domain/category_model.dart';
import '../domain/household_model.dart';

/// Provider for [HouseholdRepository].
final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  return HouseholdRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

/// StreamProvider fetching the active user's HouseholdModel safely.
final currentHouseholdProvider = StreamProvider<HouseholdModel?>((ref) async* {
  final authUser = ref.watch(authStateProvider).value;
  final userProfile = ref.watch(userProfileProvider).value;

  if (authUser == null ||
      userProfile?.householdId == null ||
      userProfile!.householdId!.isEmpty) {
    yield null;
    return;
  }

  try {
    await for (final household in ref
        .watch(householdRepositoryProvider)
        .watchHousehold(userProfile.householdId!)) {
      if (ref.read(authStateProvider).value == null) {
        yield null;
        return;
      }
      yield household;
    }
  } catch (e) {
    yield null;
  }
});

/// Provider checking if the current user is an approved member of their household.
final isApprovedMemberProvider = Provider<bool>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  final household = ref.watch(currentHouseholdProvider).value;

  if (authUser == null || household == null) return false;
  return household.memberIds.contains(authUser.uid);
});

/// StreamProvider fetching all approved member profiles in the current household.
final householdMembersProvider = StreamProvider<List<UserModel>>((ref) async* {
  final authUser = ref.watch(authStateProvider).value;
  final household = ref.watch(currentHouseholdProvider).value;

  if (authUser == null || household == null || household.memberIds.isEmpty) {
    yield [];
    return;
  }

  try {
    await for (final members in ref
        .watch(householdRepositoryProvider)
        .watchHouseholdMembers(household.memberIds)) {
      if (ref.read(authStateProvider).value == null) {
        yield [];
        return;
      }
      yield members;
    }
  } catch (e) {
    yield [];
  }
});

/// StreamProvider fetching all pending join request user profiles.
final pendingMembersProvider = StreamProvider<List<UserModel>>((ref) async* {
  final authUser = ref.watch(authStateProvider).value;
  final household = ref.watch(currentHouseholdProvider).value;

  if (authUser == null || household == null || household.pendingUserIds.isEmpty) {
    yield [];
    return;
  }

  try {
    await for (final pending in ref
        .watch(householdRepositoryProvider)
        .watchHouseholdMembers(household.pendingUserIds)) {
      if (ref.read(authStateProvider).value == null) {
        yield [];
        return;
      }
      yield pending;
    }
  } catch (e) {
    yield [];
  }
});

/// StateNotifier for handling Household UI actions (create, join, approve, reject, category & subgroup updates).
class HouseholdController extends StateNotifier<AsyncValue<void>> {
  final HouseholdRepository repository;
  final Ref ref;

  HouseholdController({
    required this.repository,
    required this.ref,
  }) : super(const AsyncValue.data(null));

  /// Create a new household
  Future<void> createHousehold(String name) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.createHousehold(name: name, adminUid: user.uid),
    );
  }

  /// Request to join a household with an invite code
  Future<void> requestJoin(String inviteCode) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.requestJoinHousehold(
        inviteCode: inviteCode,
        userUid: user.uid,
      ),
    );
  }

  /// Admin approves a user join request
  Future<void> approveJoin(String userUid) async {
    final household = ref.read(currentHouseholdProvider).value;
    if (household == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.approveJoinRequest(
        householdId: household.id,
        userUid: userUid,
      ),
    );
  }

  /// Admin rejects a user join request
  Future<void> rejectJoin(String userUid) async {
    final household = ref.read(currentHouseholdProvider).value;
    if (household == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.rejectJoinRequest(
        householdId: household.id,
        userUid: userUid,
      ),
    );
  }

  /// Update household subgroup configuration
  Future<void> updateSubgroups(Map<String, List<String>> subgroups) async {
    final household = ref.read(currentHouseholdProvider).value;
    if (household == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.updateSubgroups(
        householdId: household.id,
        subgroups: subgroups,
      ),
    );
  }

  /// Add a new subgroup to household
  Future<void> addSubgroup(String groupName) async {
    final household = ref.read(currentHouseholdProvider).value;
    if (household == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.addSubgroup(
        householdId: household.id,
        groupName: groupName,
      ),
    );
  }

  /// Remove a subgroup from household
  Future<void> removeSubgroup(String groupName) async {
    final household = ref.read(currentHouseholdProvider).value;
    if (household == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.removeSubgroup(
        householdId: household.id,
        groupName: groupName,
      ),
    );
  }

  /// Update custom categories
  Future<void> updateCategories(List<CategoryModel> categories) async {
    final household = ref.read(currentHouseholdProvider).value;
    if (household == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.updateHouseholdCategories(
        householdId: household.id,
        categories: categories,
      ),
    );
  }
}

/// StateNotifierProvider for [HouseholdController].
final householdControllerProvider =
    StateNotifierProvider<HouseholdController, AsyncValue<void>>((ref) {
  return HouseholdController(
    repository: ref.watch(householdRepositoryProvider),
    ref: ref,
  );
});
