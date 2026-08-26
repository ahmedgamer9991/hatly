import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/config/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/hatly_header_bar.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../household/domain/category_model.dart';
import '../../household/presentation/household_controller.dart';
import '../domain/shopping_item_model.dart';
import '../utils/whatsapp_parser.dart';
import 'shopping_list_controller.dart';

class CreateListScreen extends ConsumerStatefulWidget {
  const CreateListScreen({super.key});

  @override
  ConsumerState<CreateListScreen> createState() => _CreateListScreenState();
}

class _CreateListScreenState extends ConsumerState<CreateListScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _itemInputController = TextEditingController();
  final _whatsappTextController = TextEditingController();

  String _selectedAssignedTo = 'All';
  String _selectedAssignedToName = 'All Family';
  String _selectedCategory = 'Supermarket';

  final List<ShoppingItemModel> _items = [];

  @override
  void dispose() {
    _titleController.dispose();
    _itemInputController.dispose();
    _whatsappTextController.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _itemInputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _items.add(
        ShoppingItemModel(
          id: '${DateTime.now().millisecondsSinceEpoch}_${_items.length}',
          name: text,
          category: _selectedCategory,
        ),
      );
      _itemInputController.clear();
    });
  }

  void _openWhatsAppImportDialog() {
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
            'Parse Bulk Text / WhatsApp',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Paste raw shopping list text or WhatsApp message below. Hatly will automatically extract and categorize items:',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _whatsappTextController,
                  maxLines: 6,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: '1. 2kg Tomatoes\n2. Panadol Cold & Flu\n- 6 Fresh Croissants',
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
              onPressed: () {
                final parsed = WhatsAppParser.parseRawText(
                  _whatsappTextController.text,
                );
                if (parsed.isNotEmpty) {
                  setState(() {
                    _items.addAll(parsed);
                  });
                  _whatsappTextController.clear();
                }
                Navigator.pop(context);
              },
              child: const Text('Parse & Add Items'),
            ),
          ],
        );
      },
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item to the shopping list'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await ref.read(shoppingListControllerProvider.notifier).createList(
          title: _titleController.text,
          assignedTo: _selectedAssignedTo,
          assignedToName: _selectedAssignedToName,
          items: List.from(_items),
        );

    final resultState = ref.read(shoppingListControllerProvider);

    if (mounted) {
      if (resultState.hasError) {
        String errorMsg = resultState.error.toString();
        if (!errorMsg.contains('PigeonUserDetails')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error creating list: $errorMsg'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Shopping list created successfully!'),
            backgroundColor: AppTheme.primaryEmerald,
          ),
        );
        _titleController.clear();
        setState(() {
          _items.clear();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final membersState = ref.watch(householdMembersProvider);
    final state = ref.watch(shoppingListControllerProvider);
    final household = ref.watch(currentHouseholdProvider).value;

    final categories = household?.activeCategories ?? CategoryModel.defaultCategories;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
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
        child: SafeArea(
          child: Column(
            children: [
              const HatlyHeaderBar(title: 'Create List'),

              // Form Scrollable Feed
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(
                      left: 16, right: 16, top: 16, bottom: 100),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Section 1: "List Details Card"
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'LIST DETAILS',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _titleController,
                                style: const TextStyle(color: AppTheme.textPrimary),
                                decoration: const InputDecoration(
                                  hintText: 'List Title or Store Name',
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter a list title';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'ASSIGN TO',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              membersState.when(
                                loading: () => const SizedBox.shrink(),
                                error: (error, stackTrace) =>
                                    const SizedBox.shrink(),
                                data: (members) {
                                   final currentUser = ref.watch(userProfileProvider).value;
                                   final household = ref.watch(currentHouseholdProvider).value;
                                   final currentUid = currentUser?.uid;

                                   final otherMembers = members
                                       .where((m) => m.uid != currentUid)
                                       .toList();

                                   final subgroupKeys = <String>{'Sons', 'Parents', ...?household?.subgroups.keys};

                                   final List<DropdownMenuItem<String>>
                                       dropdownItems = [
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
                                         child: Text(member.name.isEmpty
                                             ? member.email
                                             : member.name),
                                       ),
                                     ),
                                   ];

                                  return DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    initialValue:
                                        '$_selectedAssignedTo|$_selectedAssignedToName',
                                    dropdownColor: AppTheme.surfaceContainer,
                                    items: dropdownItems.map((item) {
                                      return DropdownMenuItem<String>(
                                        value: item.value,
                                        child: Text(
                                          (item.child as Text).data ?? '',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: AppTheme.textPrimary),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        final parts = val.split('|');
                                        setState(() {
                                          _selectedAssignedTo = parts[0];
                                          _selectedAssignedToName = parts[1];
                                        });
                                      }
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Section 2: "QUICK ADD" Card with Dynamic Category Selector Pills
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'QUICK ADD',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Dynamic Category Selector Pills Row
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: categories.map((cat) {
                                    final catColor = Color(int.parse(
                                        cat.colorHex.replaceFirst('#', '0xFF')));
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: _CategorySelectorPill(
                                        icon: cat.iconData,
                                        label: cat.name,
                                        color: catColor,
                                        isSelected:
                                            _selectedCategory == cat.name,
                                        onTap: () => setState(
                                            () => _selectedCategory = cat.name),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Item Input Box & Add Button Row
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _itemInputController,
                                      style: const TextStyle(
                                          color: AppTheme.textPrimary),
                                      decoration: const InputDecoration(
                                        hintText:
                                            'Type item (e.g. 2kg Tomatoes)',
                                      ),
                                      onFieldSubmitted: (_) => _addItem(),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton.filled(
                                    tooltip: 'Add item to list',
                                    style: IconButton.styleFrom(
                                      backgroundColor: AppTheme.primaryEmerald
                                          .withValues(alpha: 0.2),
                                      side: const BorderSide(
                                          color: AppTheme.primaryEmerald),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      minimumSize: const Size(48, 48),
                                    ),
                                    onPressed: _addItem,
                                    icon: const Icon(
                                      Icons.add_rounded,
                                      color: AppTheme.primaryEmerald,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Parse Bulk Text / WhatsApp Button
                              Center(
                                child: TextButton.icon(
                                  onPressed: _openWhatsAppImportDialog,
                                  icon: const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 16,
                                    color: AppTheme.primaryEmerald,
                                  ),
                                  label: const Text(
                                    'OR PARSE BULK TEXT',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryEmerald,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section 3: "Detected Items" Feed Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Detected Items',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              '${_items.length} items',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Items Feed List
                        if (_items.isEmpty)
                          GlassCard(
                            padding: const EdgeInsets.all(28),
                            child: const Center(
                              child: Text(
                                'No items added yet. Type an item above or tap "OR PARSE BULK TEXT".',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _items.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              final match = categories.firstWhere(
                                (c) => c.name == item.category,
                                orElse: () => CategoryModel(
                                  id: '',
                                  name: item.category,
                                  colorHex: '#CBD5E1',
                                  iconName: 'shopping_bag',
                                ),
                              );
                              final catColor = Color(int.parse(
                                  match.colorHex.replaceFirst('#', '0xFF')));

                              return GlassCard(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: catColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: catColor.withValues(alpha: 0.3)),
                                      ),
                                      child: Icon(match.iconData,
                                          color: catColor, size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: catColor.withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                              border: Border.all(
                                                  color: catColor.withValues(
                                                      alpha: 0.3)),
                                            ),
                                            child: Text(
                                              item.category,
                                              style: TextStyle(
                                                color: catColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Delete "${_items[index].name}"',
                                      icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: AppTheme.errorRed,
                                          size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _items.removeAt(index);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 28),

                        // Bottom Submit Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryEmerald,
                            foregroundColor: const Color(0xFF00391C),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 4,
                            shadowColor: AppTheme.primaryEmerald
                                .withValues(alpha: 0.4),
                          ),
                          onPressed: state.isLoading ? null : _submit,
                          icon: state.isLoading
                              ? const SizedBox.shrink()
                              : const Icon(Icons.near_me_rounded, size: 20),
                          label: state.isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF00391C),
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Create & Send List',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
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
      ),
    );
  }
}

class _CategorySelectorPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategorySelectorPill({
    required this.icon,
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.22) : const Color(0x0DFFFFFF),
            border: Border.all(
              color: isSelected ? color : const Color(0x1AF8FAFC),
            ),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: isSelected ? color : AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? color : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
