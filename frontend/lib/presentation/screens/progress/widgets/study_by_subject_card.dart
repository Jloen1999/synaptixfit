import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../domain/models/progress/study_by_subject.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// «Por asignatura»: horas de estudio de las últimas semanas (una barra por
/// semana) y cuánto recuerdas en los repasos de cada una. Destaca las que van
/// flojas para repasarlas más a menudo.
class StudyBySubjectCard extends StatelessWidget {
  const StudyBySubjectCard({super.key, required this.report});

  /// Null si no se pudo cargar: la tarjeta no se muestra.
  final StudyBySubject? report;

  @override
  Widget build(BuildContext context) {
    final data = report;
    if (data == null) return const SizedBox.shrink();
    final l10n = context.localizations;
    final subjects = data.subjects
        .where((s) => s.totalMinutes > 0 || s.reviews > 0)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: l10n.progressBySubjectTitle(data.weeks)),
        AppCard(
          child: subjects.isEmpty
              ? Text(
                  l10n.progressBySubjectEmpty,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, s) in subjects.indexed) ...[
                      if (i > 0) const Divider(height: TokensSpacing.l),
                      _SubjectRow(subject: s),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({required this.subject});

  final SubjectStudy subject;

  static String _duration(BuildContext context, int minutes) {
    final l10n = context.localizations;
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return l10n.progressBySubjectMinutes(m);
    return m == 0
        ? l10n.progressBySubjectHoursOnly(h)
        : l10n.progressBySubjectHours(h, m);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final s = subject;
    final name =
        s.name ??
        (s.subjectId == null
            ? l10n.progressBySubjectNoSubject
            : l10n.progressBySubjectArchived);
    final recall = s.recallRate;
    final recallColor = recall == null
        ? context.colors.onSurfaceVariant
        : s.weak
        ? context.colors.error
        : recall >= 0.8
        ? context.palette.success
        : context.palette.warning;
    final reviewText = recall == null
        ? l10n.progressBySubjectNoReviews
        : l10n.progressBySubjectRecall(s.reviews, (recall * 100).round());
    final maxWeek = s.minutesByWeek.fold<int>(1, math.max);
    return Semantics(
      label:
          '$name. ${_duration(context, s.totalMinutes)}. $reviewText'
          '${s.weak ? '. ${l10n.progressBySubjectWeak}' : ''}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleSmall,
                ),
              ),
              Text(
                _duration(context, s.totalMinutes),
                style: context.textStyles.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.xs),
          // Una barra por semana (la última, la actual).
          SizedBox(
            height: TokensSize.iconL,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, minutes) in s.minutesByWeek.indexed) ...[
                  if (i > 0) const SizedBox(width: TokensSpacing.xs),
                  Expanded(
                    child: Container(
                      height: math.max(
                        TokensSize.iconL * minutes / maxWeek,
                        TokensSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: minutes == 0
                            ? context.colors.outlineVariant
                            : context.palette.study,
                        borderRadius: BorderRadius.circular(TokensRadius.s),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: TokensSpacing.xs),
          Row(
            children: [
              Icon(
                Icons.replay_rounded,
                size: TokensSize.iconXs,
                color: recallColor,
              ),
              const SizedBox(width: TokensSpacing.xs),
              Expanded(
                child: Text(
                  s.weak
                      ? '$reviewText · ${l10n.progressBySubjectWeak}'
                      : reviewText,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: s.weak
                        ? context.colors.error
                        : context.colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
