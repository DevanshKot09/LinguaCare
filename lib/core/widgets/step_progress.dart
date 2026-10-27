import 'package:flutter/material.dart';

class StepProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepProgress({
    super.key,
    required this.currentStep,
    this.totalSteps = 5,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const steps = ['Account', 'Verify', 'About you', 'Role details', 'Consents'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Step $currentStep of $totalSteps',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              currentStep <= steps.length ? steps[currentStep - 1] : '',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: currentStep / totalSteps,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
