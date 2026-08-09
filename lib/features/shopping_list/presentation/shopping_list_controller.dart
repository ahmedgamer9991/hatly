import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/firebase_providers.dart';
import '../../../core/services/notification_service.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../household/presentation/household_controller.dart';
import '../data/shopping_list_repository.dart';
import '../domain/shopping_item_model.dart';
import '../domain/shopping_list_model.dart';

/// Provider for [ShoppingListRepository].
final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  return ShoppingListRepository(
    firestore: ref.watch(firebaseFirestoreProvider),
  );
});

/// StreamProvider fetching all active lists in the active household.
final activeListsProvider = StreamProvider<List<ShoppingListModel>>((ref) async* {
  final authUser = ref.watch(authStateProvider).value;
  final household = ref.watch(currentHouseholdProvider).value;

  if (authUser == null || household == null) {
    yield [];
    return;
  }

  try {
    await for (final lists in ref
        .watch(shoppingListRepositoryProvider)
        .watchActiveHouseholdLists(household.id)) {
      if (ref.read(authStateProvider).value == null) {
        yield [];
        return;
      }
      yield lists;
    }
  } catch (e) {
    yield [];
  }
});

/// StreamProvider watching a single shopping list document in real-time.
final singleListProvider =
    StreamProvider.family<ShoppingListModel?, String>((ref, listId) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) {
    return Stream.value(null);
  }

  return ref.watch(shoppingListRepositoryProvider).watchList(listId);
});

/// StateNotifier for list creation, item status toggling, and notification dispatch.
class ShoppingListController extends StateNotifier<AsyncValue<void>> {
  final ShoppingListRepository repository;
  final Ref ref;

  ShoppingListController({
    required this.repository,
    required this.ref,
  }) : super(const AsyncValue.data(null));

  /// Create a new shopping list
  Future<void> createList({
    required String title,
    required String assignedTo,
    required String assignedToName,
    required List<ShoppingItemModel> items,
  }) async {
    final user = ref.read(authStateProvider).value;
    final household = ref.read(currentHouseholdProvider).value;

    if (user == null || household == null) return;

    final newList = ShoppingListModel(
      id: '',
      householdId: household.id,
      title: title.trim(),
      createdBy: user.uid,
      assignedTo: assignedTo,
      assignedToName: assignedToName,
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      items: items,
    );

    state = const AsyncValue.loading();
    final result =
        await AsyncValue.guard(() => repository.createList(newList));
    state = result;

    if (!result.hasError) {
      ref.read(notificationServiceProvider).sendListCreatedNotification(
            listTitle: title.trim(),
            recipientUidOrSubgroup: assignedTo,
            recipientName: assignedToName,
            householdId: household.id,
            senderUid: user.uid,
          );
    }
  }

  /// Update item status (pending, bought, outOfStock)
  Future<void> updateItemStatus({
    required String listId,
    required String itemId,
    required String status,
    String? note,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.updateItemStatus(
        listId: listId,
        itemId: itemId,
        status: status,
        note: note,
      ),
    );
  }

  /// Add a new item to an active list in real-time
  Future<void> addItemToList({
    required String listId,
    required String name,
    required String category,
  }) async {
    final newItem = ShoppingItemModel(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      category: category,
    );

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.addItemToList(listId: listId, item: newItem),
    );
  }

  /// Remove an item from an active list in real-time
  Future<void> removeItemFromList({
    required String listId,
    required String itemId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => repository.removeItemFromList(listId: listId, itemId: itemId),
    );
  }

  /// Send update notification to assigned family user(s)
  Future<void> notifyListUpdated({
    required String listId,
    required String listTitle,
    required String assignedTo,
    required String assignedToName,
  }) async {
    final household = ref.read(currentHouseholdProvider).value;
    final currentUser = ref.read(userProfileProvider).value;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(notificationServiceProvider).sendListUpdateNotification(
            listId: listId,
            listTitle: listTitle,
            recipientUidOrSubgroup: assignedTo,
            recipientName: assignedToName,
            householdId: household?.id,
            senderUid: currentUser?.uid,
          ),
    );
  }

  /// Mark list as completed
  Future<void> completeList(String listId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repository.completeList(listId));
  }

  /// Delete a shopping list from Firestore
  Future<void> deleteList(String listId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => repository.deleteList(listId));
  }

  /// Reassign a shopping list to a new recipient or subgroup
  Future<void> updateListAssignment({
    required String listId,
    required String listTitle,
    required String newAssignedTo,
    required String newAssignedToName,
  }) async {
    final user = ref.read(authStateProvider).value;
    final household = ref.read(currentHouseholdProvider).value;

    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(
      () => repository.updateListAssignment(
        listId: listId,
        assignedTo: newAssignedTo,
        assignedToName: newAssignedToName,
      ),
    );
    state = result;

    if (!result.hasError && household != null && user != null) {
      ref.read(notificationServiceProvider).sendListCreatedNotification(
            listTitle: listTitle,
            recipientUidOrSubgroup: newAssignedTo,
            recipientName: newAssignedToName,
            householdId: household.id,
            senderUid: user.uid,
          );
    }
  }
}

/// Provider for [ShoppingListController].
final shoppingListControllerProvider =
    StateNotifierProvider<ShoppingListController, AsyncValue<void>>((ref) {
  return ShoppingListController(
    repository: ref.watch(shoppingListRepositoryProvider),
    ref: ref,
  );
});
