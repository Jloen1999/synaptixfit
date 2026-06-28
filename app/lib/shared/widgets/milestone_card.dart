import 'package:flutter/material.dart';

import 'challenge_progress_bar.dart';

class MilestoneCard extends StatelessWidget {
  const MilestoneCard({
    required this.title,
    required this.weight,
    required this.progress,
    super.key,
  });

  final String title;
  final double weight;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text('${weight.toStringAsFixed(0)}% peso'),
              ],
            ),
            const SizedBox(height: 12),
            ChallengeProgressBar(progress: progress),
          ],
        ),
      ),
    );
  }
}
