import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/router/app_session.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state_panel.dart';
import '../../core/widgets/error_panel.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../data/repositories/firebase_auth_repository.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool _loadingSpecialists = true;
  String? _specialistError;
  List<Map<String, dynamic>> _pendingSpecialists = [];

  bool _loadingAudit = true;
  String? _auditError;
  List<Map<String, dynamic>> _auditLogs = [];

  int _parentCount = 0;
  int _teacherCount = 0;
  int _specialistCount = 0;
  int _adultCount = 0;
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllAdminData() async {
    _loadPendingSpecialists();
    _loadAuditLogs();
    _loadSystemStats();
  }

  Future<void> _loadPendingSpecialists() async {
    setState(() {
      _loadingSpecialists = true;
      _specialistError = null;
    });

    final client = _supabase;
    if (client == null) {
      if (mounted) {
        setState(() {
          _loadingSpecialists = false;
        });
      }
      return;
    }

    try {
      final res = await client
          .from('profiles')
          .select('uid, full_name, email, country, created_at, verified, specialist_details(profession, licence_no, licence_body, workplace)')
          .eq('role', 'specialist')
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _pendingSpecialists = List<Map<String, dynamic>>.from(res as List);
          _loadingSpecialists = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Admin] load pending specialists error: $e');
      }
      if (mounted) {
        setState(() {
          _loadingSpecialists = false;
          _specialistError = 'Unable to load specialist queue. Please verify your administrative credentials or network connection.';
        });
      }
    }
  }

  Future<void> _loadAuditLogs() async {
    setState(() {
      _loadingAudit = true;
      _auditError = null;
    });

    final client = _supabase;
    if (client == null) {
      if (mounted) {
        setState(() {
          _loadingAudit = false;
        });
      }
      return;
    }

    try {
      final res = await client
          .from('access_audit')
          .select('*')
          .order('created_at', ascending: false)
          .limit(30);

      if (mounted) {
        setState(() {
          _auditLogs = List<Map<String, dynamic>>.from(res as List);
          _loadingAudit = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Admin] load audit logs error: $e');
      }
      if (mounted) {
        setState(() {
          _loadingAudit = false;
          _auditError = 'Unable to load access audit logs. Please verify your administrative credentials or network connection.';
        });
      }
    }
  }

  Future<void> _loadSystemStats() async {
    setState(() {
      _loadingStats = true;
    });

    final client = _supabase;
    if (client == null) {
      if (mounted) {
        setState(() {
          _loadingStats = false;
        });
      }
      return;
    }

    try {
      final res = await client.from('profiles').select('role');
      int p = 0, t = 0, s = 0, a = 0;
      for (final r in (res as List)) {
        final role = r['role'] as String?;
        if (role == 'parent') p++;
        if (role == 'teacher') t++;
        if (role == 'specialist') s++;
        if (role == 'adult') a++;
      }

      if (mounted) {
        setState(() {
          _parentCount = p;
          _teacherCount = t;
          _specialistCount = s;
          _adultCount = a;
          _loadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingStats = false;
        });
      }
    }
  }

  Future<void> _toggleSpecialistVerification(String uid, bool currentVerified, String name) async {
    final newStatus = !currentVerified;
    final confirm = await ConfirmDialog.show(
      context,
      title: newStatus ? 'Approve Specialist Verification' : 'Revoke Specialist Verification',
      message: newStatus
          ? 'Are you sure you want to approve $name? This grants access to clinical assessment tools and shared child observation summaries.'
          : 'Are you sure you want to revoke verification for $name? They will be locked from recording clinical assessments.',
      confirmLabel: newStatus ? 'Approve' : 'Revoke',
      isDestructive: !newStatus,
      icon: newStatus ? Icons.verified_user_rounded : Icons.block_rounded,
    );

    if (confirm != true || !mounted) return;

    final client = _supabase;
    if (client == null) return;

    try {
      await client.from('profiles').update({'verified': newStatus}).eq('uid', uid);

      final session = ref.read(appSessionStateProvider);
      try {
        await client.from('access_audit').insert({
          'actor_uid': session.user?.uid ?? 'admin',
          'action': newStatus ? 'VERIFY_SPECIALIST' : 'REVOKE_SPECIALIST',
          'table_name': 'profiles',
          'record_id': uid,
        });
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus
                ? '$name has been verified successfully.'
                : 'Verification revoked for $name.'),
            backgroundColor: newStatus ? AppColors.secondaryLight : AppColors.errorLight,
          ),
        );
        _loadPendingSpecialists();
        _loadAuditLogs();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update verification: $e'),
            backgroundColor: AppColors.errorLight,
          ),
        );
      }
    }
  }

  Future<void> _handleSignOut() async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Sign Out Administrator',
      message: 'Are you sure you want to sign out of the LinguaCare Admin console?',
      confirmLabel: 'Sign Out',
      isDestructive: true,
      icon: Icons.logout_rounded,
    );

    if (confirm == true && mounted) {
      await ref.read(authRepositoryProvider).signOut();
      if (mounted) {
        context.go('/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final session = ref.watch(appSessionStateProvider);

    // Strict Authorization Guard
    if (session.status != AuthSessionStatus.authenticated || session.role != UserRole.admin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && GoRouter.maybeOf(context) != null) {
          context.go('/welcome');
        }
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final adminEmail = session.user?.email ?? 'admin@lingua.ai';

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_rounded, size: 20, color: Color(0xFF6366F1)),
            SizedBox(width: 8),
            Text(
              'LinguaCare Console',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh All',
            onPressed: _loadAllAdminData,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out ($adminEmail)',
            onPressed: _handleSignOut,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: isDark ? Colors.white : const Color(0xFF4338CA),
          tabs: const [
            Tab(icon: Icon(Icons.verified_user_rounded), text: 'Approvals'),
            Tab(icon: Icon(Icons.history_edu_rounded), text: 'Audit Logs'),
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'Overview'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSpecialistsTab(),
            _buildAuditLogsTab(),
            _buildOverviewTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialistsTab() {
    if (_loadingSpecialists) {
      return ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 4,
        itemBuilder: (context, index) => const SkeletonCard(),
      );
    }

    if (_specialistError != null) {
      return ErrorPanel(
        title: 'Specialist Queue Error',
        message: _specialistError!,
        onRetry: _loadPendingSpecialists,
      );
    }

    if (_pendingSpecialists.isEmpty) {
      return const EmptyStatePanel(
        icon: Icons.check_circle_outline_rounded,
        title: 'All Specialists Verified',
        description: 'There are no pending specialist applications awaiting credential verification.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _pendingSpecialists.length,
      itemBuilder: (context, index) {
        final item = _pendingSpecialists[index];
        final uid = item['uid'] as String? ?? '';
        final fullName = item['full_name'] as String? ?? 'Specialist';
        final email = item['email'] as String? ?? '';
        final verified = item['verified'] as bool? ?? false;
        final details = item['specialist_details'] as Map<String, dynamic>?;

        final profession = details?['profession'] as String? ?? 'Speech-Language Pathologist';
        final licenceNo = details?['licence_no'] as String? ?? 'N/A';
        final licenceBody = details?['licence_body'] as String? ?? 'N/A';
        final workplace = details?['workplace'] as String? ?? 'Private Practice';

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: BorderSide(
              color: verified ? AppColors.secondaryLight.withValues(alpha: 0.5) : const Color(0xFFF59E0B),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: verified
                            ? AppColors.secondaryLight.withValues(alpha: 0.15)
                            : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            verified ? Icons.check_circle_rounded : Icons.pending_rounded,
                            size: 14,
                            color: verified ? AppColors.secondaryLight : const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            verified ? 'VERIFIED' : 'PENDING REVIEW',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: verified ? AppColors.secondaryLight : const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildMetaItem('Profession', profession),
                    _buildMetaItem('Licence No', licenceNo),
                    _buildMetaItem('Licensing Body', licenceBody),
                    _buildMetaItem('Workplace', workplace),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _toggleSpecialistVerification(uid, verified, fullName),
                      icon: Icon(
                        verified ? Icons.block_rounded : Icons.verified_user_rounded,
                        size: 18,
                        color: verified ? AppColors.errorLight : AppColors.secondaryLight,
                      ),
                      label: Text(
                        verified ? 'Revoke Approval' : 'Approve Specialist',
                        style: TextStyle(
                          color: verified ? AppColors.errorLight : AppColors.secondaryLight,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: verified ? AppColors.errorLight : AppColors.secondaryLight,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuditLogsTab() {
    if (_loadingAudit) {
      return ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 5,
        itemBuilder: (context, index) => const SkeletonCard(height: 80),
      );
    }

    if (_auditError != null) {
      return ErrorPanel(
        title: 'Audit Log Error',
        message: _auditError!,
        onRetry: _loadAuditLogs,
      );
    }

    if (_auditLogs.isEmpty) {
      return const EmptyStatePanel(
        icon: Icons.history_rounded,
        title: 'No Audit Records',
        description: 'System access logs will appear here when administrative or sharing actions occur.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _auditLogs.length,
      itemBuilder: (context, index) {
        final log = _auditLogs[index];
        final action = log['action'] as String? ?? 'ACCESS';
        final table = log['table_name'] as String? ?? 'general';
        final actor = log['actor_uid'] as String? ?? 'system';
        final createdAt = log['created_at'] as String? ?? '';
        final recordId = log['record_id'] as String? ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.15),
              child: const Icon(Icons.security_rounded, size: 20, color: Color(0xFF6366F1)),
            ),
            title: Text(
              action,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: Text(
              'Actor: $actor\nTarget: $table ${recordId.isNotEmpty ? "($recordId)" : ""}\nTime: $createdAt',
              style: const TextStyle(fontSize: 12),
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            color: const Color(0xFF6366F1).withValues(alpha: 0.08),
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, size: 36, color: Color(0xFF6366F1)),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Administrative Security & Compliance',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Administrative endpoints enforce server-side PostgreSQL Row-Level Security. Every verification, consent withdrawal, and clinical data export is logged in immutable audit tables.',
                          style: TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Registered Accounts by Role',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_loadingStats)
            const SkeletonCard()
          else
            Row(
              children: [
                Expanded(child: _buildStatCard('Parents', '$_parentCount', AppColors.parentAccent, Icons.family_restroom)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _buildStatCard('Teachers', '$_teacherCount', AppColors.teacherAccent, Icons.school)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _buildStatCard('Specialists', '$_specialistCount', AppColors.specialistAccent, Icons.medical_services)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: _buildStatCard('Adults', '$_adultCount', AppColors.adultAccent, Icons.person)),
              ],
            ),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'Administrative Verification Procedures',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: AppSpacing.md),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: CircleAvatar(child: Text('1')),
                    title: Text('Cross-Reference Licensing Registry'),
                    subtitle: Text('Verify licence number, jurisdiction, and professional standing with the regional Speech-Language Pathology regulatory board.'),
                  ),
                  Divider(),
                  ListTile(
                    leading: CircleAvatar(child: Text('2')),
                    title: Text('One-Click Approval'),
                    subtitle: Text('Click "Approve Specialist" to update verification status. The specialist immediately receives access to the clinical assessment battery.'),
                  ),
                  Divider(),
                  ListTile(
                    leading: CircleAvatar(child: Text('3')),
                    title: Text('Audit Trail'),
                    subtitle: Text('All verification approvals and revocations are automatically stamped with your administrator UID in the audit log.'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
