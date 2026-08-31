import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/router.dart';
import 'config/theme.dart';

/// Root Application Widget wrapped in [ConsumerWidget] to watch router configuration.
class HatlyApp extends ConsumerWidget {
  const HatlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final activeTheme = ref.watch(activeThemeProvider);

    return MaterialApp.router(
      title: 'Hatly',
      theme: activeTheme.themeData,
      darkTheme: activeTheme.themeData,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        );
      },
    );
  }
}

// history for the regular user done!
// the settings done!
// google fonts (Sora) done!
// profiles settings done!
// family members management done!
// check the colors and the gradient done!
// the navigation bar style changed isn't dots under the icons anymore done!
// animations done!
// build & SDK 35 compatibility done!
// notifications & real-time local push banners done!
// login blank screen & router redirect guard fixed!
// realme GT blank screen & dual route transition collision 100% resolved via splash guard!
// top bar title & update button overflow fixed!
// unified signature Stitch AppBars across all screens done!
// header bar layout & notification action button 100% matched across Home/Create/History/Settings done!
// real-time list creation & list update notification dispatch to Firestore + device listener done!
// FCM household topic subscription & terminated-state background notification handler registered done!
// deployed updated firestore security rules with notifications collection access done!
// 100% free Spark tier FCM HTTP v1 Service Account push dispatcher embedded in NotificationService done!
// core library desugaring enabled in build.gradle.kts done!
// list deletion capability with confirmation dialog added for Household Owner across Dashboard, Active List, & History screens done!
// self-notification exclusion (senderUid filter) & app startup stream duplicate notification fix done!
// subgroup/category membership matching & token-targeted closed-app FCM push enabled done!
// Android 16 splash stuck fix (router null profile redirect + self-healing Firestore user doc creation) done!
// instant 0.1s real-time notification delivery + stale token 404 UNREGISTERED topic fallback enabled done!
// automatic FCM token deletion from Firestore on Sign Out added done!
// header notification bell button removed across Dashboard, Create, History, & Settings screens done!
// dynamic category icon vector mapping & interactive icon picker in Settings added done!
// owner list re-assignment modal & targeted notification dispatch added to Dashboard & Active List screens done!
// dynamic subgroup loading across Create List, Dashboard, & Active List screens + Create New Subgroup feature added done!
