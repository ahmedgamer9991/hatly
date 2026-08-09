import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/config/theme.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/hatly_header_bar.dart';
import '../../auth/presentation/auth_controller.dart';
import 'household_controller.dart';

class ManageHouseholdScreen extends ConsumerStatefulWidget {
  const ManageHouseholdScreen({super.key});

  @override
  ConsumerState<ManageHouseholdScreen> createState() =>
      _ManageHouseholdScreenState();
}

class _ManageHouseholdScreenState
    extends ConsumerState<ManageHouseholdScreen> {
  bool _isCopied = false;

  void _copyInviteCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    setState(() => _isCopied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite code copied to clipboard!'),
        backgroundColor: AppTheme.primaryEmerald,
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final householdState = ref.watch(currentHouseholdProvider);
    final membersState = ref.watch(householdMembersProvider);
    final pendingState = ref.watch(pendingMembersProvider);

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
              HatlyHeaderBar(
                title: 'Manage Family',
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: AppTheme.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Scrollable Feed
              Expanded(
                child: householdState.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryEmerald),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      'Error: $err',
                      style: const TextStyle(color: AppTheme.errorRed),
                    ),
                  ),
                  data: (household) {
                    if (household == null) {
                      return const Center(
                        child: Text(
                          'Household not found',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, top: 16, bottom: 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Section 1: "Invite Members"
                          const Text(
                            'Invite Members',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GlassCard(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'UNIQUE FAMILY CODE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textSecondary,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Inset Code Box
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0x0DFFFFFF),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: const Color(0x1AF8FAFC)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        household.inviteCode,
                                        style: GoogleFonts.sora(
                                          color: AppTheme.primaryEmerald,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 22,
                                          letterSpacing: 2.5,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () =>
                                            _copyInviteCode(household.inviteCode),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Row(
                                          children: [
                                            Icon(
                                              _isCopied
                                                  ? Icons.check_rounded
                                                  : Icons.copy_rounded,
                                              size: 16,
                                              color: _isCopied
                                                  ? AppTheme.primaryEmerald
                                                  : AppTheme.textSecondary,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _isCopied ? 'Copied' : 'Copy Code',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: _isCopied
                                                    ? AppTheme.primaryEmerald
                                                    : AppTheme.textSecondary,
                                              ),
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
                          const SizedBox(height: 24),

                          // Section 2: "Pending Requests"
                          pendingState.when(
                            loading: () => const SizedBox.shrink(),
                            error: (error, stackTrace) => const SizedBox.shrink(),
                            data: (pendingUsers) {
                              if (pendingUsers.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Pending Requests',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryEmerald,
                                          borderRadius:
                                              BorderRadius.circular(50),
                                        ),
                                        child: Text(
                                          '${pendingUsers.length} New',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF00391C),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  ...pendingUsers.map((user) => GlassCard(
                                        margin: const EdgeInsets.only(bottom: 10),
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 42,
                                              height: 42,
                                              decoration: const BoxDecoration(
                                                color: Color(0x1AFFFFFF),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  user.name.isNotEmpty
                                                      ? user.name[0]
                                                          .toUpperCase()
                                                      : 'U',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    user.name.isEmpty
                                                        ? user.email
                                                        : user.name,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 15,
                                                      color: AppTheme.textPrimary,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    user.email,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          AppTheme.textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Reject Red Button
                                            IconButton.filled(
                                              style: IconButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFFD32F2F),
                                                minimumSize: const Size(36, 36),
                                              ),
                                              icon: const Icon(
                                                  Icons.close_rounded,
                                                  color: Colors.white,
                                                  size: 18),
                                              onPressed: () {
                                                ref
                                                    .read(
                                                        householdControllerProvider
                                                            .notifier)
                                                    .rejectJoin(user.uid);
                                              },
                                            ),
                                            const SizedBox(width: 6),
                                            // Approve Green Button
                                            IconButton.filled(
                                              style: IconButton.styleFrom(
                                                backgroundColor:
                                                    AppTheme.primaryEmerald,
                                                minimumSize: const Size(36, 36),
                                              ),
                                              icon: const Icon(
                                                  Icons.check_rounded,
                                                  color: Color(0xFF00391C),
                                                  size: 18),
                                              onPressed: () {
                                                ref
                                                    .read(
                                                        householdControllerProvider
                                                            .notifier)
                                                    .approveJoin(user.uid);
                                              },
                                            ),
                                          ],
                                        ),
                                      )),
                                  const SizedBox(height: 14),
                                ],
                              );
                            },
                          ),

                          // Section 3: "Family Members"
                          const Text(
                            'Family Members',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          membersState.when(
                            loading: () => const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                    color: AppTheme.primaryEmerald),
                              ),
                            ),
                            error: (err, _) => Text(
                                'Error loading members: $err',
                                style:
                                    const TextStyle(color: AppTheme.errorRed)),
                            data: (members) {
                              return Column(
                                children: members.map((member) {
                                  final isAdmin = member.uid == household.adminId;

                                  return GlassCard(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: isAdmin
                                                ? AppTheme.primaryEmerald
                                                    .withValues(alpha: 0.15)
                                                : const Color(0x1AFFFFFF),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: const Color(0x22FFFFFF)),
                                          ),
                                          child: Icon(
                                            isAdmin
                                                ? Icons.star_rounded
                                                : Icons.person_outline_rounded,
                                            color: isAdmin
                                                ? AppTheme.primaryEmerald
                                                : AppTheme.textSecondary,
                                            size: 22,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                member.name.isEmpty
                                                    ? member.email
                                                    : member.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                isAdmin
                                                    ? 'Family Admin'
                                                    : 'Member',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: isAdmin
                                                      ? AppTheme.primaryEmerald
                                                      : AppTheme.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.more_vert_rounded,
                                          color: AppTheme.textSecondary,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 28),

                          // Section 4: Bottom Sign Out Button & Version Footer
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0x66F87171)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                              style: TextStyle(
                                color: Color(0xFFF87171),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Center(
                            child: Text(
                              'Hatly v2.4.1 — Family Plan',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
