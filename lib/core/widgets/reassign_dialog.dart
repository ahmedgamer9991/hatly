import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/config/theme.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/household/presentation/household_controller.dart';
import '../../features/shopping_list/domain/shopping_list_model.dart';
import '../../features/shopping_list/presentation/shopping_list_controller.dart';

/// Centralized helper to display the Reassign List dialog across screens.
Future<void> showReassignListDialog({
  required BuildContext context,
  required WidgetRef ref,
  required ShoppingListModel list,
}) async {
  final membersState = ref.read(householdMembersProvider);
  final currentUser = ref.read(userProfileProvider).value;
  final household = ref.read(currentHouseholdProvider).value;
  final currentUid = currentUser?.uid;

  final members = membersState.value ?? [];
  final otherMembers = members.where((m) => m.uid != currentUid).toList();
  final subgroupKeys = <String>{'Sons', 'Parents', ...?household?.subgroups.keys};

  String selectedAssignedTo = list.assignedTo;
  String selectedAssignedToName = list.assignedToName;

  return showDialog(
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
              overflow: TextOverflow.ellipsis,
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
