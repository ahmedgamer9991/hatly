import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/config/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_dialog.dart';
import '../../../core/widgets/hatly_header_bar.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../household/presentation/household_controller.dart';
import '../domain/shopping_list_model.dart';
import 'shopping_list_controller.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isCopied = false;

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _isCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite code copied!'),
        backgroundColor: AppTheme.primaryEmerald,
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProfileProvider);
    final householdState = ref.watch(currentHouseholdProvider);
    final activeListsState = ref.watch(activeListsProvider);

    final currentUser = userState.value;
    final currentHousehold = householdState.value;

    final isOwner = currentUser != null &&
        currentHousehold != null &&
        (currentUser.uid == currentHousehold.adminId);

    return Scaffold(
      body: Stack(
        children: [
          const RepaintBoundary(
            child: SizedBox.expand(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppTheme.backgroundGradient,
                ),
              ),
            ),
          ),
          SafeArea(
          child: Column(
            children: [
              const HatlyHeaderBar(),

              // Scrollable Dashboard Feed
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 16, bottom: 100),
                  children: [
                    // Family Group Glass Banner Card
                    if (currentHousehold != null)
                      GlassCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Family Group',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryEmerald,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentHousehold.name,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Inset Invite Code Card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0x0DFFFFFF),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0x1AF8FAFC)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'INVITE CODE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textSecondary,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        currentHousehold.inviteCode,
                                        style: const TextStyle(
                                          color: AppTheme.primaryEmerald,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 17,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    onPressed: () =>
                                        _copyCode(currentHousehold.inviteCode),
                                    icon: Icon(
                                      _isCopied
                                          ? Icons.check_rounded
                                          : Icons.copy_rounded,
                                      color: _isCopied
                                          ? AppTheme.primaryEmerald
                                          : AppTheme.textPrimary,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Section Title Header
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'ACTIVE SHOPPING LISTS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondary,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),

                    // Real-Time Active Lists Stream
                    activeListsState.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(
                              color: AppTheme.primaryEmerald),
                        ),
                      ),
                      error: (err, stack) => GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Error loading lists: $err',
                          style: const TextStyle(color: AppTheme.errorRed),
                        ),
                      ),
                      data: (lists) {
                        if (lists.isEmpty) {
                          return GlassCard(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 48,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No active shopping lists',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isOwner
                                      ? 'Tap the "+" tab below to create a new list for your family.'
                                      : 'Waiting for the family owner to create a shopping list.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: lists.map((list) {
                            return _ShoppingListCard(
                              list: list,
                              isOwner: isOwner || currentUser?.uid == list.createdBy,
                              onTap: () {
                                context.push('/shopping-list/${list.id}');
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
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
}

void _confirmDeleteList(
    BuildContext context, WidgetRef ref, ShoppingListModel list) async {
  final confirmed = await showGlassConfirmationDialog(
    context: context,
    title: 'Delete List',
    content:
        'Are you sure you want to delete "${list.title}"? This list will be permanently removed for all family members.',
    confirmLabel: 'Delete List',
    confirmColor: AppTheme.errorRed,
  );

  if (confirmed == true) {
    await ref
        .read(shoppingListControllerProvider.notifier)
        .deleteList(list.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Shopping list "${list.title}" deleted'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }
}

void _showReassignListDialog(
    BuildContext context, WidgetRef ref, ShoppingListModel list) {
  final membersState = ref.read(householdMembersProvider);
  final currentUser = ref.read(userProfileProvider).value;
  final household = ref.read(currentHouseholdProvider).value;
  final currentUid = currentUser?.uid;

  final members = membersState.value ?? [];
  final otherMembers = members.where((m) => m.uid != currentUid).toList();
  final subgroupKeys = <String>{'Sons', 'Parents', ...?household?.subgroups.keys};

  String selectedAssignedTo = list.assignedTo;
  String selectedAssignedToName = list.assignedToName;

  showDialog(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final List<DropdownMenuItem<String>> dropdownItems = [
            const DropdownMenuItem(
              value: 'All|All Family',
              child: Text('All Family'),
            ),
            ...subgroupKeys.map(
              (key) => DropdownMenuItem(
                value: '$key|$key Subgroup',
                child: Text('$key Subgroup'),
              ),
            ),
            ...otherMembers.map(
              (member) => DropdownMenuItem(
                value:
                    '${member.uid}|${member.name.isEmpty ? member.email : member.name}',
                child: Text(member.name.isEmpty ? member.email : member.name),
              ),
            ),
          ];

          final currentValue = '$selectedAssignedTo|$selectedAssignedToName';
          final hasCurrentValue =
              dropdownItems.any((item) => item.value == currentValue);

          return AlertDialog(
            backgroundColor: AppTheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: AppTheme.glassBorder),
            ),
            title: Text(
              'Reassign List: ${list.title}',
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select new recipient or family subgroup:',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue:
                      hasCurrentValue ? currentValue : 'All|All Family',
                  dropdownColor: AppTheme.surfaceContainer,
                  items: dropdownItems.map((item) {
                    return DropdownMenuItem<String>(
                      value: item.value,
                      child: Text(
                        (item.child as Text).data ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppTheme.textPrimary),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      final parts = val.split('|');
                      setDialogState(() {
                        selectedAssignedTo = parts[0];
                        selectedAssignedToName = parts[1];
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryEmerald,
                  foregroundColor: const Color(0xFF00391C),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(shoppingListControllerProvider.notifier)
                      .updateListAssignment(
                        listId: list.id,
                        listTitle: list.title,
                        newAssignedTo: selectedAssignedTo,
                        newAssignedToName: selectedAssignedToName,
                      );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'List reassigned to $selectedAssignedToName!',
                        ),
                        backgroundColor: AppTheme.primaryEmerald,
                      ),
                    );
                  }
                },
                child: const Text('Save & Notify',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    },
  );
}

class _ShoppingListCard extends ConsumerWidget {
  final ShoppingListModel list;
  final bool isOwner;
  final VoidCallback onTap;

  const _ShoppingListCard({
    required this.list,
    required this.isOwner,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalItems = list.items.length;
    final boughtItems = list.items.where((i) => i.status == 'bought').length;
    final progress = totalItems > 0 ? boughtItems / totalItems : 0.0;
    final percentInt = (progress * 100).toInt();

    // Map store category icons based on list items
    IconData cardIcon = Icons.shopping_cart_outlined;
    Color cardColor = AppTheme.supermarketColor;

    if (list.title.toLowerCase().contains('pharmacy') ||
        list.title.toLowerCase().contains('صيدلية')) {
      cardIcon = Icons.local_pharmacy_outlined;
      cardColor = AppTheme.pharmacyColor;
    } else if (list.title.toLowerCase().contains('bakery') ||
        list.title.toLowerCase().contains('مخبز')) {
      cardIcon = Icons.bakery_dining_outlined;
      cardColor = AppTheme.bakeryColor;
    } else if (list.title.toLowerCase().contains('butcher') ||
        list.title.toLowerCase().contains('جزار')) {
      cardIcon = Icons.restaurant_outlined;
      cardColor = AppTheme.butcherColor;
    }

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cardColor.withValues(alpha: 0.3)),
                ),
                child: Icon(cardIcon, color: cardColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Assigned: ${list.assignedToName}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        if (isOwner) ...[
                          const SizedBox(width: 4),
                          Semantics(
                            button: true,
                            label: 'Change assignment for ${list.title}',
                            child: InkWell(
                              onTap: () =>
                                  _showReassignListDialog(context, ref, list),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryEmerald
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                      color: AppTheme.primaryEmerald
                                          .withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.edit_rounded,
                                        size: 11,
                                        color: AppTheme.primaryEmerald),
                                    SizedBox(width: 3),
                                    Text(
                                      'Change',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryEmerald,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (isOwner)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.errorRed,
                    size: 22,
                  ),
                  tooltip: 'Delete List',
                  onPressed: () => _confirmDeleteList(context, ref, list),
                )
              else
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Live Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$boughtItems of $totalItems items bought',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '$percentInt%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cardColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label: 'Shopping list progress',
            value: '$percentInt percent completed',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0.0, end: progress),
                builder: (context, animValue, child) {
                  return LinearProgressIndicator(
                    value: animValue,
                    minHeight: 8,
                    backgroundColor: const Color(0x1AFFFFFF),
                    valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
