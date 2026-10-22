import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About LinguaCare')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 100),
                child: Image.asset(
                  'assets/images/banner_horizontal.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('LinguaCare DLD Support App', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Version 1.0.0+1', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 24),
            const Text(
              'What LinguaCare Does',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'LinguaCare supports language development for individuals with Developmental Language Disorder (DLD). It provides daily activities, language checks, visual schedules, communication cards, instruction helpers, collaboration tools, and local-first privacy (with cloud backup disabled via allowBackup="false" to keep personal journal and tool data strictly on your device).',
            ),
            const SizedBox(height: 24),
            const Text(
              'What LinguaCare Does NOT Do',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.redAccent),
            ),
            const SizedBox(height: 8),
            const Text(
              'LinguaCare is NOT a medical device, does NOT provide medical diagnoses, and is NOT a replacement for professional clinical care or speech-language therapy.',
            ),
          ],
        ),
      ),
    );
  }
}
