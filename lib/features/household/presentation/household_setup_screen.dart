import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/config/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/hatly_header_bar.dart';
import '../../auth/presentation/auth_controller.dart';
import 'household_controller.dart';

class HouseholdSetupScreen extends ConsumerStatefulWidget {
  const HouseholdSetupScreen({super.key});

  @override
  ConsumerState<HouseholdSetupScreen> createState() => _HouseholdSetupScreenState();
}

class _HouseholdSetupScreenState extends ConsumerState<HouseholdSetupScreen> {
  final _createFormKey = GlobalKey<FormState>();
  final _joinFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isJoining = false;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _submitCreate() {
    if (!_createFormKey.currentState!.validate()) return;
    ref
        .read(householdControllerProvider.notifier)
        .createHousehold(_nameController.text);
  }

  void _submitJoin() {
    if (!_joinFormKey.currentState!.validate()) return;
    ref
        .read(householdControllerProvider.notifier)
        .requestJoin(_codeController.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(householdControllerProvider);
    final household = ref.watch(currentHouseholdProvider).value;
    final currentUser = ref.watch(userProfileProvider).value;

    final isPendingApproval = household != null &&
        currentUser != null &&
        household.pendingUserIds.contains(currentUser.uid);

    ref.listen<AsyncValue<void>>(householdControllerProvider, (previous, next) {
      if (next.hasError) {
        String errorMsg = next.error.toString().replaceAll('Exception: ', '');
        if (errorMsg.contains('PERMISSION_DENIED') ||
            errorMsg.contains('Cloud Firestore API') ||
            errorMsg.contains('firestore.googleapis.com')) {
          errorMsg =
              '⚠️ Notice: Please enable Cloud Firestore Database in Firebase Console!';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red.shade900,
            duration: const Duration(seconds: 7),
          ),
        );
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          ref.read(authControllerProvider.notifier).signOut();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.backgroundGradient,
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    HatlyHeaderBar(
                      title: 'Household Setup',
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: AppTheme.textPrimary),
                        tooltip: 'Back to Sign In',
                        onPressed: () {
                          ref
                              .read(authControllerProvider.notifier)
                              .signOut();
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connect with your family to share real-time shopping lists',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 32),

                    // Pending Approval View (If user has sent join request)
                    if (isPendingApproval)
                      GlassCard(
                        padding: const EdgeInsets.all(28.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryEmerald.withValues(alpha: 0.15),
                                border: Border.all(
                                  color: AppTheme.primaryEmerald.withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Icon(
                                Icons.hourglass_top_rounded,
                                color: AppTheme.primaryEmerald,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Request Sent to "${household.name}"',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Your join request has been sent! Please ask the family owner to open Hatly and approve your request.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0x66F87171)),
                              ),
                              onPressed: () {
                                ref
                                    .read(authControllerProvider.notifier)
                                    .signOut();
                              },
                              icon: const Icon(Icons.logout_rounded,
                                  color: Color(0xFFF87171), size: 18),
                              label: const Text(
                                'Sign Out',
                                style: TextStyle(color: Color(0xFFF87171)),
                              ),
                            ),
                          ],
                        ),
                      )

                    // Glass Container Card for Create vs Join
                    else
                      GlassCard(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Segmented Switcher (Create vs Join)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0x1AFFFFFF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Semantics(
                                      selected: !_isJoining,
                                      button: true,
                                      label: 'Create Household tab',
                                      child: GestureDetector(
                                        onTap: () {
                                          if (_isJoining) setState(() => _isJoining = false);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            color: !_isJoining
                                                ? AppTheme.primaryEmerald
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            'Create Household',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: !_isJoining
                                                  ? const Color(0xFF00391C)
                                                  : AppTheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Semantics(
                                      selected: _isJoining,
                                      button: true,
                                      label: 'Join Household tab',
                                      child: GestureDetector(
                                        onTap: () {
                                          if (!_isJoining) setState(() => _isJoining = true);
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          decoration: BoxDecoration(
                                            color: _isJoining
                                                ? AppTheme.primaryEmerald
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            'Join Household',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _isJoining
                                                  ? const Color(0xFF00391C)
                                                  : AppTheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // CREATE HOUSEHOLD FORM
                            if (!_isJoining)
                              Form(
                                key: _createFormKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Create New Household',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Create your family group and get a unique 8-character invite code to share.',
                                      style: TextStyle(
                                          color: AppTheme.textSecondary, fontSize: 13),
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      controller: _nameController,
                                      style: const TextStyle(color: AppTheme.textPrimary),
                                      decoration: const InputDecoration(
                                        labelText: 'Family Name',
                                        hintText: 'e.g. The Smith Family',
                                        prefixIcon: Icon(Icons.family_restroom_outlined),
                                      ),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Please enter a family name';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed: state.isLoading ? null : _submitCreate,
                                      child: state.isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                color: Color(0xFF00391C),
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : const Text('Create Household'),
                                    ),
                                  ],
                                ),
                              )

                            // JOIN HOUSEHOLD FORM
                            else
                              Form(
                                key: _joinFormKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Join Existing Household',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Enter the 8-character invite code (e.g. HAT-9X82-K4) sent by your family Admin.',
                                      style: TextStyle(
                                          color: AppTheme.textSecondary, fontSize: 13),
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      controller: _codeController,
                                      textCapitalization: TextCapitalization.characters,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        letterSpacing: 2.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: 'Invite Code',
                                        hintText: 'HAT-XXXX-XX',
                                        prefixIcon: Icon(Icons.vpn_key_outlined),
                                      ),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Please enter the invite code';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed: state.isLoading ? null : _submitJoin,
                                      child: state.isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                color: Color(0xFF00391C),
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : const Text('Request Join'),
                                    ),
                                  ],
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
        ],
      ),
    ),
  );
  }
}
