import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/config/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_dialog.dart';
import '../../../core/widgets/hatly_header_bar.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../household/domain/category_model.dart';
import '../../household/presentation/household_controller.dart';
import '../domain/shopping_list_model.dart';
import 'shopping_list_controller.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  void _showCompletedListItemsDialog(
    BuildContext context,
    ShoppingListModel list,
    List<CategoryModel> categories,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.glassBorder),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  list.title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primaryEmerald,
                size: 22,
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assigned to: ${list.assignedToName} • ${list.items.length} items',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...list.items.map((item) {
                    final match = categories.firstWhere(
                      (c) => c.name == item.category,
                      orElse: () => CategoryModel(
                        id: '',
                        name: item.category,
                        colorHex: '#CBD5E1',
                        iconName: 'shopping_bag',
                      ),
                    );
                    final catColor = Color(
                      int.parse(match.colorHex.replaceFirst('#', '0xFF')),
                    );

                    final isBought = item.status == 'bought';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0x0DFFFFFF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0x1AF8FAFC)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isBought
                                ? Icons.check_circle_rounded
                                : Icons.remove_circle_outline_rounded,
                            size: 18,
                            color: isBought
                                ? AppTheme.primaryEmerald
                                : AppTheme.errorRed,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppTheme.textPrimary,
                                    decoration: isBought
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                if (item.note != null && item.note!.isNotEmpty)
                                  Text(
                                    'Note: ${item.note}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.errorRed,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Text(
                              item.category,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: catColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Close',
                style: TextStyle(color: AppTheme.primaryEmerald),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteList(
    BuildContext context,
    WidgetRef ref,
    ShoppingListModel list,
  ) async {
    final confirmed = await showGlassConfirmationDialog(
      context: context,
      title: 'Delete History List',
      content:
          'Are you sure you want to delete "${list.title}" from history? This action cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: AppTheme.errorRed,
    );

    if (confirmed == true) {
      await ref
          .read(shoppingListControllerProvider.notifier)
          .deleteList(list.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('History list "${list.title}" deleted'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    final currentUser = ref.watch(userProfileProvider).value;

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
              const HatlyHeaderBar(title: 'History & Archive'),
              Expanded(
                child: household == null
                    ? const Center(
                        child: Text(
                          'No active household selected',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : StreamBuilder<List<ShoppingListModel>>(
                        stream: ref
                            .watch(shoppingListRepositoryProvider)
                            .watchCompletedHouseholdLists(household.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryEmerald,
                              ),
                            );
                          }

                          final completedLists = snapshot.data ?? [];

                          if (completedLists.isEmpty) {
                            return Center(
                              child: GlassCard(
                                margin: const EdgeInsets.all(32),
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.history_toggle_off_rounded,
                                      size: 56,
                                      color: AppTheme.primaryEmerald
                                          .withValues(alpha: 0.6),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No Completed Lists Yet',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      isOwner
                                          ? 'When shopping trips are completed, they will appear here for easy 1-tap re-ordering.'
                                          : 'When shopping trips are completed, they will appear here in your trip history archive.',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 12,
                              bottom: 100,
                            ),
                            itemCount: completedLists.length,
                            itemBuilder: (context, index) {
                              final list = completedLists[index];
                              final dateStr =
                                  '${list.createdAt.day}/${list.createdAt.month}/${list.createdAt.year}';

                              return GlassCard(
                                margin: const EdgeInsets.only(bottom: 12),
                                onTap: () => _showCompletedListItemsDialog(
                                  context,
                                  list,
                                  categories,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            list.title,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        if (isOwner)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              color: AppTheme.errorRed,
                                              size: 20,
                                            ),
                                            tooltip: 'Delete List',
                                            onPressed: () =>
                                                _confirmDeleteList(
                                                    context, ref, list),
                                          ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryEmerald
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color: AppTheme.primaryEmerald
                                                  .withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: const Text(
                                            'Completed ✓',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryEmerald,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${list.items.length} items • Completed on $dateStr',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    if (isOwner) ...[
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            side: BorderSide(
                                              color: AppTheme.primaryEmerald
                                                  .withValues(alpha: 0.5),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () async {
                                            // Duplicate & Re-Send List
                                            await ref
                                                .read(
                                                  shoppingListControllerProvider
                                                      .notifier,
                                                )
                                                .createList(
                                                  title:
                                                      '${list.title} (Re-order)',
                                                  assignedTo: list.assignedTo,
                                                  assignedToName:
                                                      list.assignedToName,
                                                  items: list.items
                                                      .map(
                                                        (item) => item.copyWith(
                                                          status: 'pending',
                                                          note: null,
                                                        ),
                                                      )
                                                      .toList(),
                                                );

                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'List duplicated and re-sent!',
                                                  ),
                                                  backgroundColor:
                                                      AppTheme.primaryEmerald,
                                                ),
                                              );
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.replay_rounded,
                                            size: 18,
                                            color: AppTheme.primaryEmerald,
                                          ),
                                          label: const Text(
                                            'Duplicate & Re-Send List',
                                            style: TextStyle(
                                              color: AppTheme.primaryEmerald,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          );
                        },
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
