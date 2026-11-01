import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/academic/subject.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'academic_visuals.dart';

/// Tarjeta de asignatura: franja y siglas en su color, y lo que pide actuar
/// primero, la próxima evaluación («Evaluación en 5 días», en aviso si es hoy
/// o mañana); debajo, el nombre y el recuento de apuntes y archivos.
class SubjectCard extends StatelessWidget {
  const SubjectCard({super.key, required this.subject, required this.onTap});

  final Subject subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = subjectColor(context, subject.id);
    final l10n = context.localizations;
    final now = DateTime.now();
    final next = subject.nextAssessmentAt;
    final days = next == null ? null : AppDueDates.daysUntil(next, now);
    // Una evaluación ya pasada no se anuncia.
    final assessment = next == null || days == null || days < 0
        ? null
        : switch (days) {
            0 => l10n.academicAssessmentToday,
            1 => l10n.academicAssessmentTomorrow,
            <= 6 => l10n.academicAssessmentIn(days),
            _ => l10n.academicAssessmentOn(DateFormat.MMMd().format(next)),
          };
    final soon =
        next != null && assessment != null && AppDueDates.isSoon(next, now);
    final assessmentColor = soon
        ? context.palette.warning
        : context.colors.tertiary;
    // Pulsable entera (no tiene otras acciones): un botón con su contenido.
    return Card(
      clipBehavior: Clip.antiAlias,
      child: AppCardTapArea(
        borderRadius: BorderRadius.circular(TokensRadius.l),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: TokensSize.blockStripe, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(TokensSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            subjectAcronym(subject),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.headlineSmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (subject.archived)
                          Icon(
                            Icons.archive_outlined,
                            size: TokensSize.iconS,
                            color: context.colors.onSurfaceVariant,
                            semanticLabel: l10n.academicSubjectArchivedBadge,
                          ),
                      ],
                    ),
                    if (assessment != null) ...[
                      const SizedBox(height: TokensSpacing.xxs),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.event_rounded,
                            size: TokensSize.iconXs,
                            color: assessmentColor,
                          ),
                          const SizedBox(width: TokensSpacing.xs),
                          // Dos líneas: en la rejilla de dos columnas de un
                          // móvil, «Evaluación en 5 días» no cabe en una.
                          Expanded(
                            child: Text(
                              assessment,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.labelLarge?.copyWith(
                                color: assessmentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: TokensSpacing.xs),
                    Text(
                      subject.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.titleSmall,
                    ),
                    const Spacer(),
                    Text(
                      l10n.academicSubjectCounts(
                        subject.noteCount,
                        subject.fileCount,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.labelMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
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
