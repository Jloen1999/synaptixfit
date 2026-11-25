import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/academic/subject.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'academic_visuals.dart';
import 'academic_widgets.dart';

/// Tarjeta de asignatura de Académico (ADR 0057), legible de un vistazo: el
/// nombre en grande; «6 ECTS · 2.º curso · 1.er cuatri»; cuántos temas lleva
/// hechos (o la invitación a importar la guía); los repasos de hoy y lo
/// próximo. Todo lo calcula el servidor; profesor y apuntes van en el detalle.
class SubjectCard extends StatelessWidget {
  const SubjectCard({
    super.key,
    required this.subject,
    required this.onTap,
    this.onImportGuide,
  });

  final Subject subject;
  final VoidCallback onTap;

  /// «Sin temario: importa la guía». Va fuera de la zona que abre la
  /// asignatura (nada de toques anidados); sin él, no se ofrece.
  final VoidCallback? onImportGuide;

  @override
  Widget build(BuildContext context) {
    final color = subjectColor(context, subject.id);
    final l10n = context.localizations;
    final meta = subjectMetaText(context, subject);
    final done = subject.topicsDone ?? 0;
    final total = subject.topicsTotal ?? 0;
    final next = SubjectNextUpView.of(subject);
    final importGuide = !subject.hasSyllabus && !subject.archived
        ? onImportGuide
        : null;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: TokensSize.blockStripe, color: color),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCardTapArea(
                    borderRadius: BorderRadius.circular(TokensRadius.l),
                    onTap: onTap,
                    padding: EdgeInsets.fromLTRB(
                      TokensSpacing.m,
                      TokensSpacing.m,
                      TokensSpacing.m,
                      importGuide == null ? TokensSpacing.m : TokensSpacing.xs,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                subject.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.textStyles.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (subject.archived)
                              Icon(
                                AppIcons.archive,
                                size: TokensSize.iconS,
                                color: context.colors.onSurfaceVariant,
                                semanticLabel:
                                    l10n.academicSubjectArchivedBadge,
                              ),
                          ],
                        ),
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: TokensSpacing.xxs),
                          Text(
                            meta,
                            style: context.textStyles.bodyMedium?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (subject.hasSyllabus) ...[
                          const SizedBox(height: TokensSpacing.s),
                          Row(
                            children: [
                              Expanded(
                                child: ExcludeSemantics(
                                  child: AcademicProgressBar(
                                    value: done / total,
                                    color: context.palette.study,
                                  ),
                                ),
                              ),
                              const SizedBox(width: TokensSpacing.s),
                              Text(
                                l10n.academicTopicsProgress(done, total),
                                style: context.textStyles.labelLarge,
                              ),
                            ],
                          ),
                        ],
                        if (subject.reviewsDueToday > 0) ...[
                          const SizedBox(height: TokensSpacing.s),
                          AppPill(
                            label: l10n.academicReviewsToday(
                              subject.reviewsDueToday,
                            ),
                            color: context.palette.study,
                            icon: AppIcons.review,
                          ),
                        ],
                        if (next != null) ...[
                          const SizedBox(height: TokensSpacing.s),
                          _NextUpRow(next: next),
                        ],
                      ],
                    ),
                  ),
                  if (importGuide != null)
                    // Con el mismo margen que el texto de la tarjeta: el
                    // botón empieza donde el nombre, no encima de la franja.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        TokensSpacing.m,
                        0,
                        TokensSpacing.m,
                        TokensSpacing.m,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        // El lector oye de qué asignatura es cada botón.
                        child: Semantics(
                          container: true,
                          button: true,
                          excludeSemantics: true,
                          label: l10n.academicImportGuideFor(subject.name),
                          onTap: importGuide,
                          // Tonal (secundario, ADR 0065): como texto suelto
                          // no se reconocía como botón.
                          child: FilledButton.tonal(
                            onPressed: importGuide,
                            child: Text(l10n.academicNoSyllabusImport),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «Lo próximo» de la tarjeta en una franja suave: icono y texto. Si urge
/// (hoy o mañana) el icono va en color de aviso; el texto ya lo dice.
class _NextUpRow extends StatelessWidget {
  const _NextUpRow({required this.next});

  final SubjectNextUpView next;

  @override
  Widget build(BuildContext context) {
    final color = next.urgent
        ? context.palette.warning
        : context.colors.onSurfaceVariant;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(TokensRadius.m),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: TokensSpacing.sm,
          vertical: TokensSpacing.s,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(next.icon, size: TokensSize.iconXs, color: color),
            const SizedBox(width: TokensSpacing.s),
            Expanded(
              child: Text(
                next.text(context),
                semanticsLabel: next.label(context),
                style: context.textStyles.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  // El aviso en color solo como icono: en texto no llega al
                  // contraste AA en tema claro.
                  color: context.colors.onSurface,
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
  const SubjectNextUpView._(this.icon, this.urgent, this.text);

  final IconData icon;
  final bool urgent;

  /// La frase entera («Próxima clase: lun 10:00 · Aula 2.3»): en la lista de
  /// una columna cabe, y es también lo que oye el lector.
  final String Function(BuildContext context) text;

  /// Lo que oye el lector de pantalla.
  String label(BuildContext context) => text(context);

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
