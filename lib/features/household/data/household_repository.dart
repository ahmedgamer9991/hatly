import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/domain/user_model.dart';
import '../domain/category_model.dart';
import '../domain/household_model.dart';

class HouseholdRepository {
  final FirebaseFirestore firestore;

  HouseholdRepository({required this.firestore});

  /// Helper to generate a secure 8-character invite code formatted as HAT-XXXX-XX
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    final part1 = List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join();
    final part2 = List.generate(2, (_) => chars[rand.nextInt(chars.length)]).join();
    return 'HAT-$part1-$part2';
  }

  /// Create a new household and set creator as Admin (Admin belongs to no subgroup).
  Future<HouseholdModel> createHousehold({
    required String name,
    required String adminUid,
  }) async {
    final inviteCode = _generateInviteCode();
    final docRef = firestore.collection('households').doc();

    final household = HouseholdModel(
      id: docRef.id,
      name: name.trim(),
      inviteCode: inviteCode,
      adminId: adminUid,
      createdAt: DateTime.now(),
      memberIds: [adminUid],
      pendingUserIds: [],
      subgroups: {
        'Parents': [],
        'Sons': [],
      },
      customCategories: CategoryModel.defaultCategories,
    );

    // Write household document
    await docRef.set(household.toMap());

    // Merge householdId into user's profile document
    await firestore.collection('users').doc(adminUid).set({
      'householdId': docRef.id,
    }, SetOptions(merge: true));

    return household;
  }

  /// Request to join a household using an invite code.
  Future<String> requestJoinHousehold({
    required String inviteCode,
    required String userUid,
  }) async {
    final cleanCode = inviteCode.trim().toUpperCase();

    final query = await firestore
        .collection('households')
        .where('inviteCode', isEqualTo: cleanCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Invalid family invite code. Please verify and try again.');
    }

    final householdDoc = query.docs.first;
    final household = HouseholdModel.fromMap(householdDoc.data(), householdDoc.id);

    if (household.memberIds.contains(userUid)) {
      throw Exception('You are already an approved member of this family.');
    }

    if (household.pendingUserIds.contains(userUid)) {
      throw Exception('Your join request has already been sent! Waiting for family owner approval.');
    }

    // Add user UID to pending list on household document
    await householdDoc.reference.update({
      'pendingUserIds': FieldValue.arrayUnion([userUid]),
    });

    // Link householdId to joining user profile document for real-time tracking
    await firestore.collection('users').doc(userUid).set({
      'householdId': householdDoc.id,
    }, SetOptions(merge: true));

    return householdDoc.id;
  }

  /// Admin approves a pending user join request.
  Future<void> approveJoinRequest({
    required String householdId,
    required String userUid,
  }) async {
    await firestore.collection('households').doc(householdId).update({
      'pendingUserIds': FieldValue.arrayRemove([userUid]),
      'memberIds': FieldValue.arrayUnion([userUid]),
    });

    await firestore.collection('users').doc(userUid).set({
      'householdId': householdId,
    }, SetOptions(merge: true));
  }

  /// Admin rejects a pending user join request.
  Future<void> rejectJoinRequest({
    required String householdId,
    required String userUid,
  }) async {
    await firestore.collection('households').doc(householdId).update({
      'pendingUserIds': FieldValue.arrayRemove([userUid]),
    });

    // Unlink householdId from user profile doc
    await firestore.collection('users').doc(userUid).update({
      'householdId': FieldValue.delete(),
    });
  }

  /// Stream of HouseholdModel updates in real-time.
  Stream<HouseholdModel?> watchHousehold(String householdId) {
    return firestore
        .collection('households')
        .doc(householdId)
        .snapshots()
        .map((doc) {
      if (doc.exists && doc.data() != null) {
        return HouseholdModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    });
  }

  /// Stream of member user models (approved or pending) in a household.
  Stream<List<UserModel>> watchHouseholdMembers(List<String> memberIds) {
    if (memberIds.isEmpty) return Stream.value([]);

    return firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: memberIds)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Update subgroup member lists.
  Future<void> updateSubgroups({
    required String householdId,
    required Map<String, List<String>> subgroups,
  }) async {
    await firestore.collection('households').doc(householdId).update({
      'subgroups': subgroups,
    });
  }

  /// Add a new subgroup to household.
  Future<void> addSubgroup({
    required String householdId,
    required String groupName,
  }) async {
    final doc = await firestore.collection('households').doc(householdId).get();
    if (!doc.exists) return;

    final data = doc.data() ?? {};
    final rawSubgroups = Map<String, dynamic>.from(data['subgroups'] as Map? ?? {});
    final cleanName = groupName.trim();

    if (!rawSubgroups.containsKey(cleanName)) {
      rawSubgroups[cleanName] = [];
      await firestore.collection('households').doc(householdId).update({
        'subgroups': rawSubgroups,
      });
    }
  }

  /// Remove a subgroup from household.
  Future<void> removeSubgroup({
    required String householdId,
    required String groupName,
  }) async {
    final doc = await firestore.collection('households').doc(householdId).get();
    if (!doc.exists) return;

    final data = doc.data() ?? {};
    final rawSubgroups = Map<String, dynamic>.from(data['subgroups'] as Map? ?? {});

    if (rawSubgroups.containsKey(groupName)) {
      rawSubgroups.remove(groupName);
      await firestore.collection('households').doc(householdId).update({
        'subgroups': rawSubgroups,
      });
    }
  }

  /// Update household custom categories in real-time.
  Future<void> updateHouseholdCategories({
    required String householdId,
    required List<CategoryModel> categories,
  }) async {
    await firestore.collection('households').doc(householdId).update({
      'customCategories': categories.map((c) => c.toMap()).toList(),
    });
  }
}
