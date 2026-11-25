import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/enums/evaluation_mode.dart';
import '../../../../../domain/enums/pass_outlook.dart';
import '../../../../../domain/models/academic/teaching_guide.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/academic_visuals.dart';
import '../bloc/subject_progress_bloc.dart';
import 'guide_import_entry.dart';
import 'subject_tab_body.dart';

/// Pestaña Evaluación (ADR 0057): «Cómo te evalúan» (continua o global),
/// «Tu nota» en puntos con la frase de lo que falta para aprobar y las pruebas
/// con su nota. Las cuentas y la frase las decide el servidor.
class EvaluationTab extends StatelessWidget {
  const EvaluationTab({super.key});

  @override
  Widget build(BuildContext context) => SubjectTabBody(
    children: (context, state) {
      final guide = state.guide;
      final l10n = context.localizations;
      if (guide == null) {
        return [
          GuideMissingView(
            subjectId: state.subjectId,
            icon: Icons.grade_outlined,
            title: l10n.academicEvaluationEmptyTitle,
            message: l10n.academicEvaluationEmptyMessage,
          ),
        ];
      }
      if (guide.assessments.isEmpty) {
        return [
          GuideMissingView(
            subjectId: state.subjectId,
            icon: Icons.grade_outlined,
            title: l10n.academicGradeNoCriteria,
            guide: guide,
          ),
        ];
      }
      return [
        if (guide.availableModes.length > 1) ...[
          _ModeChoice(guide: guide, saving: state.savingGrade),
          const SizedBox(height: TokensSpacing.m),
        ],
        YourGradeCard(estimate: guide.estimate),
        const SizedBox(height: TokensSpacing.m),
        _AssessmentsCard(guide: guide, saving: state.savingGrade),
      ];
    },
  );
}

/// «Cómo te evalúan»: Continua / Global (solo examen), con su «?».
class _ModeChoice extends StatelessWidget {
  const _ModeChoice({required this.guide, required this.saving});

  final TeachingGuide guide;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppHelpToggle(
          tooltip: l10n.academicEvaluationHelpTooltip,
          help: l10n.academicEvaluationHelp,
          child: Semantics(
            header: true,
            child: Text(
              l10n.academicGuideModeLabel,
              style: context.textStyles.titleSmall,
            ),
          ),
        ),
        SegmentedButton<EvaluationMode>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: EvaluationMode.continuous,
              label: Text(l10n.academicModeContinuous),
            ),
            ButtonSegment(
              value: EvaluationMode.global,
              label: Text(l10n.academicModeGlobal),
            ),
          ],
          selected: {guide.effectiveMode ?? guide.availableModes.first},
          onSelectionChanged: saving
              ? null
              : (s) => context.read<SubjectProgressBloc>().add(
                  SubjectProgressEvent.modeChanged(s.first),
                ),
        ),
      ],
    );
  }
}

/// «Tu nota»: puntos que llevas de los posibles en lo ya evaluado y una sola
/// frase según [GradeEstimate.outlook] (sin notas, la media que falta, ya
/// aprobado o ya no se llega).
class YourGradeCard extends StatelessWidget {
  const YourGradeCard({super.key, required this.estimate});

  final GradeEstimate? estimate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final e = estimate;
    final outlook = e?.outlook ?? PassOutlook.noGrades;
    final graded = e != null && outlook != PassOutlook.noGrades;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.academicGradeSimulator,
              style: context.textStyles.titleMedium,
            ),
          ),
          if (graded) ...[
            const SizedBox(height: TokensSpacing.s),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: grade(e.earnedPoints),
                    style: context.textStyles.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text: ' ${l10n.academicPointsOf(grade(e.possiblePoints))}',
                    style: context.textStyles.titleMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              semanticsLabel: l10n.academicPointsOfTotal(
                grade(e.earnedPoints),
                grade(e.possiblePoints),
              ),
            ),
            Text(
              l10n.academicPointsSoFar(e.coveredPercentage.round()),
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: TokensSpacing.sm),
          _OutlookNote(estimate: e, outlook: outlook),
        ],
      ),
    );
  }
}

class _OutlookNote extends StatelessWidget {
  const _OutlookNote({required this.estimate, required this.outlook});

  final GradeEstimate? estimate;
  final PassOutlook outlook;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final required = estimate?.requiredGradeToPass;
    final (icon, tint, text) = switch (outlook) {
      PassOutlook.alreadyPassed => (
        Icons.check_circle_outline_rounded,
        context.palette.success,
        l10n.academicPassAlready,
      ),
      PassOutlook.outOfReach => (
        Icons.error_outline_rounded,
        context.palette.warning,
        l10n.academicPassOutOfReach,
      ),
      PassOutlook.needsAverage when required != null => (
        AppIcons.goal,
        context.colors.primary,
        l10n.academicPassNeeds(grade(required)),
      ),
      _ => (
        Icons.edit_note_rounded,
        context.colors.onSurfaceVariant,
        l10n.academicPassNoGrades,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          tint.withValues(alpha: AppPill.tintAlpha),
          context.colors.surface,
        ),
        borderRadius: BorderRadius.circular(TokensRadius.m),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TokensSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: tint, size: TokensSize.iconS),
            const SizedBox(width: TokensSpacing.s),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: Text(
                  text,
                  style: context.textStyles.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «Pruebas»: las de la modalidad activa, con su peso, fecha, «sin segunda
/// oportunidad» si la guía lo dice y la nota (o «Poner nota»).
class _AssessmentsCard extends StatelessWidget {
  const _AssessmentsCard({required this.guide, required this.saving});

  final TeachingGuide guide;
  final bool saving;

  Future<void> _editGrade(BuildContext context, Assessment assessment) async {
    final bloc = context.read<SubjectProgressBloc>();
    final result = await showModalBottomSheet<({double? value})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _GradeSheet(assessment: assessment),
    );
    if (result != null) {
      bloc.add(
        SubjectProgressEvent.gradeChanged(
          index: assessment.index,
          grade: result.value,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final active = guide.assessments.where((a) => a.active).toList();
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: TokensSpacing.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.m),
            child: Semantics(
              header: true,
              child: Text(
                l10n.academicTestsTitle,
                style: context.textStyles.titleMedium,
              ),
            ),
          ),
          // Alto reservado: la barra de guardado no desplaza la lista.
          SizedBox(
            height: TokensSize.progressBar,
            child: saving ? const LinearProgressIndicator() : null,
          ),
          if (active.isEmpty)
            Padding(
              padding: const EdgeInsets.all(TokensSpacing.m),
              child: Text(l10n.academicGradeNoCriteria),
            ),
          for (final a in active)
            _AssessmentRow(
              stacked: context.largeText,
              action: a.grade == null
                  ? OutlinedButton.icon(
                      onPressed: saving ? null : () => _editGrade(context, a),
                      icon: const Icon(AppIcons.add),
                      label: Text(l10n.academicGradeAdd),
                    )
                  : _GradeChip(
                      value: a.grade!,
                      onPressed: saving ? null : () => _editGrade(context, a),
                    ),
              tile: ListTile(
                title: Text(a.name),
                subtitle: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: [
                          l10n.academicGradeWeight(a.percentage.round()),
                          if (a.dueDate != null) shortDate(a.dueDate!),
                        ].join(' · '),
                      ),
                      if (a.recoverable == false)
                        TextSpan(
                          text: ' · ${l10n.academicNotRecoverable}',
                          style: context.textStyles.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TokensSpacing.m,
              TokensSpacing.xs,
              TokensSpacing.m,
              TokensSpacing.xs,
            ),
            child: Text(
              l10n.academicGradeEnterHint,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de una prueba: la acción se ve («Poner nota» o la nota, verde si
/// aprueba). Al lado del nombre o, con el texto grande, debajo.
class _AssessmentRow extends StatelessWidget {
  const _AssessmentRow({
    required this.tile,
    required this.action,
    required this.stacked,
  });

  final ListTile tile;
  final Widget action;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    if (!stacked) {
      return AppFocusOutline(
        child: ListTile(
          title: tile.title,
          subtitle: tile.subtitle,
          trailing: action,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tile,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.m),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: action,
          ),
        ),
      ],
    );
  }
}

/// Nota puesta: verde si aprueba (5 o más), de aviso si no; con lápiz.
class _GradeChip extends StatelessWidget {
  const _GradeChip({required this.value, required this.onPressed});

  final double value;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final passed = value >= _GradeSheet.passMark;
    final color = passed ? context.palette.success : context.palette.warning;
    // Aprobado o no con icono y en el texto accesible, no solo con el color.
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: color),
      icon: Icon(
        passed
            ? Icons.check_circle_outline_rounded
            : Icons.error_outline_rounded,
        size: TokensSize.iconXs,
      ),
      label: Text(
        grade(value),
        semanticsLabel: l10n.academicGradeEditSemantics(
          grade(value),
          passed ? l10n.academicGradePassed : l10n.academicGradeFailed,
        ),
        style: context.textStyles.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Hoja para poner la nota de una prueba: número grande, deslizador de 0 a 10
/// (de 0,25 en 0,25), atajos 5-10 y un campo para la nota exacta.
class _GradeSheet extends StatefulWidget {
  const _GradeSheet({required this.assessment});

  final Assessment assessment;

  /// Aprobado en la escala española (0-10): solo colorea la nota puesta.
  static const passMark = 5.0;

  @override
  State<_GradeSheet> createState() => _GradeSheetState();
}

class _GradeSheetState extends State<_GradeSheet> {
  late double _value = widget.assessment.grade ?? _GradeSheet.passMark;
  late final _text = TextEditingController(text: grade(_value));

  /// El campo tiene un valor que no es una nota de 0 a 10.
  bool _invalid = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _set(double v, {bool fromText = false}) {
    setState(() {
      _value = v.clamp(0, 10).toDouble();
      _invalid = false;
    });
    if (!fromText) _text.text = grade(_value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final color = _value >= _GradeSheet.passMark
        ? context.palette.success
        : context.palette.warning;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        TokensSpacing.m,
        0,
        TokensSpacing.m,
        TokensSpacing.m + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                widget.assessment.name,
                style: context.textStyles.titleMedium,
              ),
            ),
            Text(
              l10n.academicGradeWeight(widget.assessment.percentage.round()),
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: TokensSpacing.m),
            Center(
              child: Text(
                grade(_value),
                style: context.textStyles.displaySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Center(
              child: Text(
                _value >= _GradeSheet.passMark
                    ? l10n.academicGradePassed
                    : l10n.academicGradeFailed,
                style: context.textStyles.labelLarge?.copyWith(color: color),
              ),
            ),
            Slider(
              value: _value,
              max: 10,
              divisions: 40,
              label: grade(_value),
              semanticFormatterCallback: (v) => grade(v),
              onChanged: _set,
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: TokensSpacing.xs,
              runSpacing: TokensSpacing.xs,
              children: [
                for (final quick in const [5.0, 6.0, 7.0, 8.0, 9.0, 10.0])
                  ChoiceChip(
                    label: Text(grade(quick)),
                    selected: _value == quick,
                    onSelected: (_) => _set(quick),
                  ),
              ],
            ),
            const SizedBox(height: TokensSpacing.m),
            TextField(
              controller: _text,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                labelText: l10n.academicGradeLabel,
                hintText: l10n.academicGradeHint,
                errorText: _invalid ? l10n.academicGradeOutOfRange : null,
              ),
              onChanged: (t) {
                final v = double.tryParse(t.trim().replaceAll(',', '.'));
                if (v != null && v >= 0 && v <= 10) {
                  _set(v, fromText: true);
                } else {
                  setState(() => _invalid = t.trim().isNotEmpty);
                }
              },
            ),
            const SizedBox(height: TokensSpacing.m),
            Row(
              children: [
                if (widget.assessment.grade != null)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop((value: null)),
                    child: Text(l10n.academicGradeClear),
                  ),
                const Spacer(),
                AppPrimaryButton(
                  label: l10n.commonSave,
                  onPressed: _invalid
                      ? null
                      : () => Navigator.of(context).pop((value: _value)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
