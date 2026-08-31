import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../../core/providers/firebase_providers.dart';
import '../../core/widgets/glass_card.dart';
import '../../features/auth/domain/user_model.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/household/presentation/household_controller.dart';
import '../../features/household/presentation/household_setup_screen.dart';
import '../../features/household/presentation/manage_household_screen.dart';
import '../../features/shopping_list/presentation/active_list_screen.dart';
import '../../features/shopping_list/presentation/create_list_screen.dart';
import 'main_shell_screen.dart';

/// Animated Glassmorphism Splash Screen shown during app boot, login transitions, and hot restart.
class AppSplashScreen extends ConsumerStatefulWidget {
  const AppSplashScreen({super.key});

  @override
  ConsumerState<AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends ConsumerState<AppSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutBack,
      ),
    );
    _animController.forward();

    // Start 2-second splash timer for smooth branding & data settling
    _startSplashTimer();
  }

  Future<void> _startSplashTimer() async {
    final startTime = DateTime.now();
    final authUser = ref.read(firebaseAuthProvider).currentUser;

    if (authUser == null) {
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;
      final remaining = 2000 - elapsed;
      if (remaining > 0) await Future.delayed(Duration(milliseconds: remaining));
      if (!mounted || _hasNavigated) return;
      _hasNavigated = true;
      context.go('/login');
      return;
    }

    bool isApprovedMember = false;
    try {
      final firestore = ref.read(firebaseFirestoreProvider);
      final userDoc = await firestore.collection('users').doc(authUser.uid).get();

      String? householdId = userDoc.data()?['householdId'] as String?;

      if (householdId == null || householdId.isEmpty) {
        final hQuery = await firestore
            .collection('households')
            .where('memberIds', arrayContains: authUser.uid)
            .limit(1)
            .get();
        if (hQuery.docs.isNotEmpty) {
          householdId = hQuery.docs.first.id;
          await firestore.collection('users').doc(authUser.uid).set({
            'householdId': householdId,
          }, SetOptions(merge: true));
        }
      }

      if (householdId != null && householdId.isNotEmpty) {
        final hDoc = await firestore.collection('households').doc(householdId).get();
        if (hDoc.exists && hDoc.data() != null) {
          final memberIds = List<dynamic>.from(hDoc.data()?['memberIds'] ?? []);
          if (memberIds.contains(authUser.uid)) {
            isApprovedMember = true;
          }
        }
      }
    } catch (e) {
      debugPrint('Direct splash auth check error: $e');
    }

    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    final remaining = 2000 - elapsed;
    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }

    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    if (isApprovedMember) {
      context.go('/');
    } else {
      context.go('/household-setup');
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgGradient = ref.watch(activeGradientProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: bgGradient,
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withValues(alpha: 0.15),
                      border: Border.all(
                        color: primaryColor,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.shopping_bag_rounded,
                        color: primaryColor,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Hatly',
                    style: GoogleFonts.sora(
                      fontWeight: FontWeight.w800,
                      fontSize: 38,
                      color: primaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Real-Time Family Shopping',
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 36),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: primaryColor,
                            strokeWidth: 2.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Loading family workspace...',
                          style: GoogleFonts.sora(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper building smooth fade & slide page transitions for GoRouter.
Page<dynamic> _buildFadeSlidePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      );
      final slideAnimation = Tween<Offset>(
        begin: const Offset(0.04, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      ));

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

/// ChangeNotifier that triggers GoRouter redirects whenever Auth or Household states change.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<User?>>(
      authStateProvider,
      (prev, next) => notifyListeners(),
    );
    _ref.listen<AsyncValue<UserModel?>>(
      userProfileProvider,
      (prev, next) => notifyListeners(),
    );
    _ref.listen<bool>(
      isApprovedMemberProvider,
      (prev, next) => notifyListeners(),
    );
    _ref.listen<AsyncValue<bool>>(
      appInitialDataLoaderProvider,
      (prev, next) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);
    final authUser = authState.value;
    final isLoggedIn = authUser != null;

    final isSplash = state.matchedLocation == '/splash';
    final isLoggingIn = state.matchedLocation == '/login';
    final isSetup = state.matchedLocation == '/household-setup';

    // 1. While on /splash, ALWAYS stay on /splash and let AppSplashScreen handle data preloading & single transition!
    if (isSplash) {
      return null;
    }

    // 2. Not logged in -> redirect to /login
    if (!isLoggedIn) {
      return isLoggingIn ? null : '/login';
    }

    // 3. Logged in and on /login -> go to /splash for preloading
    if (isLoggingIn) {
      return '/splash';
    }

    // 4. If approved member is on setup screen -> redirect to '/'
    final isApprovedMember = _ref.read(isApprovedMemberProvider);
    if (isApprovedMember && isSetup) {
      return '/';
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

/// Provider for [GoRouter] with authentication, preloading, and household redirect guards.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => _buildFadeSlidePage(
          key: state.pageKey,
          child: const AppSplashScreen(),
        ),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _buildFadeSlidePage(
          key: state.pageKey,
          child: const MainShellScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildFadeSlidePage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/household-setup',
        pageBuilder: (context, state) => _buildFadeSlidePage(
          key: state.pageKey,
          child: const HouseholdSetupScreen(),
        ),
      ),
      GoRoute(
        path: '/manage-household',
        pageBuilder: (context, state) => _buildFadeSlidePage(
          key: state.pageKey,
          child: const ManageHouseholdScreen(),
        ),
      ),
      GoRoute(
        path: '/create-list',
        pageBuilder: (context, state) => _buildFadeSlidePage(
          key: state.pageKey,
          child: const CreateListScreen(),
        ),
      ),
      GoRoute(
        path: '/shopping-list/:id',
        pageBuilder: (context, state) {
          final listId = state.pathParameters['id'] ?? '';
          return _buildFadeSlidePage(
            key: state.pageKey,
            child: ActiveListScreen(listId: listId),
          );
        },
      ),
    ],
  );
});
