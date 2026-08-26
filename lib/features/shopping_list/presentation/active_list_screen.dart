import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/config/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/glass_dialog.dart';
import '../../../core/widgets/hatly_header_bar.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../household/domain/category_model.dart';
import '../../household/presentation/household_controller.dart';
import '../domain/shopping_item_model.dart';
import '../domain/shopping_list_model.dart';
import 'shopping_list_controller.dart';

class ActiveListScreen extends ConsumerStatefulWidget {
  final String listId;

  const ActiveListScreen({
    super.key,
    required this.listId,
  });

  @override
  ConsumerState<ActiveListScreen> createState() => _ActiveListScreenState();
}

class _ActiveListScreenState extends ConsumerState<ActiveListScreen> {
  final _quickAddController = TextEditingController();
  String _selectedCategory = 'Supermarket';

  @override
  void dispose() {
    _quickAddController.dispose();
    super.dispose();
  }

  void _addItem() async {
    final text = _quickAddController.text.trim();
    if (text.isEmpty) return;

    _quickAddController.clear();
    await ref.read(shoppingListControllerProvider.notifier).addItemToList(
          listId: widget.listId,
          name: text,
          category: _selectedCategory,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ "$text" added to list'),
          backgroundColor: AppTheme.primaryEmerald,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _confirmDeleteList(String listTitle) async {
    final confirmed = await showGlassConfirmationDialog(
      context: context,
      title: 'Delete List',
      content:
          'Are you sure you want to delete "$listTitle"? This list will be permanently removed for all family members.',
      confirmLabel: 'Delete List',
      confirmColor: AppTheme.errorRed,
    );

    if (confirmed == true) {
      await ref
          .read(shoppingListControllerProvider.notifier)
          .deleteList(widget.listId);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shopping list "$listTitle" deleted'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _sendUpdateNotification(String listTitle, String assignedTo, String assignedToName) {
    ref.read(shoppingListControllerProvider.notifier).notifyListUpdated(
          listId: widget.listId,
          listTitle: listTitle,
          assignedTo: assignedTo,
          assignedToName: assignedToName,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ List updated! Notification sent to $assignedToName'),
        backgroundColor: AppTheme.primaryEmerald,
      ),
    );
  }

  void _showReassignDialog(ShoppingListModel list) {
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
                            '✓ List reassigned to $selectedAssignedToName!',
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

  void _showOutOfStockDialog(
    BuildContext context,
    ShoppingItemModel item,
  ) {
    final noteController = TextEditingController(text: item.note ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.glassBorder),
          ),
          title: Text(
            'Out of Stock: ${item.name}',
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add a quick note for the list creator (e.g. out of stock, bought smaller size...):',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Comment / Note',
                  hintText: 'e.g. Only 500g box available...',
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
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
              onPressed: () {
                ref
                    .read(shoppingListControllerProvider.notifier)
                    .updateItemStatus(
                      listId: widget.listId,
                      itemId: item.id,
                      status: 'outOfStock',
                      note: noteController.text,
                    );
                Navigator.pop(context);
              },
              child: const Text('Flag Out of Stock',
                  style: TextStyle(color: Color(0xFF690005))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(singleListProvider(widget.listId));
    final household = ref.watch(currentHouseholdProvider).value;
    final currentUser = ref.watch(userProfileProvider).value;

    final categories = household?.activeCategories ?? CategoryModel.defaultCategories;

    return listState.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryEmerald),
        ),
      ),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text('Error: $err', style: const TextStyle(color: AppTheme.errorRed)),
        ),
      ),
      data: (list) {
        if (list == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('List Not Found')),
            body: const Center(
              child: Text('Shopping list not found',
                  style: TextStyle(color: AppTheme.textSecondary)),
            ),
          );
        }

        final isOwner = currentUser?.uid == household?.adminId ||
            currentUser?.uid == list.createdBy;

        final totalItems = list.items.length;
        final boughtItems =
            list.items.where((i) => i.status == 'bought').length;
        final progress = totalItems > 0 ? boughtItems / totalItems : 0.0;
        final percentInt = (progress * 100).toInt();

        // Dynamically group items by categories
        final Map<String, List<ShoppingItemModel>> groupedItems = {};
        for (var cat in categories) {
          groupedItems[cat.name] = [];
        }

        for (var item in list.items) {
          if (groupedItems.containsKey(item.category)) {
            groupedItems[item.category]!.add(item);
          } else {
            groupedItems.putIfAbsent(item.category, () => []).add(item);
          }
        }

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
                  HatlyHeaderBar(
                    title: list.title,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary),
                      onPressed: () => Navigator.pop(context),
                    ),
                    trailing: isOwner
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppTheme.errorRed,
                                  size: 22,
                                ),
                                tooltip: 'Delete List',
                                onPressed: () => _confirmDeleteList(list.title),
                              ),
                              const SizedBox(width: 4),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryEmerald,
                                  foregroundColor: const Color(0xFF00391C),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  minimumSize: const Size(48, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () => _sendUpdateNotification(
                                  list.title,
                                  list.assignedTo,
                                  list.assignedToName,
                                ),
                                icon: const Icon(
                                    Icons.notifications_active_rounded,
                                    size: 18),
                                label: const Text(
                                  'Update',
                                  style: TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),

                  // Top Live Progress Banner Card
                  GlassCard(
                    margin: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryEmerald,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      isOwner
                                          ? 'Real-Time Monitoring'
                                          : 'Live Progress: $percentInt%',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$boughtItems of $totalItems bought',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: AppTheme.primaryEmerald,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Semantics(
                          label: 'Shopping progress',
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
                                  minHeight: 10,
                                  backgroundColor: const Color(0x1AFFFFFF),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                      AppTheme.primaryEmerald),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.person_outline_rounded,
                                      size: 13, color: AppTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Assigned to: ${list.assignedToName}',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (isOwner)
                              Semantics(
                                button: true,
                                label: 'Reassign list from ${list.assignedToName}',
                                child: InkWell(
                                  onTap: () => _showReassignDialog(list),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryEmerald
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: AppTheme.primaryEmerald
                                              .withValues(alpha: 0.3)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.swap_horiz_rounded,
                                            size: 14,
                                            color: AppTheme.primaryEmerald),
                                        SizedBox(width: 4),
                                        Text(
                                          'Change',
                                          style: TextStyle(
                                            fontSize: 12,
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
                        ),
                      ],
                    ),
                  ),

                  // Grouped Items Checklist Stream
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        ...groupedItems.entries.map((entry) {
                          final catName = entry.key;
                          final catItems = entry.value;
                          if (catItems.isEmpty) return const SizedBox.shrink();

                          final match = categories.firstWhere(
                            (c) => c.name == catName,
                            orElse: () => CategoryModel(
                              id: '',
                              name: catName,
                              colorHex: '#CBD5E1',
                              iconName: 'shopping_bag',
                            ),
                          );

                          final catColor = Color(
                              int.parse(match.colorHex.replaceFirst('#', '0xFF')));

                          return _CategorySection(
                            title: catName,
                            color: catColor,
                            items: catItems,
                            listId: widget.listId,
                            isOwner: isOwner,
                            onOutOfStockTap: (item) =>
                                _showOutOfStockDialog(context, item),
                          );
                        }),
                        const SizedBox(height: 140),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

          // Bottom Bar (Finish Shopping for Shopper OR Live Add Item Bar for Owner)
          bottomSheet: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceContainer,
              border: Border(top: BorderSide(color: AppTheme.glassBorder)),
            ),
            child: isOwner
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dynamic Category Selector Pills Bar for Owner
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: categories.map((cat) {
                            final catColor = Color(int.parse(
                                cat.colorHex.replaceFirst('#', '0xFF')));
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: _CategoryPillChoice(
                                label: cat.name,
                                color: catColor,
                                isSelected: _selectedCategory == cat.name,
                                onTap: () => setState(
                                    () => _selectedCategory = cat.name),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _quickAddController,
                              style: const TextStyle(color: AppTheme.textPrimary),
                              decoration: const InputDecoration(
                                hintText: 'Add item to live list...',
                              ),
                              onSubmitted: (_) => _addItem(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.primaryEmerald,
                              minimumSize: const Size(48, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded,
                                color: Color(0xFF00391C)),
                            onPressed: _addItem,
                          ),
                        ],
                      ),
                    ],
                  )
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryEmerald,
                      foregroundColor: const Color(0xFF00391C),
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    onPressed: () {
                      ref
                          .read(shoppingListControllerProvider.notifier)
                          .completeList(widget.listId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Shopping trip finished! List moved to History.'),
                          backgroundColor: AppTheme.primaryEmerald,
                        ),
                      );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text(
                      'Finish Shopping & Archive List',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class _CategoryPillChoice extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryPillChoice({
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      button: true,
      label: '$label category',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.25) : const Color(0x0DFFFFFF),
            border: Border.all(color: isSelected ? color : const Color(0x1AF8FAFC)),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? color : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategorySection extends ConsumerWidget {
  final String title;
  final Color color;
  final List<ShoppingItemModel> items;
  final String listId;
  final bool isOwner;
  final Function(ShoppingItemModel) onOutOfStockTap;

  const _CategorySection({
    required this.title,
    required this.color,
    required this.items,
    required this.listId,
    required this.isOwner,
    required this.onOutOfStockTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
        ),
        ...items.map((item) {
          final isBought = item.status == 'bought';
          final isOutOfStock = item.status == 'outOfStock';

          return GlassCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Status Check Indicator with 48x48dp Touch Target & Semantics
                Semantics(
                  checked: isBought,
                  label: '${isBought ? "Mark as pending" : "Mark as bought"} ${item.name}',
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isOwner
                        ? null // Owner is in read-only monitoring mode
                        : () {
                            final newStatus = isBought ? 'pending' : 'bought';
                            ref
                                .read(shoppingListControllerProvider.notifier)
                                .updateItemStatus(
                                  listId: listId,
                                  itemId: item.id,
                                  status: newStatus,
                                );
                          },
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isBought
                              ? AppTheme.primaryEmerald
                              : (isOutOfStock
                                  ? AppTheme.errorRed.withValues(alpha: 0.2)
                                  : Colors.transparent),
                          border: Border.all(
                            color: isBought
                                ? AppTheme.primaryEmerald
                                : (isOutOfStock
                                    ? AppTheme.errorRed
                                    : AppTheme.textSecondary.withValues(alpha: 0.5)),
                            width: 2,
                          ),
                        ),
                        child: isBought
                            ? const Icon(Icons.check_rounded,
                                size: 16, color: Color(0xFF00391C))
                            : (isOutOfStock
                                ? const Icon(Icons.close_rounded,
                                    size: 16, color: AppTheme.errorRed)
                                : null),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isBought
                              ? AppTheme.textSecondary
                              : AppTheme.textPrimary,
                          decoration:
                              isBought ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if (item.note != null && item.note!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Note: ${item.note}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.errorRed,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isOwner)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppTheme.errorRed, size: 20),
                    tooltip: 'Remove item "${item.name}"',
                    onPressed: () {
                      ref
                          .read(shoppingListControllerProvider.notifier)
                          .removeItemFromList(
                            listId: listId,
                            itemId: item.id,
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Item "${item.name}" removed'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  )
                else if (!isBought)
                  IconButton(
                    tooltip: 'Report out of stock',
                    icon: Icon(
                      Icons.warning_amber_rounded,
                      color: isOutOfStock
                          ? AppTheme.errorRed
                          : AppTheme.textSecondary,
                      size: 22,
                    ),
                    onPressed: () => onOutOfStockTap(item),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
