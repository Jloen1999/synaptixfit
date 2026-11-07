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
  const SubjectCard({super.key, required this.subject, required this.onTap});

  final Subject subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = subjectColor(context, subject.id);
    final l10n = context.localizations;
    final next = SubjectNextUpView.of(subject);
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

/// Cómo se pinta lo próximo de una asignatura ([Subject.nextUp], que elige el
/// servidor: lo urgente primero). Aquí solo se decide icono y texto; urgente va
/// en color de aviso.
class SubjectNextUpView {
  const SubjectNextUpView._(this.icon, this.urgent, this.text, [this._label]);

  final IconData icon;
  final bool urgent;

  /// Texto visible (en la clase, corto: «lun 10:00 · Aula 2.3»).
  final String Function(BuildContext context) text;
  final String Function(BuildContext context)? _label;

  /// Lo que oye el lector de pantalla (la frase entera).
  String label(BuildContext context) => (_label ?? text)(context);

  static SubjectNextUpView? of(Subject subject) {
    final next = subject.nextUp;
    if (next == null) return null;
    final days = next.daysLeft;
    return switch (next.kind) {
      SubjectNextUpKind.delivery => SubjectNextUpView._(
        AppIcons.delivery,
        next.urgent,
        (context) => context.localizations.academicNextDeliveryIn(days),
      ),
      SubjectNextUpKind.exam => SubjectNextUpView._(
        AppIcons.exam,
        next.urgent,
        (context) => context.localizations.academicNextExamIn(days),
      ),
      SubjectNextUpKind.classSession => SubjectNextUpView._(
        Icons.co_present_outlined,
        next.urgent,
        (context) => nextClassText(context, next.at, next.place, short: true),
        (context) => nextClassText(context, next.at, next.place),
      ),
      SubjectNextUpKind.assessment => SubjectNextUpView._(
        AppIcons.calendar,
        next.urgent,
        (context) {
          final l10n = context.localizations;
          return switch (days) {
            0 => l10n.academicAssessmentToday,
            1 => l10n.academicAssessmentTomorrow,
            <= 6 => l10n.academicAssessmentIn(days),
            _ => l10n.academicAssessmentOn(DateFormat.MMMd().format(next.at)),
          };
        },
      ),
    };
  }
}
