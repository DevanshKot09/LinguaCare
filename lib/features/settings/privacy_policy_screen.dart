import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy and Your Data'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, color: theme.colorScheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DPDP Act 2023 Compliance',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Digital Personal Data Protection Act • Version 1.0',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'LinguaCare is committed to protecting your and your child\'s privacy. We adhere to the principles of purpose limitation, data minimisation, and zero advertising.',
                      style: TextStyle(fontSize: 12.5, color: theme.colorScheme.onSurface.withValues(alpha: 0.85)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _PrivacySection(
              title: '1. Personal Data Collected & Purpose (Section 5)',
              icon: Icons.data_usage_rounded,
              color: Colors.blue,
              points: const [
                'Account Information: Email address and authentication credentials managed securely.',
                'Developmental Information: Child nickname, general age band (e.g. 5–11, 11–18), screening responses, and developmental observations.',
                'Purpose of Processing: Providing language support activities, tracking milestones, and enabling selective family/educator collaboration.',
                'Data Minimisation: We encourage nicknames instead of legal child names, and do not collect precise GPS coordinates, biometric identifiers, or Aadhaar numbers.',
              ],
            ),
            const SizedBox(height: 16),
            _PrivacySection(
              title: '2. Processing of Children\'s Data (Section 9)',
              icon: Icons.child_care_rounded,
              color: Colors.purple,
              points: const [
                'Verifiable Parental Consent: Children under 18 cannot register independently. All child profiles require explicit parental/guardian consent.',
                'Zero Behavioral Tracking: We strictly never engage in tracking, profiling, or behavioral monitoring of children.',
                'Zero Advertising: LinguaCare contains NO ads and we never sell, rent, or monetize your or your child\'s personal data.',
                'No Detrimental Processing: We never process child data in any manner that could adversely affect the well-being of the child.',
              ],
            ),
            const SizedBox(height: 16),
            _PrivacySection(
              title: '3. Data Stored Exclusively On-Device',
              icon: Icons.phone_android_rounded,
              color: Colors.teal,
              points: const [
                'Visual Schedules, Communication Cards, Adult Journal entries, and personal practice notes are stored 100% locally on your device.',
                'These personal tools never upload to cloud databases and can be cleared instantly via Settings > Clear Data on this Device.',
              ],
            ),
            const SizedBox(height: 16),
            _PrivacySection(
              title: '4. Your Rights under DPDP Act 2023 (Chapter III)',
              icon: Icons.verified_user_rounded,
              color: Colors.green,
              points: const [
                'Right to Access (Sec. 11): You have the right to a summary of personal data processed and identities of professionals it was shared with.',
                'Right to Correction & Erasure (Sec. 12): You can update your profile or permanently erase all data using "Delete Account" in Settings.',
                'Right to Withdraw Consent (Sec. 6(4)): You may revoke sharing permissions with any teacher or specialist at any time; access is terminated immediately.',
                'Right to Nominate (Sec. 14): You may nominate an individual to exercise your privacy rights in the event of death or incapacity by contacting our Grievance Officer.',
              ],
            ),
            const SizedBox(height: 16),
            _PrivacySection(
              title: '5. Security Safeguards & Encryption (Section 8)',
              icon: Icons.lock_outline_rounded,
              color: Colors.indigo,
              points: const [
                'Row-Level Security (RLS) ensures no unauthorized user can read another family\'s records.',
                'Invite codes are cryptographically hashed using SHA-256 with salts.',
                'Observation notes pass through automated filters to detect and prevent inadvertent entry of phone numbers or email addresses.',
                'All data transmitted to cloud services is encrypted using TLS 1.3.',
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.support_agent_rounded, color: Colors.orange, size: 22),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '6. Grievance Redressal Officer (Section 13)',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'If you have any questions, concerns, or wish to exercise your rights under the DPDP Act 2023, you may contact our designated Grievance Officer:',
                      style: TextStyle(fontSize: 13, height: 1.4, color: theme.colorScheme.onSurface.withValues(alpha: 0.85)),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Designation: Grievance & Data Protection Officer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          SizedBox(height: 4),
                          Text('Email: grievance@linguacare.app / privacy@linguacare.app', style: TextStyle(fontSize: 13)),
                          SizedBox(height: 4),
                          Text('Response Resolution: Within 30 days as prescribed by law.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'If a grievance is not redressed satisfactorily, you may file a complaint with the Data Protection Board of India (DPBI) as per applicable rules.',
                      style: TextStyle(fontSize: 11.5, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> points;

  const _PrivacySection({
    required this.title,
    required this.icon,
    required this.color,
    required this.points,
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
            const SizedBox(height: 12),
            ...points.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        p,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
