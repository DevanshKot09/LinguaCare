import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            Row(
              children: [
                Icon(Icons.gavel_rounded, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Terms & Conditions',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Last updated: October 2024 • Version 1.0',
                        style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _TermsCard(
              title: '1. Important Medical & Clinical Disclaimer',
              icon: Icons.health_and_safety_rounded,
              color: Colors.redAccent,
              content:
                  'LinguaCare is an educational and supportive application designed to assist families, educators, and speech professionals in supporting language development. '
                  'LinguaCare is NOT a certified medical device and does NOT provide formal clinical diagnosis, medical treatment, or prescription. '
                  'Our screening tools and activities do not substitute professional evaluation by a registered Speech-Language Pathologist (SLP) or healthcare professional.',
            ),
            const SizedBox(height: 16),
            _TermsCard(
              title: '2. Eligibility & Parental Responsibility (DPDP Act)',
              icon: Icons.family_restroom_rounded,
              color: Colors.blueAccent,
              content:
                  'In compliance with Section 9 of the Digital Personal Data Protection (DPDP) Act, 2023, individuals under 18 years of age are not permitted to create independent accounts. '
                  'All profiles for children must be created and managed by a verified parent or lawful caregiver who holds the legal authority to grant consent on the child\'s behalf.',
            ),
            const SizedBox(height: 16),
            _TermsCard(
              title: '3. Data Sharing & Collaboration',
              icon: Icons.share_rounded,
              color: Colors.teal,
              content:
                  'Parents may selectively share child observations, activity progress, and screening summaries with verified teachers or specialists using secure invite links. '
                  'Sharing can be paused or revoked by the parent at any moment from the Family Sharing settings, terminating remote access immediately.',
            ),
            const SizedBox(height: 16),
            _TermsCard(
              title: '4. Account Termination & Right to Erasure',
              icon: Icons.delete_forever_rounded,
              color: Colors.deepOrange,
              content:
                  'You may discontinue using LinguaCare at any time. Under your statutory rights, you may permanently delete your account and all associated personal and child data from Settings > Delete Account. '
                  'Deletion permanently wipes your cloud records and local application storage.',
            ),
            const SizedBox(height: 16),
            _TermsCard(
              title: '5. Governing Law & Dispute Resolution',
              icon: Icons.account_balance_rounded,
              color: Colors.indigo,
              content:
                  'These Terms are governed by and construed in accordance with the laws of India, including the Digital Personal Data Protection Act, 2023 and the Information Technology Act, 2000. '
                  'Any grievances may be directed to our Grievance Redressal Officer at grievance@linguacare.app.',
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Questions regarding these terms? Contact us at support@linguacare.app',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _TermsCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  const _TermsCard({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
