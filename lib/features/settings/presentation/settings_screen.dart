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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite code copied to clipboard!'),
        backgroundColor: AppTheme.primaryEmerald,
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Profile updated successfully!'),
        backgroundColor: AppTheme.primaryEmerald,
      ),
    );
  }

  void _showAddSubgroupDialog() {
    final groupNameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
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
                controller: groupNameCtrl,
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
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryEmerald),
              onPressed: () {
                final groupName = groupNameCtrl.text.trim();
                if (groupName.isEmpty) return;

                ref.read(householdControllerProvider.notifier).addSubgroup(groupName);
                Navigator.pop(context);
              },
              child: const Text('Add Subgroup',
                  style: TextStyle(color: Color(0xFF00391C))),
            ),
          ],
        );
      },
    );
  }

  void _showAddCategoryDialog(List<CategoryModel> existingCategories) {
    final nameCtrl = TextEditingController();
    String selectedColorHex = '#64DD91';
    String selectedIconName = 'shopping_cart';

    final colorOptions = [
      '#64DD91', // Emerald
      '#38BDF8', // Sky Blue
      '#FBBF24', // Amber
      '#F87171', // Rose
      '#A855F7', // Purple
      '#EC4899', // Pink
      '#10B981', // Mint
      '#CBD5E1', // Slate
    ];

    final iconOptions = [
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

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                      controller: nameCtrl,
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
                      children: colorOptions.map((hex) {
                        final isSelected = selectedColorHex == hex;
                        final colorInt =
                            int.parse(hex.replaceFirst('#', '0xFF'));
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedColorHex = hex;
                            });
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(colorInt),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
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
                      children: iconOptions.map((iconName) {
                        final isSelected = selectedIconName == iconName;
                        final dummyCat = CategoryModel(
                          id: '',
                          name: '',
                          colorHex: selectedColorHex,
                          iconName: iconName,
                        );
                        final selectedColor = Color(int.parse(
                            selectedColorHex.replaceFirst('#', '0xFF')));

                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedIconName = iconName;
                            });
                          },
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
                              color: isSelected
                                  ? selectedColor
                                  : AppTheme.textSecondary,
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
                      backgroundColor: AppTheme.primaryEmerald),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;

                    final newCat = CategoryModel(
                      id: '${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      colorHex: selectedColorHex,
                      iconName: selectedIconName,
                    );

                    final updatedList = [...existingCategories, newCat];
                    ref
                        .read(householdControllerProvider.notifier)
                        .updateCategories(updatedList);

                    Navigator.pop(context);
                  },
                  child: const Text('Save Category',
                      style: TextStyle(color: Color(0xFF00391C))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditCategoryDialog(
    CategoryModel cat,
    List<CategoryModel> existingCategories,
  ) {
    final nameCtrl = TextEditingController(text: cat.name);
    String selectedColorHex = cat.colorHex;
    String selectedIconName = cat.iconName;

    final colorOptions = [
      '#64DD91',
      '#38BDF8',
      '#FBBF24',
      '#F87171',
      '#A855F7',
      '#EC4899',
      '#10B981',
      '#CBD5E1',
    ];

    final iconOptions = [
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

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppTheme.glassBorder),
              ),
              title: Text(
                'Edit Category: ${cat.name}',
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
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
                      children: colorOptions.map((hex) {
                        final isSelected = selectedColorHex == hex;
                        final colorInt =
                            int.parse(hex.replaceFirst('#', '0xFF'));
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedColorHex = hex;
                            });
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(colorInt),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
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
                      children: iconOptions.map((iconName) {
                        final isSelected = selectedIconName == iconName;
                        final dummyCat = CategoryModel(
                          id: '',
                          name: '',
                          colorHex: selectedColorHex,
                          iconName: iconName,
                        );
                        final selectedColor = Color(int.parse(
                            selectedColorHex.replaceFirst('#', '0xFF')));

                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              selectedIconName = iconName;
                            });
                          },
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
                              color: isSelected
                                  ? selectedColor
                                  : AppTheme.textSecondary,
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
                      backgroundColor: AppTheme.primaryEmerald),
                  onPressed: () {
                    final newName = nameCtrl.text.trim();
                    if (newName.isEmpty) return;

                    final updatedList = existingCategories.map((c) {
                      if (c.id == cat.id) {
                        return c.copyWith(
                          name: newName,
                          colorHex: selectedColorHex,
                          iconName: selectedIconName,
                        );
                      }
                      return c;
                    }).toList();

                    ref
                        .read(householdControllerProvider.notifier)
                        .updateCategories(updatedList);

                    Navigator.pop(context);
                  },
                  child: const Text('Save Changes',
                      style: TextStyle(color: Color(0xFF00391C))),
                ),
              ],
            );
          },
        );
      },
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

  void _showSubgroupAssignmentDialog(
      UserModel member, Map<String, List<String>> subgroups) {
    String selectedSubgroup = 'None';
    final newSubgroupCtrl = TextEditingController();
    bool isCreatingNewSubgroup = false;

    subgroups.forEach((groupName, memberList) {
      if (memberList.contains(member.uid)) {
        selectedSubgroup = groupName;
      }
    });

    final availableGroupNames =
        <String>{'None', 'Sons', 'Parents', ...subgroups.keys}.toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppTheme.glassBorder),
              ),
              title: Text(
                'Assign Subgroup: ${member.name}',
                style: const TextStyle(color: AppTheme.textPrimary),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...availableGroupNames.map((groupName) {
                      final isSelected = !isCreatingNewSubgroup &&
                          selectedSubgroup == groupName;
                      return GestureDetector(
                        onTap: () => setDialogState(() {
                          isCreatingNewSubgroup = false;
                          selectedSubgroup = groupName;
                        }),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryEmerald.withValues(alpha: 0.2)
                                : const Color(0x0DFFFFFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryEmerald
                                  : const Color(0x1AF8FAFC),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                groupName == 'None'
                                    ? 'Unassigned / None'
                                    : '$groupName Subgroup',
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded,
                                    color: AppTheme.primaryEmerald, size: 20),
                            ],
                          ),
                        ),
                      );
                    }),
                    if (!isCreatingNewSubgroup)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryEmerald,
                            side: const BorderSide(color: AppTheme.primaryEmerald),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            setDialogState(() {
                              isCreatingNewSubgroup = true;
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
                          controller: newSubgroupCtrl,
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
                  child: const Text('Cancel',
                      style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryEmerald),
                  onPressed: () {
                    final updatedSubgroups =
                        Map<String, List<String>>.from(subgroups);

                    // Remove member from all current groups
                    updatedSubgroups.forEach((key, list) {
                      list.remove(member.uid);
                    });

                    String targetGroup = selectedSubgroup;
                    if (isCreatingNewSubgroup) {
                      final newGroupInput = newSubgroupCtrl.text.trim();
                      if (newGroupInput.isNotEmpty) {
                        targetGroup = newGroupInput;
                      }
                    }

                    // Add to selected group if not 'None'
                    if (targetGroup != 'None' && targetGroup.isNotEmpty) {
                      updatedSubgroups.putIfAbsent(targetGroup, () => []);
                      if (!updatedSubgroups[targetGroup]!
                          .contains(member.uid)) {
                        updatedSubgroups[targetGroup]!.add(member.uid);
                      }
                    }

                    ref
                        .read(householdControllerProvider.notifier)
                        .updateSubgroups(updatedSubgroups);

                    Navigator.pop(context);
                  },
                  child: const Text('Save Assignment',
                      style: TextStyle(color: Color(0xFF00391C))),
                ),
              ],
            );
          },
        );
      },
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

    return Scaffold(
      body: Stack(
        children: [
          const RepaintBoundary(
            child: SizedBox.expand(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.8, -0.9),
                    radius: 1.3,
                    colors: [
                      Color(0xFF11253E),
                      Color(0xFF081425),
                      Color(0xFF040E1F),
                    ],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const HatlyHeaderBar(title: 'Settings'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, top: 16, bottom: 100),
                    children: [
                      _buildUserProfileCard(currentUser, isOwner),
                      if (household != null) ...[
                        const SizedBox(height: 20),
                        _buildHouseholdCard(
                          household: household,
                          isOwner: isOwner,
                          pendingState: pendingState,
                          membersState: membersState,
                        ),
                        if (isOwner) ...[
                          const SizedBox(height: 20),
                          _buildCategoryCard(categories),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfileCard(UserModel? currentUser, bool isOwner) {
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
                  fontSize: 10,
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
                      ? AppTheme.primaryEmerald.withValues(alpha: 0.15)
                      : const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: isOwner
                        ? AppTheme.primaryEmerald
                        : AppTheme.glassBorder,
                  ),
                ),
                child: Text(
                  isOwner ? '👑 Owner' : '🛒 Shopper',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isOwner
                        ? AppTheme.primaryEmerald
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
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
                  border: Border.all(
                      color: AppTheme.primaryEmerald, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    currentUser?.name.isNotEmpty == true
                        ? currentUser!.name[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: AppTheme.primaryEmerald,
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
                  backgroundColor: AppTheme.primaryEmerald,
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
                      color: Color(0xFF00391C)),
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
  }) {
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
                        color: AppTheme.primaryEmerald,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    _isCopied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 18,
                    color: AppTheme.primaryEmerald,
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
                  icon: const Icon(Icons.add_rounded,
                      size: 16, color: AppTheme.primaryEmerald),
                  label: const Text(
                    'Add Group',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryEmerald,
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
                  color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: AppTheme.primaryEmerald.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$groupName Subgroup',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryEmerald,
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
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: AppTheme.primaryEmerald,
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
                            color: AppTheme.primaryEmerald,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            '${pendingUsers.length} New',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00391C),
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
                              icon: const Icon(Icons.check_circle_rounded,
                                  color: AppTheme.primaryEmerald),
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
            loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppTheme.primaryEmerald)),
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
                                ? AppTheme.primaryEmerald.withValues(alpha: 0.2)
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
                                    ? AppTheme.primaryEmerald
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
                                  Text(
                                    member.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  if (isMemberAdmin) ...[
                                    const SizedBox(width: 6),
                                    const Text('👑 Admin',
                                        style: TextStyle(
                                            fontSize: 10,
                                            color: AppTheme.primaryEmerald)),
                                  ],
                                ],
                              ),
                              Text(
                                member.email,
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
                                    ? AppTheme.primaryEmerald
                                        .withValues(alpha: 0.15)
                                    : const Color(0x1AFFFFFF),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: memberSubgroup != 'Unassigned'
                                      ? AppTheme.primaryEmerald
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
                                          ? AppTheme.primaryEmerald
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                  if (isOwner) ...[
                                    const SizedBox(width: 4),
                                    const Icon(
                                        Icons.arrow_drop_down_rounded,
                                        size: 16,
                                        color: AppTheme.primaryEmerald),
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

  Widget _buildCategoryCard(List<CategoryModel> categories) {
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
                icon: const Icon(Icons.add_rounded,
                    size: 16, color: AppTheme.primaryEmerald),
                label: const Text(
                  'Add Category',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryEmerald,
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
                    icon: const Icon(Icons.edit_outlined,
                        size: 18, color: AppTheme.textSecondary),
                    onPressed: () =>
                        _showEditCategoryDialog(cat, categories),
                  ),
                  IconButton(
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
}
