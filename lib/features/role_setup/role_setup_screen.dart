import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';

class RoleSetupScreen extends ConsumerWidget {
  const RoleSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Role'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                const Text(
                  'Select how you will use LinguaCare. Note: Your role cannot be changed after setup.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _RoleCard(
                  title: 'Parent / Caregiver',
                  description: 'Manage child profiles, run screenings, and practice daily activities.',
                  icon: Icons.family_restroom_rounded,
                  color: AppColors.parentAccent,
                  onTap: () => context.push('/role-setup/form?role=parent'),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  title: 'Educator / Teacher',
                  description: 'Access strategies, record observations, and support students.',
                  icon: Icons.school_rounded,
                  color: AppColors.teacherAccent,
                  onTap: () => context.push('/role-setup/form?role=teacher'),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  title: 'Adult (18+)',
                  description: 'Self-reflection, communication card, journal, and personal tools.',
                  icon: Icons.person_rounded,
                  color: AppColors.adultAccent,
                  onTap: () => context.push('/role-setup/form?role=adult'),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  title: 'Specialist (SLP)',
                  description: 'Manage caseload, set goals, and enter confirmed clinical outcomes.',
                  icon: Icons.medical_services_rounded,
                  color: AppColors.specialistAccent,
                  onTap: () => context.push('/role-setup/form?role=specialist'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(description, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
