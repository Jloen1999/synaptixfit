import 'package:flutter/material.dart';

class ChallengeProgressBar extends StatelessWidget {
  const ChallengeProgressBar({
    required this.progress,
    this.label,
    this.circular = false,
    super.key,
  });

  final double progress;
  final String? label;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final normalized = progress.clamp(0.0, 1.0).toDouble();
    if (circular) {
      return SizedBox(
        width: 72,
        height: 72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(value: normalized),
            Text('${(normalized * 100).round()}%'),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
        ],
        LinearProgressIndicator(value: normalized, minHeight: 8),
      ],
    );
  }
}
