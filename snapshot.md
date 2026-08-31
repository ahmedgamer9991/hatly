# Project Snapshot — Hatly (`snapshot.md`)
*Last Updated: 2026-08-28*

---

## 🟢 Status & Quality Metrics
- **Static Analysis:** `flutter analyze` ➔ **0 errors, 0 warnings**
- **Unit Tests:** `flutter test` ➔ **23/23 passed** across 7 test suites (`theme_preset_test`, `category_model_test`, `notification_payload_test`, `household_model_test`, `shopping_list_model_test`, `user_model_test`, `whatsapp_parser_test`).
- **Luminous Halo Navigation Dock:** True Floating HUD Overlay (`Stack` architecture) with 100% transparent side/bottom gaps and continuous pass-through scrolling (lists scroll completely underneath and past the dock), real-time backdrop blur (`sigma: 25`), dynamic theme surface tint (`theme.backgroundGradient.colors.last`), floating capsule geometry (`borderRadius: 32`), and borderless active tab luminous halo glow (radial ambient light behind icon with icon/text drop shadows).
- **Dynamic Category Icons & Interactive Assignment Chips:** Dashboard active shopping list cards dynamically resolve first-item category store icons/colors, feature merged interactive assignment pills (`[ 👤 Name ▾ ]`) with direct tap-to-reassign modal triggers, and enhanced 0% progress track border affordances.
- **100% Theme-Adaptive & Floating SnackBars:** Global floating SnackBar system (`SnackBarBehavior.floating`, `insetPadding: bottom 90`) elevated cleanly above the floating navigation dock with dynamic theme accent adaptation (`primary`, `onPrimary`, `surfaceContainer`, `elevation: 8`).
- **Interactive Invite Code Banner:** Tap-anywhere copy-to-clipboard invite code card with theme-accent sheen, tactile ripple, and copy status micro-feedback.
- **10-Theme Dynamic Switcher:** 10 curated Glassmorphic themes (`theme_presets.dart`) with instant live preview, `SharedPreferences` persistence (`theme_controller.dart`), and reactive `activeGradientProvider` across all 9 screens.
- **Theme Centralization:** 100% centralized single-file theme architecture via [`AppTheme`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/app/config/theme.dart) + [`ThemePreset`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/app/config/theme_presets.dart).
- **Memory & Lifecycle Safety:** All dialog `TextEditingController` instances bound to `try-finally` or `StatefulWidget` disposal cycles.
- **Code Cleanliness:** 0 dead files, centralized shared components (`reassign_dialog.dart`).
- **Responsive UI & Multi-Device:** Hardened for 320dp small screens, large tablets (max-width card constraints), font scaling (1.5x+), and strict viewport bounds.
- **Accessibility (a11y):** WCAG AA Compliant — 48x48dp touch targets, 4.8:1 input hint contrast, `Semantics` screen reader labels on tabs/checkboxes/pills, full icon tooltips.
- **Live Security Rules:** Deployed to Firebase project `hatly-app-2026` via Firebase MCP.
- **Firebase Infrastructure:** Spark Free Tier (Direct FCM HTTP v1 OAuth 2.0 via `googleapis_auth` + `.env`, no Cloud Functions).

---

## 🏛️ Domain Data Models (`lib/features/*/domain/`)

| Model | File | Fields | Methods |
| :--- | :--- | :--- | :--- |
| **`UserModel`** | [`user_model.dart`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/auth/domain/user_model.dart) | `uid`, `email`, `name`, `householdId`, `fcmToken` | `fromMap()`, `toMap()`, `copyWith()` |
| **`HouseholdModel`** | [`household_model.dart`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/household/domain/household_model.dart) | `id`, `name`, `inviteCode`, `adminId`, `memberIds`, `pendingUserIds`, `subgroups` (`Map<String, List<String>>`), `customCategories` | `fromMap()`, `toMap()`, `activeCategories`, `copyWith()` |
| **`ShoppingListModel`** | [`shopping_list_model.dart`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/shopping_list/domain/shopping_list_model.dart) | `id`, `householdId`, `title`, `createdBy`, `assignedTo`, `assignedToName`, `status` (`active`/`completed`), `createdAt`, `updatedAt`, `items` | `fromMap()`, `toMap()`, `copyWith()` |
| **`ShoppingItemModel`** | [`shopping_item_model.dart`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/shopping_list/domain/shopping_item_model.dart) | `id`, `name`, `category`, `status` (`pending`/`bought`/`outOfStock`), `note` | `fromMap()`, `toMap()`, `copyWith()` |
| **`CategoryModel`** | [`category_model.dart`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/household/domain/category_model.dart) | `id`, `name`, `colorHex`, `iconName` | `fromMap()`, `toMap()`, `iconData`, `defaultCategories` |

---

## ⚡ Riverpod State Providers & Controllers

| Provider / Controller | Location | Type / Stream | Purpose |
| :--- | :--- | :--- | :--- |
| **`authStateProvider`** | [`auth_controller.dart`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/auth/presentation/auth_controller.dart) | `StreamProvider<User?>` | Listens to Firebase Auth login/logout state. |
| **`userProfileProvider`** | [`auth_controller.dart`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/auth/presentation/auth_controller.dart) | `StreamProvider<UserModel?>` | Streams logged-in user profile document from Firestore. |
| **`authControllerProvider`** | [`auth_controller.dart`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/auth/presentation/auth_controller.dart) | `StateNotifier<AsyncValue<void>>` | Handles `signIn()`, `signUp()`, `signOut()`, `updateProfile()`. |
| **`currentHouseholdProvider`** | [`household_controller.dart`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/household/presentation/household_controller.dart) | `StreamProvider<HouseholdModel?>` | Streams user's active household document in real-time. |
| **`isApprovedMemberProvider`** | [`household_controller.dart`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/household/presentation/household_controller.dart) | `Provider<bool>` | Validates if logged-in user UID is in `household.memberIds`. |
| **`householdMembersProvider`** | [`household_controller.dart`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/household/presentation/household_controller.dart) | `StreamProvider<List<UserModel>>` | Streams all approved family member user profiles. |
| **`pendingMembersProvider`** | [`household_controller.dart`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/household/presentation/household_controller.dart) | `StreamProvider<List<UserModel>>` | Streams pending join requests for admin approval. |
| **`householdControllerProvider`** | [`household_controller.dart`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/household/presentation/household_controller.dart) | `StateNotifier<AsyncValue<void>>` | Actions: `createHousehold()`, `requestJoin()`, `approveJoin()`, `rejectJoin()`, `addSubgroup()`, `updateSubgroups()`, `updateCategories()`. |
| **`activeListsProvider`** | [`shopping_list_controller.dart`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/shopping_list/presentation/shopping_list_controller.dart) | `StreamProvider<List<ShoppingListModel>>` | Streams all active lists in current household. |
| **`singleListProvider`** | [`shopping_list_controller.dart`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/shopping_list/presentation/shopping_list_controller.dart) | `StreamProvider.family<ShoppingListModel?, id>` | Streams a specific shopping list document. |
| **`shoppingListControllerProvider`**| [`shopping_list_controller.dart`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/shopping_list/presentation/shopping_list_controller.dart) | `StateNotifier<AsyncValue<void>>` | Actions: `createList()`, `addItemToList()`, `updateItemStatus()`, `removeItemFromList()`, `updateListAssignment()`, `completeList()`, `deleteList()`. |
| **`notificationServiceProvider`** | [`notification_service.dart`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/core/services/notification_service.dart) | `Provider<NotificationService>` | Native notifications, FCM token sync, topic subscriptions, HTTP v1 push dispatches. |

---

## 🎨 UI Design System & Core Widgets (`lib/core/widgets/`)

- **[`GlassCard`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/core/widgets/glass_card.dart):** Frosted glass container (`enableBlur: false` for 60/120 FPS list performance, `enableBlur: true` for overlays). Supports `fillColor`, `borderColor`, `hasActiveGlow`, `onTap`.
- **[`GlassDialog`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/core/widgets/glass_dialog.dart):** `showGlassConfirmationDialog()` helper with WCAG AA compliant red button (`#DC2626`) and min 48dp button targets.
- **[`HatlyHeaderBar`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/core/widgets/hatly_header_bar.dart):** Unified app header bar supporting leading back buttons & trailing actions.
- **[`showReassignListDialog`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/core/widgets/reassign_dialog.dart):** Shared modal dialog for reassigning shopping lists to family members or subgroups.
- **[`AppTheme`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/app/config/theme.dart):** 100% Centralized Theme Token: `backgroundGradient` (`#11253E` → `#081425` → `#040E1F`), `primaryEmerald` (`#10B981`), `GoogleFonts.sora`, 70% input hint contrast (`0xB394A3B8`).

---

## 🗺️ Screen Navigation Matrix (`lib/app/config/`)

- **`/` (Splash Guard):** [`AppSplashScreen`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/app/config/router.dart) — Routes to `/login`, `/household-setup`, or `/dashboard`.
- **`/login`:** [`LoginScreen`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/auth/presentation/login_screen.dart) — Handles login & sign up toggle with `Semantics` tab labels, password visibility tooltip, and tablet max-width constraints.
- **`/household-setup`:** [`HouseholdSetupScreen`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/household/presentation/household_setup_screen.dart) — Create new family group or join with 6-letter invite code, with min 48dp tab hit areas and tablet container constraints.
- **`/dashboard` (Main Shell):** [`MainShellScreen`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/app/config/main_shell_screen.dart) — Bottom nav shell (`IndexedStack`) with `Semantics(selected: ...)` and 48x48dp targets:
  - Index 0: [`DashboardScreen`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/shopping_list/presentation/dashboard_screen.dart)
  - Index 1: [`CreateListScreen`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/shopping_list/presentation/create_list_screen.dart) (Owner only)
  - Index 2: [`HistoryScreen`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/shopping_list/presentation/history_screen.dart)
  - Index 3: [`SettingsScreen`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/settings/presentation/settings_screen.dart)
- **`/shopping-list/:id`:** [`ActiveListScreen`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/shopping_list/presentation/active_list_screen.dart) — Real-time active item checklist, status updates with 48x48dp hit targets, out-of-stock flagging, quick item addition, bounded live progress headers, and list completion.
- **`/manage-household`:** [`ManageHouseholdScreen`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/household/presentation/manage_household_screen.dart) — Member moderation (48x48dp reject/approve buttons with tooltips), overflow-safe invite code container, & subgroup manager.

---

## 🛠️ Key Utilities & Security Constraints

- **[`WhatsAppParser`](file:///c:/Users/ahmed/Desktop/flutter/hatly/lib/features/shopping_list/utils/whatsapp_parser.dart):** `parseRawText(String text)` parses multiline pasted notes / WhatsApp text and autodetects store categories using English/Arabic keyword matching (`_autoDetectCategory`).
- **GPU Scroll Optimization:** Radial background gradients isolated inside `RepaintBoundary` + `Stack` on all list screens.
- **Firestore Offline Mode:** `persistenceEnabled: true` enabled in `main.dart`.
- **Live Security Rules ([`firestore.rules`](file:///c:/Users/ahmed/Desktop/flutter/hatly/firestore.rules)):** Strict multi-tenant isolation (`resource.data.householdId == getUserData().householdId`), profile update owner restrictions (`isOwner(userId)`).
