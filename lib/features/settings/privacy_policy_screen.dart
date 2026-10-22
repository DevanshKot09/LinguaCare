import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy and Your Data')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.amber.shade100,
              child: const Text(
                'Placeholder text - needs legal review.',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Data Privacy Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              '• What is collected: Basic profile info, encrypted auth credentials, and optional shared family observations or screening results if you choose to share.\n\n'
              '• What stays only on the phone: Visual schedules, communication cards, adult journal entries, and local checklists are stored exclusively on your device and are never uploaded.\n\n'
              '• Who can see it: Data sharing with family members, teachers, or specialists is strictly controlled by you and can be stopped at any time.\n\n'
              '• How to delete account: You can permanently delete your account and associated cloud data from Settings at any time, which also clears local device data.',
            ),
          ],
        ),
      ),
    );
  }
}
