import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/config/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_dialog.dart';
import '../../../core/widgets/hatly_header_bar.dart';
import '../../../core/widgets/reassign_dialog.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../household/domain/category_model.dart';
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Invite code copied!'),
        backgroundColor: primaryColor,
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
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const HatlyHeaderBar(title: 'Hatly'),

            // Scrollable Dashboard Feed
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 16, bottom: 120),
                  children: [
                    // Family Group Glass Banner Card
                    if (currentHousehold != null)
                      GlassCard(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Family Group',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
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

                            // Inset Invite Code Card (Tap to Copy)
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () =>
                                    _copyCode(currentHousehold.inviteCode),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: _isCopied
                                          ? primaryColor.withValues(alpha: 0.6)
                                          : primaryColor.withValues(alpha: 0.25),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'INVITE CODE',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: primaryColor.withValues(alpha: 0.8),
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            currentHousehold.inviteCode,
                                            style: TextStyle(
                                              color: primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 17,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _isCopied
                                              ? primaryColor.withValues(alpha: 0.2)
                                              : const Color(0x14FFFFFF),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          _isCopied
                                              ? Icons.check_rounded
                                              : Icons.copy_rounded,
                                          color: _isCopied
                                              ? primaryColor
                                              : AppTheme.textPrimary,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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
                      loading: () => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(
                              color: primaryColor),
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
    final primaryColor = Theme.of(context).colorScheme.primary;
    final totalItems = list.items.length;
    final boughtItems = list.items.where((i) => i.status == 'bought').length;
    final progress = totalItems > 0 ? boughtItems / totalItems : 0.0;
    final percentInt = (progress * 100).toInt();

    final household = ref.watch(currentHouseholdProvider).value;
    final categories = household?.activeCategories ?? CategoryModel.defaultCategories;

    // Resolve category icon and color based on the first item in the list
    CategoryModel? firstCategory;
    if (list.items.isNotEmpty) {
      final firstItemCat = list.items.first.category.trim();
      firstCategory = categories.firstWhere(
        (c) => c.name.toLowerCase() == firstItemCat.toLowerCase(),
        orElse: () => CategoryModel(
          id: '',
          name: firstItemCat,
          colorHex: '#10B981',
          iconName: 'shopping_bag',
        ),
      );
    } else {
      // Fallback matching on list title
      final titleLower = list.title.toLowerCase();
      firstCategory = categories.firstWhere(
        (c) => titleLower.contains(c.name.toLowerCase()),
        orElse: () => CategoryModel(
          id: '',
          name: 'General',
          colorHex: '#10B981',
          iconName: 'shopping_bag',
        ),
      );
    }

    final IconData cardIcon = firstCategory.iconData;
    final Color cardColor = Color(
      int.parse(firstCategory.colorHex.replaceFirst('#', '0xFF')),
    );

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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Flexible(
                          child: Semantics(
                            button: isOwner,
                            label: isOwner
                                ? 'Assigned to ${list.assignedToName}. Tap to change assignment.'
                                : 'Assigned to ${list.assignedToName}',
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: isOwner
                                    ? () => showReassignListDialog(
                                          context: context,
                                          ref: ref,
                                          list: list,
                                        )
                                    : null,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isOwner
                                        ? primaryColor.withValues(alpha: 0.12)
                                        : const Color(0x14FFFFFF),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isOwner
                                          ? primaryColor.withValues(alpha: 0.3)
                                          : const Color(0x1FFFFFFF),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.person_rounded,
                                        size: 12,
                                        color: isOwner
                                            ? primaryColor
                                            : AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: Text(
                                          list.assignedToName,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isOwner
                                                ? primaryColor
                                                : AppTheme.textSecondary,
                                          ),
                                        ),
                                      ),
                                      if (isOwner) ...[
                                        const SizedBox(width: 2),
                                        Icon(
                                          Icons.arrow_drop_down_rounded,
                                          size: 15,
                                          color: primaryColor,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
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
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0x24FFFFFF),
                    width: 0.8,
                  ),
                ),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0.0, end: progress),
                  builder: (context, animValue, child) {
                    return LinearProgressIndicator(
                      value: animValue,
                      minHeight: 7,
                      backgroundColor: const Color(0x1AFFFFFF),
                      valueColor: AlwaysStoppedAnimation<Color>(cardColor),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
