# Graph Report - .  (2026-08-09)

## Corpus Check
- 64 files · ~58,613 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 555 nodes · 865 edges · 31 communities (28 shown, 3 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 6 edges (avg confidence: 0.5)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Authentication & User Management
- Authentication & User Management
- Authentication & User Management
- Authentication & User Management
- Authentication & User Management
- Authentication & User Management
- Authentication & User Management
- Authentication & User Management
- Authentication & User Management
- Authentication & User Management
- Subsystem 10
- Authentication & User Management
- Shopping Lists & Utility Controllers
- Subsystem 13
- Authentication & User Management
- Household & Family Group Management
- Visual Assets & Branding
- Authentication & User Management
- Household & Family Group Management
- Subsystem 19
- Subsystem 20
- Shopping Lists & Utility Controllers
- Visual Assets & Branding
- Subsystem 23
- Shopping Lists & Utility Controllers
- Subsystem 25
- Subsystem 26
- Subsystem 30

## God Nodes (most connected - your core abstractions)
1. `currentHouseholdProvider` - 33 edges
2. `userProfileProvider` - 25 edges
3. `householdMembersProvider` - 11 edges
4. `ShoppingListController` - 11 edges
5. `HouseholdRepository` - 10 edges
6. `authControllerProvider` - 9 edges
7. `HouseholdController` - 9 edges
8. `_SettingsScreenState` - 9 edges
9. `ShoppingListRepository` - 9 edges
10. `AuthController` - 8 edges

## Surprising Connections (you probably didn't know these)
- `NotificationService` --implements--> `Push Notifications Spec`  [EXTRACTED]
  lib/core/services/notification_service.dart → docs/specs/hatly-spec.md
- `NotificationService` --shares_data_with--> `Shopping Lists Firestore Schema`  [EXTRACTED]
  lib/core/services/notification_service.dart → docs/specs/hatly-spec.md
- `HatlyApp Widget` --implements--> `Hatly App Spec`  [INFERRED]
  lib/app/app.dart → docs/specs/hatly-spec.md
- `AppSplashScreen Widget` --shares_data_with--> `Household Group Concept`  [INFERRED]
  lib/app/config/router.dart → docs/specs/hatly-spec.md
- `Hatly App Shopping Basket Logo` --conceptually_related_to--> `Web App Manifest Configuration`  [INFERRED]
  assets/images/logo.png → web/manifest.json

## Import Cycles
- None detected.

## Communities (31 total, 3 thin omitted)

### Community 0 - "Authentication & User Management"
Cohesion: 0.06
Nodes (48): AsyncValue, auth_controller.dart, ConsumerStatefulWidget, ../../../core/providers/firebase_providers.dart, ../../../core/widgets/glass_card.dart, ../data/auth_repository.dart, AuthRepository, UserModel (+40 more)

### Community 1 - "Authentication & User Management"
Cohesion: 0.09
Nodes (47): ConsumerState, ../data/household_repository.dart, build, userProfileProvider, HouseholdRepository, CategoryModel, HouseholdModel, addSubgroup (+39 more)

### Community 2 - "Authentication & User Management"
Cohesion: 0.05
Nodes (41): @pragma, app/app.dart, dart:convert, firebase_options.dart, FirebaseMessaging?, FlutterLocalNotificationsPlugin, Push Notifications Spec, Shopping Lists Firestore Schema (+33 more)

### Community 3 - "Authentication & User Management"
Cohesion: 0.05
Nodes (43): ConsumerWidget, ../../../core/widgets/glass_dialog.dart, ../../household/domain/category_model.dart, ../../household/presentation/household_controller.dart, _CategorySection, color, _confirmDeleteList, createState (+35 more)

### Community 4 - "Authentication & User Management"
Cohesion: 0.06
Nodes (36): ../../../core/services/notification_service.dart, ../data/shopping_list_repository.dart, ../domain/shopping_item_model.dart, ../domain/shopping_list_model.dart, addItemToList, completeList, createList, deleteList (+28 more)

### Community 5 - "Authentication & User Management"
Cohesion: 0.06
Nodes (33): ../../auth/domain/user_model.dart, dart:math, ../domain/category_model.dart, ../domain/household_model.dart, ../domain/user_model.dart, FirebaseAuth, FirebaseFirestore, firebaseMessagingProvider (+25 more)

### Community 6 - "Authentication & User Management"
Cohesion: 0.06
Nodes (31): category_model.dart, DateTime, activeCategories, adminId, copyWith, createdAt, customCategories, fromMap (+23 more)

### Community 7 - "Authentication & User Management"
Cohesion: 0.07
Nodes (29): ../../auth/presentation/auth_controller.dart, class, ../../../core/widgets/hatly_header_bar.dart, FormState, household_controller.dart, _codeController, _createFormKey, createState (+21 more)

### Community 8 - "Authentication & User Management"
Cohesion: 0.08
Nodes (24): Animation, AnimationController, ../../features/auth/domain/user_model.dart, ../../features/auth/presentation/login_screen.dart, ../../features/household/presentation/household_setup_screen.dart, ../../features/household/presentation/manage_household_screen.dart, ../../features/shopping_list/presentation/active_list_screen.dart, GoRouter (+16 more)

### Community 9 - "Authentication & User Management"
Cohesion: 0.09
Nodes (23): dart:async, ../../features/auth/presentation/auth_controller.dart, ../../features/household/presentation/household_controller.dart, ../../features/settings/presentation/settings_screen.dart, ../../features/shopping_list/presentation/create_list_screen.dart, ../../features/shopping_list/presentation/dashboard_screen.dart, ../../features/shopping_list/presentation/history_screen.dart, IconData (+15 more)

### Community 10 - "Subsystem 10"
Cohesion: 0.10
Nodes (19): Hatly App Spec, HatlyApp Widget, AppTheme, backgroundCanvas, bakeryColor, butcherColor, deepSlate, errorRed (+11 more)

### Community 11 - "Authentication & User Management"
Cohesion: 0.11
Nodes (17): copyWith, email, fcmToken, fromMap, householdId, name, toMap, uid (+9 more)

### Community 12 - "Shopping Lists & Utility Controllers"
Cohesion: 0.11
Nodes (18): _addItem, color, createState, dispose, _formKey, icon, isSelected, _itemInputController (+10 more)

### Community 13 - "Subsystem 13"
Cohesion: 0.14
Nodes (13): dart:ui, EdgeInsetsGeometry?, blur, borderColor, borderRadius, build, child, fillColor (+5 more)

### Community 14 - "Authentication & User Management"
Cohesion: 0.14
Nodes (10): package:flutter_test/flutter_test.dart, package:hatly/features/auth/domain/user_model.dart, package:hatly/features/household/domain/household_model.dart, package:hatly/features/shopping_list/domain/shopping_item_model.dart, package:hatly/features/shopping_list/domain/shopping_list_model.dart, package:hatly/features/shopping_list/utils/whatsapp_parser.dart, main, main (+2 more)

### Community 15 - "Household & Family Group Management"
Cohesion: 0.20
Nodes (10): ChangeNotifier, config/router.dart, ../config/theme.dart, Household Group Concept, build, HatlyApp, AppSplashScreen Widget, RouterNotifier (+2 more)

### Community 16 - "Visual Assets & Branding"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 17 - "Authentication & User Management"
Cohesion: 0.22
Nodes (10): _listenToRealtimeNotifications, AppSplashScreen, _AppSplashScreenState, _startSplashTimer, firebaseAuthProvider, firebaseFirestoreProvider, Route /, Route /household-setup (+2 more)

### Community 18 - "Household & Family Group Management"
Cohesion: 0.20
Nodes (9): colorHex, copyWith, defaultCategories, fromMap, iconName, id, name, toMap (+1 more)

### Community 19 - "Subsystem 19"
Cohesion: 0.29
Nodes (6): ../../../app/config/theme.dart, build, leading, title, trailing, Widget

### Community 20 - "Subsystem 20"
Cohesion: 0.29
Nodes (6): Color, cancelLabel, confirmColor, confirmLabel, showGlassConfirmationDialog, required String content,
  String

### Community 21 - "Shopping Lists & Utility Controllers"
Cohesion: 0.29
Nodes (7): _NavBarItem, CategoryBadge, GlassCard, HatlyHeaderBar, _CategoryPillChoice, _CategorySelectorPill, StatelessWidget

### Community 22 - "Visual Assets & Branding"
Cohesion: 0.29
Nodes (6): build, categoryName, compact, _getCategoryColor, _getCategoryIcon, package:flutter/material.dart

### Community 23 - "Subsystem 23"
Cohesion: 0.33
Nodes (5): handle_new_rx_page(), __lldb_init_module(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages., SBDebugger, SBFrame

### Community 24 - "Shopping Lists & Utility Controllers"
Cohesion: 0.40
Nodes (5): Hatly App Shopping Basket Logo, Web App Icon 192x192, Web App Icon 512x512, Flutter Web Favicon, Web App Manifest Configuration

## Knowledge Gaps
- **300 isolated node(s):** `flutter_export_environment.sh script`, `+registerWithRegistry`, `_currentIndex`, `_notifSub`, `icon` (+295 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **3 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `userProfileProvider` connect `Authentication & User Management` to `Authentication & User Management`, `Authentication & User Management`, `Authentication & User Management`, `Authentication & User Management`?**
  _High betweenness centrality (0.036) - this node is a cross-community bridge._
- **Why does `ShoppingListModel` connect `Authentication & User Management` to `Authentication & User Management`, `Authentication & User Management`?**
  _High betweenness centrality (0.035) - this node is a cross-community bridge._
- **Why does `UserModel` connect `Authentication & User Management` to `Authentication & User Management`, `Authentication & User Management`?**
  _High betweenness centrality (0.032) - this node is a cross-community bridge._
- **What connects `flutter_export_environment.sh script`, `+registerWithRegistry`, `_currentIndex` to the rest of the system?**
  _300 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Authentication & User Management` be split into smaller, more focused modules?**
  _Cohesion score 0.060408163265306125 - nodes in this community are weakly interconnected._
- **Should `Authentication & User Management` be split into smaller, more focused modules?**
  _Cohesion score 0.08687943262411348 - nodes in this community are weakly interconnected._
- **Should `Authentication & User Management` be split into smaller, more focused modules?**
  _Cohesion score 0.04830917874396135 - nodes in this community are weakly interconnected._