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

    final currentTheme = ref.watch(activeThemeProvider);
    final bgGradient = ref.watch(activeGradientProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (_currentIndex >= pages.length) {
      _currentIndex = 0;
    }

    return Stack(
      children: [
        // 1. Root full-screen theme gradient that flows behind the entire screen and floating dock
        RepaintBoundary(
          child: SizedBox.expand(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: bgGradient,
              ),
            ),
          ),
        ),

        // 2. Active Screen Content (Full viewport so lists scroll smoothly behind dock)
        Positioned.fill(
          child: IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
        ),

        // 3. True Floating Glass HUD Navigation Dock with 100% transparent surround
        Positioned(
          left: 18,
          right: 18,
          bottom: MediaQuery.of(context).padding.bottom > 0
              ? MediaQuery.of(context).padding.bottom + 4
              : 14,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: currentTheme.backgroundGradient.colors.last
                      .withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.25),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: isOwner
                      ? [
                          _NavBarItem(
                            icon: Icons.home_outlined,
                            selectedIcon:Icons.home_rounded,
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
                            icon: Icons.home_outlined,
                            selectedIcon: Icons.home_rounded,
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
        ),
      ],
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
    final activeColor = Theme.of(context).colorScheme.primary;
    final inactiveColor = AppTheme.textSecondary;

    return Semantics(
      selected: isSelected,
      label: '$label tab',
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 54, minHeight: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Soft Radial Ambient Glow behind Icon
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      width: isSelected ? 38 : 0,
                      height: isSelected ? 38 : 0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isSelected
                            ? RadialGradient(
                                colors: [
                                  activeColor.withValues(alpha: 0.35),
                                  activeColor.withValues(alpha: 0.12),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.55, 1.0],
                              )
                            : null,
                      ),
                    ),
                    Icon(
                      isSelected ? (selectedIcon ?? icon) : icon,
                      color: isSelected ? activeColor : inactiveColor,
                      size: 24,
                      shadows: isSelected
                          ? [
                              Shadow(
                                color: activeColor.withValues(alpha: 0.7),
                                blurRadius: 16,
                              ),
                              Shadow(
                                color: activeColor.withValues(alpha: 0.4),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? activeColor : inactiveColor,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    letterSpacing: 0.2,
                    decoration: TextDecoration.none,
                    shadows: isSelected
                        ? [
                            Shadow(
                              color: activeColor.withValues(alpha: 0.6),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
