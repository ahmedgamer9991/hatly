import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../../core/providers/firebase_providers.dart';
import '../../core/services/notification_service.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/household/presentation/household_controller.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shopping_list/presentation/create_list_screen.dart';
import '../../features/shopping_list/presentation/dashboard_screen.dart';
import '../../features/shopping_list/presentation/history_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _currentIndex = 0;
  StreamSubscription<QuerySnapshot>? _notifSub;
  bool _hasInitializedNotifs = false;
  bool _hasSubscribedTopic = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initNotifications();
    });
  }

  void _initNotifications() {
    if (_hasInitializedNotifs) return;

    final currentUser = ref.read(userProfileProvider).value;
    final household = ref.read(currentHouseholdProvider).value;

    if (currentUser != null) {
      _hasInitializedNotifs = true;
      final notifService = ref.read(notificationServiceProvider);
      notifService.initialize();
      notifService.saveUserFcmToken(currentUser.uid, existingToken: currentUser.fcmToken);

      if (household != null && household.id.isNotEmpty) {
        _hasSubscribedTopic = true;
        notifService.subscribeToHouseholdTopic(household.id);
      }
      _listenToRealtimeNotifications(currentUser.uid);
    }
  }

  void _listenToRealtimeNotifications(String uid) {
    _notifSub?.cancel();
    final firestore = ref.read(firebaseFirestoreProvider);

    // Only listen for new notifications created AFTER the current app session starts
    final subTime = DateTime.now();

    _notifSub = firestore
        .collection('notifications')
        .where('createdAt', isGreaterThanOrEqualTo: subTime)
        .snapshots()
        .listen(
      (snapshot) {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data != null) {
              final senderUid = data['senderUid'] as String? ?? '';
              // Exclude notifications created by current user
              if (senderUid.isNotEmpty && senderUid == uid) continue;

              final recipient = data['recipient'] as String? ?? '';
              final title = data['title'] as String? ?? 'Hatly Notification 🛒';
              final body = data['body'] as String? ?? '';
              final docId = data['id'] as String? ?? change.doc.id;

              final currentUser = ref.read(userProfileProvider).value;
              final currentHousehold = ref.read(currentHouseholdProvider).value;
              final recipientLower = recipient.trim().toLowerCase();

              // Check subgroup/category membership
              bool isInSubgroup = false;
              if (currentHousehold != null && currentHousehold.subgroups.isNotEmpty) {
                currentHousehold.subgroups.forEach((subgroupName, memberUids) {
                  final nameLower = subgroupName.trim().toLowerCase();
                  if (recipientLower == nameLower ||
                      recipientLower == '$nameLower subgroup' ||
                      recipientLower.contains(nameLower)) {
                    if (memberUids.contains(uid)) {
                      isInSubgroup = true;
                    }
                  }
                });
              }

              final isForMe = recipient == uid ||
                  recipientLower == 'all' ||
                  recipientLower == 'everyone' ||
                  recipientLower == 'household' ||
                  isInSubgroup ||
                  (currentUser?.name != null &&
                      currentUser!.name.trim().toLowerCase() == recipientLower);

              if (isForMe && body.isNotEmpty) {
                // Instantly show local notification with deterministic ID to deduplicate with FCM
                ref.read(notificationServiceProvider).showLocalNotification(
                      id: docId.hashCode & 0x7FFFFFFF,
                      title: title,
                      body: body,
                    );
              }
            }
          }
        }
      },
      onError: (error) {
        debugPrint('Firestore notifications stream error (Check Rules): $error');
      },
    );
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProfileProvider);
    final householdState = ref.watch(currentHouseholdProvider);

    final currentUser = userState.value;
    final household = householdState.value;

    // Reactively trigger notification initialization ONCE when user profile or household resolves
    ref.listen(userProfileProvider, (previous, next) {
      if (!_hasInitializedNotifs && next.value != null) {
        _initNotifications();
      }
    });

    ref.listen(currentHouseholdProvider, (previous, next) {
      if (!_hasSubscribedTopic && next.value != null && next.value!.id.isNotEmpty) {
        _hasSubscribedTopic = true;
        ref
            .read(notificationServiceProvider)
            .subscribeToHouseholdTopic(next.value!.id);
      }
    });

    final isOwner = currentUser != null &&
        household != null &&
        (currentUser.uid == household.adminId);

    final List<Widget> pages = isOwner
        ? const [
            DashboardScreen(),
            CreateListScreen(),
            HistoryScreen(),
            SettingsScreen(),
          ]
        : const [
            DashboardScreen(),
            HistoryScreen(),
            SettingsScreen(),
          ];

    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF040E1F),
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xD9081425),
              border: Border(
                top: BorderSide(
                  color: Color(0x26FFFFFF),
                  width: 1,
                ),
              ),
            ),
            padding: EdgeInsets.only(
              top: 10,
              bottom: MediaQuery.of(context).padding.bottom + 6,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: isOwner
                  ? [
                      _NavBarItem(
                        icon: Icons.home_rounded,
                        label: 'Home',
                        isSelected: _currentIndex == 0,
                        onTap: () => setState(() => _currentIndex = 0),
                      ),
                      _NavBarItem(
                        icon: Icons.add_circle_outline_rounded,
                        selectedIcon: Icons.add_circle_rounded,
                        label: 'Create',
                        isSelected: _currentIndex == 1,
                        onTap: () => setState(() => _currentIndex = 1),
                      ),
                      _NavBarItem(
                        icon: Icons.history_rounded,
                        label: 'History',
                        isSelected: _currentIndex == 2,
                        onTap: () => setState(() => _currentIndex = 2),
                      ),
                      _NavBarItem(
                        icon: Icons.settings_outlined,
                        selectedIcon: Icons.settings_rounded,
                        label: 'Settings',
                        isSelected: _currentIndex == 3,
                        onTap: () => setState(() => _currentIndex = 3),
                      ),
                    ]
                  : [
                      _NavBarItem(
                        icon: Icons.home_rounded,
                        label: 'Home',
                        isSelected: _currentIndex == 0,
                        onTap: () => setState(() => _currentIndex = 0),
                      ),
                      _NavBarItem(
                        icon: Icons.history_rounded,
                        label: 'History',
                        isSelected: _currentIndex == 1,
                        onTap: () => setState(() => _currentIndex = 1),
                      ),
                      _NavBarItem(
                        icon: Icons.settings_outlined,
                        selectedIcon: Icons.settings_rounded,
                        label: 'Settings',
                        isSelected: _currentIndex == 2,
                        onTap: () => setState(() => _currentIndex = 2),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppTheme.primaryEmerald;
    final inactiveColor = AppTheme.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? (selectedIcon ?? icon) : icon,
            color: isSelected ? activeColor : inactiveColor,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? activeColor : inactiveColor,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 4,
            width: 4,
            decoration: BoxDecoration(
              color: isSelected ? activeColor : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
