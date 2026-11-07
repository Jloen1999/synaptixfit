import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/academic/subject.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'academic_visuals.dart';

/// Tarjeta de asignatura con tres niveles según lo que importa (ADR 0036):
/// el nombre y las siglas en grande; lo próximo y accionable en tamaño medio
/// («Entrega en 3 días», «Próxima clase: lun 10:00 · Aula 2.3»); el profesor y
/// los recuentos en pequeño. Los días de clase y los créditos van en el
/// detalle para no cargar la tarjeta.
class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.subject,
    required this.onTap,
    this.now,
  });

  final Subject subject;
  final VoidCallback onTap;

  /// Para los tests; por defecto, ahora.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final color = subjectColor(context, subject.id);
    final l10n = context.localizations;
    final next = SubjectNextUp.of(subject, now ?? DateTime.now());
    final nextColor = next?.urgent ?? false
        ? context.palette.warning
        : context.colors.tertiary;
    final teacher = subject.teacher?.trim();
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
                        Text(
                          subjectAcronym(subject),
                          maxLines: 1,
                          style: context.textStyles.labelLarge?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        if (subject.archived)
                          Icon(
                            AppIcons.archive,
                            size: TokensSize.iconS,
                            color: context.colors.onSurfaceVariant,
                            semanticLabel: l10n.academicSubjectArchivedBadge,
                          ),
                      ],
                    ),
                    Text(
                      subject.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (next != null) ...[
                      const SizedBox(height: TokensSpacing.xs),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            next.icon,
                            size: TokensSize.iconXs,
                            color: nextColor,
                          ),
                          const SizedBox(width: TokensSpacing.xs),
                          // Dos líneas: en la rejilla de dos columnas de un
                          // móvil, «Próxima clase: lun 10:00 · Aula 2.3» no
                          // cabe en una.
                          Expanded(
                            child: Text(
                              next.text(context),
                              semanticsLabel: next.label(context),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.bodyMedium?.copyWith(
                                color: nextColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    if (teacher != null && teacher.isNotEmpty)
                      Text(
                        teacher,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.labelMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    Text(
                      l10n.academicSubjectCounts(
                        subject.noteCount,
                        subject.fileCount,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.labelSmall?.copyWith(
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

/// Lo próximo y accionable de una asignatura para su tarjeta. Una entrega o
/// examen que vence hoy o mañana va primero (en color de aviso); si no, la
/// próxima clase; si no hay clases, la entrega más cercana y, por último, la
/// próxima evaluación que la persona apuntó a mano.
class SubjectNextUp {
  const SubjectNextUp._(this.icon, this.urgent, this.text, [this._label]);

  final IconData icon;
  final bool urgent;

  /// Texto visible (en la clase, corto: «lun 10:00 · Aula 2.3»).
  final String Function(BuildContext context) text;
  final String Function(BuildContext context)? _label;

  /// Lo que oye el lector de pantalla (la frase entera).
  String label(BuildContext context) => (_label ?? text)(context);

  static SubjectNextUp? of(Subject subject, DateTime now) {
    final deadline = subject.nextDeadline;
    final deadlineDays = deadline == null
        ? null
        : AppDueDates.daysUntil(deadline.dueAt, now);
    SubjectNextUp deadlineUp(SubjectDeadline d, int days) => SubjectNextUp._(
      d.exam ? Icons.quiz_outlined : Icons.assignment_outlined,
      AppDueDates.isSoon(d.dueAt, now),
      (context) => d.exam
          ? context.localizations.academicNextExamIn(days)
          : context.localizations.academicNextDeliveryIn(days),
    );
    if (deadline != null &&
        deadlineDays != null &&
        deadlineDays >= 0 &&
        deadlineDays <= AppDueDates.urgentDays) {
      return deadlineUp(deadline, deadlineDays);
    }
    final classAt = subject.nextClassAt;
    if (classAt != null && classAt.isAfter(now)) {
      return SubjectNextUp._(
        Icons.co_present_outlined,
        false,
        (context) => nextClassText(
          context,
          classAt,
          subject.nextClassPlace,
          short: true,
        ),
        (context) => nextClassText(context, classAt, subject.nextClassPlace),
      );
    }
    if (deadline != null && deadlineDays != null && deadlineDays >= 0) {
      return deadlineUp(deadline, deadlineDays);
    }
    final assessment = subject.nextAssessmentAt;
    final days = assessment == null
        ? null
        : AppDueDates.daysUntil(assessment, now);
    if (assessment == null || days == null || days < 0) return null;
    return SubjectNextUp._(
      Icons.event_rounded,
      AppDueDates.isSoon(assessment, now),
      (context) {
        final l10n = context.localizations;
        return switch (days) {
          0 => l10n.academicAssessmentToday,
          1 => l10n.academicAssessmentTomorrow,
          <= 6 => l10n.academicAssessmentIn(days),
          _ => l10n.academicAssessmentOn(DateFormat.MMMd().format(assessment)),
        };
      },
    );
  }
}
