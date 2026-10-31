import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../app/validators/validators.dart';
import '../../../../../domain/enums/challenge_difficulty.dart';
import '../../../../../domain/enums/challenge_type.dart';
import '../../../../../domain/models/challenges/challenge.dart';
import '../../../../../domain/models/challenges/challenge_draft_validator.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../challenges_routes.dart';
import '../../widgets/challenge_labels.dart';
import '../../widgets/challenge_focus.dart';
import '../../widgets/challenge_selectors.dart';
import '../bloc/quick_challenge_bloc.dart';

/// Resultado de la hoja de creación rápida.
sealed class QuickChallengeResult {
  const QuickChallengeResult();
}

/// Reto creado o editado desde la hoja.
final class QuickChallengeSaved extends QuickChallengeResult {
  const QuickChallengeSaved(this.challenge);

  final Challenge challenge;
}

/// Reto creado desde la pantalla completa abierta con «Añadir tareas».
final class QuickChallengeCreatedWithTasks extends QuickChallengeResult {
  const QuickChallengeCreatedWithTasks(this.challengeId);

  final String challengeId;
}

/// Abre la hoja reutilizable de creación rápida (o de edición de los datos
/// básicos con [editing]). Con «Añadir tareas» abre `/challenges/new`
/// conservando lo escrito. Se puede usar desde otros módulos.
Future<QuickChallengeResult?> showQuickChallengeSheet(
  BuildContext context, {
  Challenge? editing,
  String? prefilledTitle,
  String? subjectId,
  String? subjectName,
}) async {
  final result = await showModalBottomSheet<Object>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => BlocProvider(
      create: (_) =>
          getIt<QuickChallengeBloc>()..add(const QuickChallengeEvent.started()),
      child: _QuickChallengeView(
        editing: editing,
        prefilledTitle: prefilledTitle,
        subjectId: subjectId,
        subjectName: subjectName,
      ),
    ),
  );
  if (result is Challenge) return QuickChallengeSaved(result);
  if (result is ChallengeFormArgs && context.mounted) {
    final id = await context.push<String>(
      ChallengesPaths.create,
      extra: result,
    );
    return id == null ? null : QuickChallengeCreatedWithTasks(id);
  }
  return null;
}

class _QuickChallengeView extends StatefulWidget {
  const _QuickChallengeView({
    this.editing,
    this.prefilledTitle,
    this.subjectId,
    this.subjectName,
  });

  final Challenge? editing;
  final String? prefilledTitle;
  final String? subjectId;
  final String? subjectName;

  @override
  State<_QuickChallengeView> createState() => _QuickChallengeViewState();
}

class _QuickChallengeViewState extends State<_QuickChallengeView>
    with ErrorsMessageMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _sessionTarget;
  late ChallengeType _type;
  late ChallengeDifficulty _difficulty;
  late DateTime _endAt;
  String? _subjectId;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    final now = DateTime.now();
    _title = TextEditingController(
      text: editing?.title ?? widget.prefilledTitle ?? '',
    );
    _type = editing?.type ?? context.defaultChallengeType;
    _difficulty = editing?.difficulty ?? ChallengeDifficulty.medium;
    _endAt =
        editing?.endAt ?? DateTime(now.year, now.month, now.day + 7, 23, 59);
    _subjectId = editing?.subjectId ?? widget.subjectId;
    _sessionTarget = TextEditingController(
      text: editing?.sessionTarget?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _sessionTarget.dispose();
    super.dispose();
  }

  String? _validateTitle(String? value) {
    final failure = Validators.minLength(value, 5);
    if (failure == ValidationFailure.required) {
      return context.localizations.validationRequired;
    }
    if (failure != null || (value?.trim().length ?? 0) > 80) {
      return context.localizations.challengesValidationTitle;
    }
    return null;
  }

  /// Con tareas el progreso lo marcan ellas, así que el objetivo no aplica.
  bool get _showsSessionTarget =>
      _type == ChallengeType.fitness &&
      !(widget.editing?.hasMilestones ?? false);

  int? get _parsedSessionTarget =>
      _showsSessionTarget ? int.tryParse(_sessionTarget.text.trim()) : null;

  String? _validateSessionTarget(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final target = int.tryParse(text);
    return target == null ||
            !ChallengeDraftValidator.isValidSessionTarget(target)
        ? context.localizations.challengesIssueSessionTarget
        : null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<QuickChallengeBloc>().add(
      QuickChallengeEvent.submitted(
        editing: widget.editing,
        title: _title.text.trim(),
        type: _type,
        difficulty: _difficulty,
        endAt: _endAt,
        subjectId: _subjectId,
        sessionTarget: _parsedSessionTarget,
      ),
    );
  }

  void _openFullForm() {
    Navigator.of(context).pop(
      ChallengeFormArgs(
        title: _title.text.trim(),
        subjectId: _subjectId,
        subjectName: widget.subjectName,
        type: _type,
        difficulty: _difficulty,
        endAt: _endAt,
        sessionTarget: _parsedSessionTarget,
      ),
    );
  }

  Future<void> _pickEnd() async {
    final picked = await pickChallengeEndDate(context, initial: _endAt);
    if (picked != null) setState(() => _endAt = picked);
  }

  /// Fin de un reto que empieza hoy y dura lo indicado (a las 23:59, como el
  /// selector de fecha).
  static DateTime _endIn({int days = 0, int months = 0}) {
    final now = DateTime.now();
    if (months == 0) {
      return DateTime(now.year, now.month, now.day + days, 23, 59);
    }
    // Un 31 + 1 mes no salta al mes siguiente: se queda en su último día.
    final lastDay = DateTime(now.year, now.month + months + 1, 0).day;
    final day = now.day < lastDay ? now.day : lastDay;
    return DateTime(now.year, now.month + months, day, 23, 59);
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final editing = widget.editing;
    return BlocConsumer<QuickChallengeBloc, QuickChallengeState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.status == QuickChallengeStatus.saved) {
          Navigator.of(context).pop(state.saved);
        }
      },
      builder: (context, state) {
        final saving = state.status == QuickChallengeStatus.saving;
        final error = state.error;
        return Padding(
          padding: EdgeInsets.only(
            left: TokensSpacing.l,
            right: TokensSpacing.l,
            bottom: MediaQuery.viewInsetsOf(context).bottom + TokensSpacing.l,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      editing == null
                          ? l10n.challengesQuickTitle
                          : l10n.challengesQuickEditTitle,
                      style: context.textStyles.titleLarge,
                    ),
                  ),
                  if (editing == null) ...[
                    const SizedBox(height: TokensSpacing.xs),
                    Text(
                      l10n.challengesQuickSubtitle,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: TokensSpacing.l),
                  AppTextField(
                    label: l10n.challengesFieldTitle,
                    // El ejemplo sigue al tipo: estudiar o entrenar.
                    hint: _type == ChallengeType.fitness
                        ? l10n.challengesFieldTitleHintFitness
                        : l10n.challengesFieldTitleHint,
                    controller: _title,
                    icon: Icons.flag_outlined,
                    textInputAction: TextInputAction.done,
                    validator: _validateTitle,
                  ),
                  const SizedBox(height: TokensSpacing.m),
                  ChallengeTypeField(
                    label: l10n.challengesFieldType,
                    value: _type,
                    onChanged: saving ? null : (t) => setState(() => _type = t),
                  ),
                  if (_showsSessionTarget) ...[
                    const SizedBox(height: TokensSpacing.m),
                    AppTextField(
                      label: l10n.challengesFieldSessionTarget,
                      hint: l10n.challengesFieldSessionTargetHint,
                      helper: l10n.challengesFieldSessionTargetHelper,
                      controller: _sessionTarget,
                      icon: Icons.fitness_center_rounded,
                      keyboardType: TextInputType.number,
                      enabled: !saving,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      validator: _validateSessionTarget,
                    ),
                  ],
                  const SizedBox(height: TokensSpacing.m),
                  Text(
                    l10n.challengesEffortLabel,
                    style: context.textStyles.labelLarge,
                  ),
                  const SizedBox(height: TokensSpacing.s),
                  EffortSelector(
                    value: _difficulty,
                    onChanged: saving
                        ? null
                        : (d) => setState(() => _difficulty = d),
                  ),
                  const SizedBox(height: TokensSpacing.m),
                  ChallengeDateField(
                    label: l10n.challengesFieldEndDate,
                    text: ChallengeFormats.longDate(_endAt),
                    onTap: saving ? null : _pickEnd,
                  ),
                  const SizedBox(height: TokensSpacing.s),
                  // Atajos de duración: un toque en vez de abrir el calendario.
                  Semantics(
                    container: true,
                    label: l10n.challengesDurationLabel,
                    child: Wrap(
                      spacing: TokensSpacing.s,
                      runSpacing: TokensSpacing.xs,
                      children: [
                        for (final (label, end) in [
                          (l10n.challengesDurationWeek, _endIn(days: 7)),
                          (l10n.challengesDurationTwoWeeks, _endIn(days: 14)),
                          (l10n.challengesDurationMonth, _endIn(months: 1)),
                        ])
                          ChoiceChip(
                            label: Text(label),
                            selected: _sameDay(_endAt, end),
                            onSelected: saving
                                ? null
                                : (_) => setState(() => _endAt = end),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: TokensSpacing.m),
                  if (state.status == QuickChallengeStatus.loading)
                    const AppSkeletonGroup(child: AppSkeleton(height: 56))
                  else
                    ChallengeSubjectDropdown(
                      subjects: state.subjects,
                      value: _subjectId,
                      fallbackName: widget.subjectName,
                      onChanged: saving
                          ? null
                          : (id) => setState(() {
                              _subjectId = id;
                              if (id != null) _type = ChallengeType.academic;
                            }),
                    ),
                  if (error != null) ...[
                    const SizedBox(height: TokensSpacing.m),
                    AppInlineMessage(message: errorMessage(context, error)),
                  ],
                  const SizedBox(height: TokensSpacing.l),
                  AppPrimaryButton(
                    label: editing == null
                        ? l10n.challengesQuickCreate
                        : l10n.commonSave,
                    loading: saving,
                    onPressed: _submit,
                  ),
                  if (editing == null) ...[
                    const SizedBox(height: TokensSpacing.s),
                    TextButton.icon(
                      onPressed: saving ? null : _openFullForm,
                      icon: const Icon(Icons.playlist_add_rounded),
                      label: Text(l10n.challengesQuickAddTasks),
                    ),
                    Text(
                      l10n.challengesQuickAddTasksHint,
                      textAlign: TextAlign.center,
                      style: context.textStyles.labelMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
