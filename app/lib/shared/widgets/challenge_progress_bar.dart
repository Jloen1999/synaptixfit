import 'package:flutter/material.dart';

class ChallengeProgressBar extends StatelessWidget {
  const ChallengeProgressBar({
    required this.progress,
    this.label,
    this.circular = false,
    this.color,
    super.key,
  });

  final double progress;
  final String? label;
  final bool circular;
  final Color? color;

  Color _progressColor() {
    if (color != null) return color!;
    final p = progress.clamp(0.0, 1.0);
    if (p >= 0.7) return Colors.green;
    if (p >= 0.3) return Colors.orange;
    if (p > 0) return Colors.blue;
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final normalized = progress.clamp(0.0, 1.0).toDouble();
    final barColor = _progressColor();

    if (circular) {
      return SizedBox(
        width: 72,
        height: 72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: normalized,
              color: barColor,
            ),
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
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: normalized,
            minHeight: 8,
            backgroundColor: barColor.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
      ],
    );
  }
}
