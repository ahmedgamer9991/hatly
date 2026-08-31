import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/config/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/hatly_header_bar.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../household/domain/category_model.dart';
import '../../household/presentation/household_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(userProfileProvider).value;
      if (user != null) {
        _nameController.text = user.name;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _isCopied = true);
    final primaryColor = Theme.of(context).colorScheme.primary;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Invite code copied to clipboard!'),
        backgroundColor: primaryColor,
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  void _saveProfileName() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    ref.read(authControllerProvider.notifier).updateProfile(name);
    final primaryColor = Theme.of(context).colorScheme.primary;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✓ Profile updated successfully!'),
        backgroundColor: primaryColor,
      ),
    );
  }

  Future<void> _showAddSubgroupDialog() async {
    await showDialog(
      context: context,
      builder: (context) => _AddSubgroupDialog(
        onAdd: (groupName) {
          ref.read(householdControllerProvider.notifier).addSubgroup(groupName);
        },
      ),
    );
  }

  Future<void> _showAddCategoryDialog(List<CategoryModel> existingCategories) async {
    await showDialog(
      context: context,
      builder: (context) => _AddCategoryDialog(
        existingCategories: existingCategories,
        onAdd: (newCat) {
          ref
              .read(householdControllerProvider.notifier)
              .updateCategories([...existingCategories, newCat]);
        },
      ),
    );
  }

  Future<void> _showEditCategoryDialog(
    CategoryModel cat,
    List<CategoryModel> existingCategories,
  ) async {
    await showDialog(
      context: context,
      builder: (context) => _EditCategoryDialog(
        category: cat,
        existingCategories: existingCategories,
        onSave: (updatedCat) {
          final updatedList = existingCategories
              .map((c) => c.id == cat.id ? updatedCat : c)
              .toList();
          ref
              .read(householdControllerProvider.notifier)
              .updateCategories(updatedList);
        },
      ),
    );
  }

  void _deleteCategory(
      CategoryModel cat, List<CategoryModel> existingCategories) {
    final updatedList =
        existingCategories.where((c) => c.id != cat.id).toList();

    ref
        .read(householdControllerProvider.notifier)
        .updateCategories(updatedList);
  }

  Future<void> _showSubgroupAssignmentDialog(
      UserModel member, Map<String, List<String>> subgroups) async {
    await showDialog(
      context: context,
      builder: (context) => _AssignSubgroupDialog(
        member: member,
        subgroups: subgroups,
        onSave: (updatedSubgroups) {
          ref
              .read(householdControllerProvider.notifier)
              .updateSubgroups(updatedSubgroups);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProfileProvider);
    final householdState = ref.watch(currentHouseholdProvider);
    final pendingState = ref.watch(pendingMembersProvider);
    final membersState = ref.watch(householdMembersProvider);

    final currentUser = userState.value;
    final household = householdState.value;

    final isOwner = currentUser != null &&
        household != null &&
        (currentUser.uid == household.adminId);

    final categories =
        household?.activeCategories ?? CategoryModel.defaultCategories;
    final currentTheme = ref.watch(activeThemeProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const HatlyHeaderBar(title: 'Settings'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 16, bottom: 120),
                children: [
                  _buildUserProfileCard(currentUser, isOwner, currentTheme),
                  const SizedBox(height: 20),
                  _buildThemeSelectionSection(currentTheme),
                  if (household != null) ...[
                    const SizedBox(height: 20),
                    _buildHouseholdCard(
                      household: household,
                      isOwner: isOwner,
                      pendingState: pendingState,
                      membersState: membersState,
                      currentTheme: currentTheme,
                    ),
                    if (isOwner) ...[
                      const SizedBox(height: 20),
                      _buildCategoryCard(categories, currentTheme),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileCard(UserModel? currentUser, bool isOwner, ThemePreset currentTheme) {
    final primaryColor = currentTheme.primary;
    final onPrimary = currentTheme.themeData.colorScheme.onPrimary;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MY PROFILE SETTINGS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOwner
                      ? primaryColor.withValues(alpha: 0.15)
                      : const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: isOwner
                        ? primaryColor
                        : AppTheme.glassBorder,
                  ),
                ),
                child: Text(
                  isOwner ? '👑 Owner' : '🛒 Shopper',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isOwner
                        ? primaryColor
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: 0.15),
                  border: Border.all(
                      color: primaryColor, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    currentUser?.name.isNotEmpty == true
                        ? currentUser!.name[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUser?.name ?? 'User',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentUser?.email ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    hintText: 'Your name',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: onPrimary,
                  minimumSize: const Size(80, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _saveProfileName,
                child: const Text(
                  'Save',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0x66F87171)),
              minimumSize: const Size(double.infinity, 44),
            ),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
            icon: const Icon(Icons.logout_rounded,
                color: AppTheme.errorRed, size: 18),
            label: const Text(
              'Sign Out',
              style: TextStyle(color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseholdCard({
    required dynamic household,
    required bool isOwner,
    required AsyncValue<List<UserModel>> pendingState,
    required AsyncValue<List<UserModel>> membersState,
    required ThemePreset currentTheme,
  }) {
    final primaryColor = currentTheme.primary;
    final onPrimary = currentTheme.themeData.colorScheme.onPrimary;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FAMILY GROUP MANAGEMENT',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            household.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0x0DFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1AF8FAFC)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'INVITE CODE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      household.inviteCode,
                      style: GoogleFonts.sora(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        color: primaryColor,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    _isCopied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 18,
                    color: primaryColor,
                  ),
                  onPressed: () => _copyCode(household.inviteCode),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FAMILY SUBGROUPS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              if (isOwner)
                TextButton.icon(
                  onPressed: _showAddSubgroupDialog,
                  icon: Icon(Icons.add_rounded,
                      size: 16, color: primaryColor),
                  label: Text(
                    'Add Group',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: household.subgroups.keys.map<Widget>((groupName) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$groupName Subgroup',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    if (isOwner) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          ref
                              .read(householdControllerProvider.notifier)
                              .removeSubgroup(groupName as String);
                        },
                        child: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          if (isOwner)
            pendingState.when(
              loading: () => const SizedBox.shrink(),
              error: (e, s) => const SizedBox.shrink(),
              data: (pendingUsers) {
                if (pendingUsers.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Pending Join Requests',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            '${pendingUsers.length} New',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...pendingUsers.map((user) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0x0DFFFFFF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    user.email,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.check_circle_rounded,
                                  color: primaryColor),
                              onPressed: () {
                                ref
                                    .read(householdControllerProvider.notifier)
                                    .approveJoin(user.uid);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel_rounded,
                                  color: AppTheme.errorRed),
                              onPressed: () {
                                ref
                                    .read(householdControllerProvider.notifier)
                                    .rejectJoin(user.uid);
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          const Text(
            'Approved Family Members',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          membersState.when(
            loading: () => Center(
                child: CircularProgressIndicator(
                    color: primaryColor)),
            error: (e, s) =>
                Text('Error loading members: $e', style: const TextStyle(color: AppTheme.errorRed)),
            data: (members) {
              return Column(
                children: members.map((member) {
                  final isMemberAdmin = member.uid == household.adminId;

                  String memberSubgroup = 'Unassigned';
                  (household.subgroups as Map<String, dynamic>).forEach((groupName, uids) {
                    if (uids is List && uids.contains(member.uid)) {
                      memberSubgroup = groupName;
                    }
                  });

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0x0DFFFFFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x1AF8FAFC)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isMemberAdmin
                                ? primaryColor.withValues(alpha: 0.2)
                                : const Color(0x1AFFFFFF),
                          ),
                          child: Center(
                            child: Text(
                              member.name.isNotEmpty
                                  ? member.name[0].toUpperCase()
                                  : 'M',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isMemberAdmin
                                    ? primaryColor
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      member.name,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isMemberAdmin) ...[
                                    const SizedBox(width: 6),
                                    Text('👑 Admin',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: primaryColor)),
                                  ],
                                ],
                              ),
                              Text(
                                member.email,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isMemberAdmin)
                          InkWell(
                            onTap: isOwner
                                ? () => _showSubgroupAssignmentDialog(
                                      member,
                                      Map<String, List<String>>.from(
                                          household.subgroups
                                              .map((k, v) => MapEntry(k.toString(), List<String>.from(v)))),
                                    )
                                : null,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: memberSubgroup != 'Unassigned'
                                    ? primaryColor
                                        .withValues(alpha: 0.15)
                                    : const Color(0x1AFFFFFF),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: memberSubgroup != 'Unassigned'
                                      ? primaryColor
                                          .withValues(alpha: 0.4)
                                      : const Color(0x33FFFFFF),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    memberSubgroup,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: memberSubgroup != 'Unassigned'
                                          ? primaryColor
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                  if (isOwner) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                        Icons.arrow_drop_down_rounded,
                                        size: 16,
                                        color: primaryColor),
                                  ],
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(List<CategoryModel> categories, ThemePreset currentTheme) {
    final primaryColor = currentTheme.primary;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'STORE CATEGORIES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddCategoryDialog(categories),
                icon: Icon(Icons.add_rounded,
                    size: 16, color: primaryColor),
                label: Text(
                  'Add Category',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...categories.map((cat) {
            final catColor = Color(
                int.parse(cat.colorHex.replaceFirst('#', '0xFF')));

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0x0DFFFFFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x1AF8FAFC)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: catColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cat.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit category "${cat.name}"',
                    icon: const Icon(Icons.edit_outlined,
                        size: 18, color: AppTheme.textSecondary),
                    onPressed: () =>
                        _showEditCategoryDialog(cat, categories),
                  ),
                  IconButton(
                    tooltip: 'Delete category "${cat.name}"',
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 18, color: AppTheme.errorRed),
                    onPressed: () => _deleteCategory(cat, categories),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildThemeSelectionSection(ThemePreset currentTheme) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: currentTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.palette_outlined,
                  color: AppTheme.textPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'App Theme & Styling (10 Presets)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Active: ${currentTheme.emoji} ${currentTheme.name}',
                      style: TextStyle(
                        fontSize: 12,
                        color: currentTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Tap any theme below to preview and test different color aesthetics across the whole app in real-time:',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 125,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ThemePreset.allPresets.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final preset = ThemePreset.allPresets[index];
                final isSelected = preset.id == currentTheme.id;

                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: 'Switch to ${preset.name} theme',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      ref.read(themeControllerProvider.notifier).setTheme(preset);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Theme switched to ${preset.emoji} ${preset.name}'),
                          backgroundColor: preset.primary,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 145,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: preset.backgroundGradient,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? preset.primary
                              : const Color(0x33FFFFFF),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: preset.primary.withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                preset.emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: preset.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 12,
                                    color: Color(0xFF000000),
                                  ),
                                )
                              else
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: preset.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: preset.secondary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                preset.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                preset.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AddSubgroupDialog extends StatefulWidget {
  final ValueChanged<String> onAdd;

  const _AddSubgroupDialog({required this.onAdd});

  @override
  State<_AddSubgroupDialog> createState() => _AddSubgroupDialogState();
}

class _AddSubgroupDialogState extends State<_AddSubgroupDialog> {
  late final TextEditingController _groupNameCtrl;

  @override
  void initState() {
    super.initState();
    _groupNameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _groupNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return AlertDialog(
      backgroundColor: AppTheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.glassBorder),
      ),
      title: const Text(
        'Add New Family Subgroup',
        style: TextStyle(color: AppTheme.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _groupNameCtrl,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Subgroup Name',
              hintText: 'e.g. Sons, Kids, Drivers, Parents...',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: onPrimary,
          ),
          onPressed: () {
            final groupName = _groupNameCtrl.text.trim();
            if (groupName.isEmpty) return;

            widget.onAdd(groupName);
            Navigator.pop(context);
          },
          child: const Text('Add Subgroup',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _AddCategoryDialog extends StatefulWidget {
  final List<CategoryModel> existingCategories;
  final ValueChanged<CategoryModel> onAdd;

  const _AddCategoryDialog({
    required this.existingCategories,
    required this.onAdd,
  });

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  late final TextEditingController _nameCtrl;
  String _selectedColorHex = '#64DD91';
  String _selectedIconName = 'shopping_cart';

  static const _colorOptions = [
    '#64DD91', // Emerald
    '#38BDF8', // Sky Blue
    '#FBBF24', // Amber
    '#F87171', // Rose
    '#A855F7', // Purple
    '#EC4899', // Pink
    '#10B981', // Mint
    '#CBD5E1', // Slate
  ];

  static const _iconOptions = [
    'shopping_cart',
    'local_pharmacy',
    'bakery_dining',
    'restaurant',
    'fastfood',
    'pets',
    'cleaning_services',
    'shopping_bag',
    'local_grocery_store',
    'sports',
    'florist',
    'more_horiz',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.glassBorder),
      ),
      title: const Text(
        'Add Store Category',
        style: TextStyle(color: AppTheme.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g. Pets, Snacks, Baby...',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose Category Color:',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colorOptions.map((hex) {
                final isSelected = _selectedColorHex == hex;
                final colorInt = int.parse(hex.replaceFirst('#', '0xFF'));
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorHex = hex),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(colorInt),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose Category Icon:',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _iconOptions.map((iconName) {
                final isSelected = _selectedIconName == iconName;
                final dummyCat = CategoryModel(
                  id: '',
                  name: '',
                  colorHex: _selectedColorHex,
                  iconName: iconName,
                );
                final selectedColor = Color(int.parse(
                    _selectedColorHex.replaceFirst('#', '0xFF')));

                return GestureDetector(
                  onTap: () => setState(() => _selectedIconName = iconName),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? selectedColor.withValues(alpha: 0.25)
                          : const Color(0x0DFFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? selectedColor
                            : const Color(0x1AF8FAFC),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      dummyCat.iconData,
                      size: 20,
                      color: isSelected ? selectedColor : AppTheme.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;

            final newCat = CategoryModel(
              id: '${DateTime.now().millisecondsSinceEpoch}',
              name: name,
              colorHex: _selectedColorHex,
              iconName: _selectedIconName,
            );

            widget.onAdd(newCat);
            Navigator.pop(context);
          },
          child: const Text('Save Category',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _EditCategoryDialog extends StatefulWidget {
  final CategoryModel category;
  final List<CategoryModel> existingCategories;
  final ValueChanged<CategoryModel> onSave;

  const _EditCategoryDialog({
    required this.category,
    required this.existingCategories,
    required this.onSave,
  });

  @override
  State<_EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<_EditCategoryDialog> {
  late final TextEditingController _nameCtrl;
  late String _selectedColorHex;
  late String _selectedIconName;

  static const _colorOptions = [
    '#64DD91',
    '#38BDF8',
    '#FBBF24',
    '#F87171',
    '#A855F7',
    '#EC4899',
    '#10B981',
    '#CBD5E1',
  ];

  static const _iconOptions = [
    'shopping_cart',
    'local_pharmacy',
    'bakery_dining',
    'restaurant',
    'fastfood',
    'pets',
    'cleaning_services',
    'shopping_bag',
    'local_grocery_store',
    'sports',
    'florist',
    'more_horiz',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category.name);
    _selectedColorHex = widget.category.colorHex;
    _selectedIconName = widget.category.iconName;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.glassBorder),
      ),
      title: Text(
        'Edit Category: ${widget.category.name}',
        style: const TextStyle(color: AppTheme.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Category Name',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Category Color:',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _colorOptions.map((hex) {
                final isSelected = _selectedColorHex == hex;
                final colorInt = int.parse(hex.replaceFirst('#', '0xFF'));
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorHex = hex),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(colorInt),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Category Icon:',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _iconOptions.map((iconName) {
                final isSelected = _selectedIconName == iconName;
                final dummyCat = CategoryModel(
                  id: '',
                  name: '',
                  colorHex: _selectedColorHex,
                  iconName: iconName,
                );
                final selectedColor = Color(int.parse(
                    _selectedColorHex.replaceFirst('#', '0xFF')));

                return GestureDetector(
                  onTap: () => setState(() => _selectedIconName = iconName),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? selectedColor.withValues(alpha: 0.25)
                          : const Color(0x0DFFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? selectedColor
                            : const Color(0x1AF8FAFC),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      dummyCat.iconData,
                      size: 20,
                      color: isSelected ? selectedColor : AppTheme.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () {
            final newName = _nameCtrl.text.trim();
            if (newName.isEmpty) return;

            final updatedCat = widget.category.copyWith(
              name: newName,
              colorHex: _selectedColorHex,
              iconName: _selectedIconName,
            );

            widget.onSave(updatedCat);
            Navigator.pop(context);
          },
          child: const Text('Save Changes',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _AssignSubgroupDialog extends StatefulWidget {
  final UserModel member;
  final Map<String, List<String>> subgroups;
  final ValueChanged<Map<String, List<String>>> onSave;

  const _AssignSubgroupDialog({
    required this.member,
    required this.subgroups,
    required this.onSave,
  });

  @override
  State<_AssignSubgroupDialog> createState() => _AssignSubgroupDialogState();
}

class _AssignSubgroupDialogState extends State<_AssignSubgroupDialog> {
  late final TextEditingController _newSubgroupCtrl;
  late String _selectedSubgroup;
  bool _isCreatingNewSubgroup = false;
  late final List<String> _availableGroupNames;

  @override
  void initState() {
    super.initState();
    _newSubgroupCtrl = TextEditingController();
    _selectedSubgroup = 'None';
    widget.subgroups.forEach((groupName, memberList) {
      if (memberList.contains(widget.member.uid)) {
        _selectedSubgroup = groupName;
      }
    });
    _availableGroupNames = <String>{'None', 'Sons', 'Parents', ...widget.subgroups.keys}.toList();
  }

  @override
  void dispose() {
    _newSubgroupCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.glassBorder),
      ),
      title: Text(
        'Assign Subgroup: ${widget.member.name}',
        style: const TextStyle(color: AppTheme.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._availableGroupNames.map((groupName) {
              final isSelected = !_isCreatingNewSubgroup && _selectedSubgroup == groupName;
              return GestureDetector(
                onTap: () => setState(() {
                  _isCreatingNewSubgroup = false;
                  _selectedSubgroup = groupName;
                }),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                        : const Color(0x0DFFFFFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : const Color(0x1AF8FAFC),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        groupName == 'None' ? 'Unassigned / None' : '$groupName Subgroup',
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded,
                            color: Theme.of(context).colorScheme.primary, size: 20),
                    ],
                  ),
                ),
              );
            }),
            if (!_isCreatingNewSubgroup)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _isCreatingNewSubgroup = true;
                    });
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Create New Subgroup'),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextField(
                  controller: _newSubgroupCtrl,
                  autofocus: true,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'New Subgroup Name',
                    hintText: 'e.g. Daughters, Drivers, Kids...',
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          onPressed: () {
            final updatedSubgroups = Map<String, List<String>>.from(widget.subgroups);

            // Remove member from all current groups
            updatedSubgroups.forEach((key, list) {
              list.remove(widget.member.uid);
            });

            String targetGroup = _selectedSubgroup;
            if (_isCreatingNewSubgroup) {
              final newGroupInput = _newSubgroupCtrl.text.trim();
              if (newGroupInput.isNotEmpty) {
                targetGroup = newGroupInput;
              }
            }

            // Add to selected group if not 'None'
            if (targetGroup != 'None' && targetGroup.isNotEmpty) {
              updatedSubgroups.putIfAbsent(targetGroup, () => []);
              if (!updatedSubgroups[targetGroup]!.contains(widget.member.uid)) {
                updatedSubgroups[targetGroup]!.add(widget.member.uid);
              }
            }

            widget.onSave(updatedSubgroups);
            Navigator.pop(context);
          },
          child: const Text('Save Assignment', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
