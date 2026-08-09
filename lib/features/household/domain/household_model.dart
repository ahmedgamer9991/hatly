import 'category_model.dart';

class HouseholdModel {
  final String id;
  final String name;
  final String inviteCode;
  final String adminId;
  final DateTime createdAt;
  final List<String> memberIds;
  final List<String> pendingUserIds;
  final Map<String, List<String>> subgroups;
  final List<CategoryModel> customCategories;

  const HouseholdModel({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.adminId,
    required this.createdAt,
    required this.memberIds,
    required this.pendingUserIds,
    required this.subgroups,
    this.customCategories = const [],
  });

  /// Get active categories (returns customCategories if non-empty, otherwise defaults)
  List<CategoryModel> get activeCategories =>
      customCategories.isNotEmpty ? customCategories : CategoryModel.defaultCategories;

  factory HouseholdModel.fromMap(Map<String, dynamic> map, String id) {
    // Parse subgroups map safely
    final rawSubgroups = map['subgroups'] as Map<String, dynamic>? ?? {};
    final parsedSubgroups = <String, List<String>>{};
    rawSubgroups.forEach((key, value) {
      if (value is List) {
        parsedSubgroups[key] =
            List<String>.from(value.map((e) => e.toString()));
      }
    });

    // Parse custom categories safely
    final rawCategories = map['customCategories'] as List? ?? [];
    final parsedCategories = rawCategories
        .map((c) => CategoryModel.fromMap(Map<String, dynamic>.from(c as Map)))
        .toList();

    return HouseholdModel(
      id: id,
      name: map['name'] as String? ?? '',
      inviteCode: map['inviteCode'] as String? ?? '',
      adminId: map['adminId'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is DateTime
              ? map['createdAt'] as DateTime
              : (map['createdAt'] as dynamic).toDate() as DateTime)
          : DateTime.now(),
      memberIds: List<String>.from(map['memberIds'] as List? ?? []),
      pendingUserIds: List<String>.from(map['pendingUserIds'] as List? ?? []),
      subgroups: parsedSubgroups,
      customCategories: parsedCategories.isNotEmpty
          ? parsedCategories
          : CategoryModel.defaultCategories,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'inviteCode': inviteCode,
      'adminId': adminId,
      'createdAt': createdAt,
      'memberIds': memberIds,
      'pendingUserIds': pendingUserIds,
      'subgroups': subgroups,
      'customCategories': customCategories.map((c) => c.toMap()).toList(),
    };
  }

  HouseholdModel copyWith({
    String? id,
    String? name,
    String? inviteCode,
    String? adminId,
    DateTime? createdAt,
    List<String>? memberIds,
    List<String>? pendingUserIds,
    Map<String, List<String>>? subgroups,
    List<CategoryModel>? customCategories,
  }) {
    return HouseholdModel(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      adminId: adminId ?? this.adminId,
      createdAt: createdAt ?? this.createdAt,
      memberIds: memberIds ?? this.memberIds,
      pendingUserIds: pendingUserIds ?? this.pendingUserIds,
      subgroups: subgroups ?? this.subgroups,
      customCategories: customCategories ?? this.customCategories,
    );
  }
}
