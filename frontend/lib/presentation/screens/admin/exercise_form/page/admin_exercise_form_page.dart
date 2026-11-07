import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/admin/admin_exercise_difficulty.dart';
import '../../../../../domain/enums/admin/admin_exercise_modality.dart';
import '../../../../../domain/enums/admin/admin_exercise_purpose.dart';
import '../../../../../domain/enums/admin/admin_measurement_type.dart';
import '../../../../../domain/models/admin/admin_exercise.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/admin_labels.dart';
import '../../widgets/admin_multi_select_field.dart';
import '../../widgets/admin_status.dart';
import '../../widgets/admin_widgets.dart';
import '../bloc/admin_exercise_form_bloc.dart';

/// Alta (sin [exerciseId]) o edición de un ejercicio. Al guardar vuelve con `true`.
class AdminExerciseFormPage extends StatelessWidget {
  const AdminExerciseFormPage({super.key, this.exerciseId});

  final String? exerciseId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<AdminExerciseFormBloc>()
            ..add(AdminExerciseFormEvent.started(exerciseId: exerciseId)),
      child: const _AdminExerciseFormView(),
    );
  }
}

class _AdminExerciseFormView extends StatefulWidget {
  const _AdminExerciseFormView();

  @override
  State<_AdminExerciseFormView> createState() => _AdminExerciseFormViewState();
}

/// Paso de instrucciones con identificador estable para reordenar.
class _Step {
  _Step(this.id, String text) : controller = TextEditingController(text: text);

  final int id;
  final TextEditingController controller;
}

class _AdminExerciseFormViewState extends State<_AdminExerciseFormView>
    with ErrorsMessageMixin {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _met = TextEditingController();
  final _gifUrl = TextEditingController();
  final _previewUrl = TextEditingController();
  final _nameEn = TextEditingController();
  final _nameFr = TextEditingController();
  final _namePt = TextEditingController();
  final _steps = <_Step>[];
  var _nextStepId = 0;

  AdminExerciseFormBloc get _bloc => context.read<AdminExerciseFormBloc>();

  @override
  void dispose() {
    for (final c in [
      _name,
      _description,
      _met,
      _gifUrl,
      _previewUrl,
      _nameEn,
      _nameFr,
      _namePt,
    ]) {
      c.dispose();
    }
    for (final step in _steps) {
      step.controller.dispose();
    }
    super.dispose();
  }

  /// Rellena los campos de texto con el borrador cargado.
  void _fill(AdminExerciseDraft draft) {
    _name.text = draft.name;
    _description.text = draft.description;
    _met.text = AdminFormat.decimal(draft.met).replaceAll(',', '.');
    _gifUrl.text = draft.gifUrl;
    _previewUrl.text = draft.previewUrl;
    _fillNames(draft.translations);
    for (final step in _steps) {
      step.controller.dispose();
    }
    _steps
      ..clear()
      ..addAll([
        for (final text in draft.instructions) _Step(_nextStepId++, text),
      ]);
    setState(() {});
  }

  void _fillNames(AdminExerciseNames? names) {
    _nameEn.text = names?.en ?? '';
    _nameFr.text = names?.fr ?? '';
    _namePt.text = names?.pt ?? '';
  }

  /// Cambia un idioma sin tocar los demás (solo si los nombres se cargaron).
  void _updateNames(AdminExerciseNames Function(AdminExerciseNames n) change) =>
      _update(
        (d) => d.translations == null
            ? d
            : d.copyWith(translations: change(d.translations!)),
      );

  void _update(AdminExerciseDraft Function(AdminExerciseDraft d) change) =>
      _bloc.add(AdminExerciseFormEvent.draftChanged(change(_bloc.state.draft)));

  void _syncSteps() {
    setState(() {});
    _update(
      (d) => d.copyWith(
        instructions: [for (final step in _steps) step.controller.text],
      ),
    );
  }

  void _addStep() {
    _steps.add(_Step(_nextStepId++, ''));
    _syncSteps();
  }

  void _removeStep(int index) {
    _steps.removeAt(index).controller.dispose();
    _syncSteps();
  }

  void _moveStep(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _steps.length) return;
    final step = _steps.removeAt(index);
    _steps.insert(target, step);
    _syncSteps();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<AdminExerciseFormBloc, AdminExerciseFormState>(
      listenWhen: (a, b) =>
          (a.status != AdminStatus.ready && b.status == AdminStatus.ready) ||
          (a.effect != b.effect && b.effect != null) ||
          a.namesRevision != b.namesRevision,
      listener: (context, state) {
        // Nombres propuestos por la IA: a sus campos, sin tocar el resto.
        if (state.namesRevision > 0 && state.effect == null) {
          _fillNames(state.draft.translations);
          if (state.status == AdminStatus.ready) return;
        }
        final effect = state.effect;
        if (effect == null) {
          _fill(state.draft);
          return;
        }
        switch (effect) {
          case AdminExerciseFormSavedEffect():
            context.showSnack(l10n.adminExerciseSaved);
            context.pop(true);
          case AdminExerciseFormFailureEffect(:final error):
            context.showSnack(errorMessage(context, error));
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppPageBar.reading(
            title: Text(
              state.isEditing
                  ? l10n.adminExerciseEditTitle
                  : l10n.adminExerciseNewTitle,
            ),
          ),
          body: switch (state.status) {
            AdminStatus.failure => AppErrorView(
              error: state.error!,
              onRetry: () => _bloc.add(
                AdminExerciseFormEvent.started(exerciseId: state.exerciseId),
              ),
            ),
            AdminStatus.ready => _buildForm(context, state),
            _ => const AppSkeletonList(count: 6, height: 64),
          },
          bottomNavigationBar: state.status == AdminStatus.ready
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(TokensSpacing.m),
                    child: Center(
                      heightFactor: 1,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: TokensLayout.readingMaxWidth,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: AppPrimaryButton(
                            label: l10n.commonSave,
                            loading: state.submitting,
                            onPressed: () => _bloc.add(
                              const AdminExerciseFormEvent.submitted(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _buildForm(BuildContext context, AdminExerciseFormState state) {
    final l10n = context.localizations;
    final draft = state.draft;
    final show = state.showErrors;
    final options = state.options;
    const gap = SizedBox(height: TokensSpacing.m);
    return ListView(
      padding: const EdgeInsets.all(TokensSpacing.m),
      children: [
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: TokensLayout.readingMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.isEditing && !state.active)
                  Padding(
                    padding: const EdgeInsets.only(bottom: TokensSpacing.m),
                    child: AppPill(
                      label: l10n.adminExerciseInactiveNotice,
                      color: context.colors.error,
                      icon: Icons.pause_circle_outline_rounded,
                    ),
                  ),
                _Section(
                  title: l10n.adminExerciseSectionBasics,
                  children: [
                    // Al salir del nombre, si aún no hay nombres en otros
                    // idiomas, la IA los propone para revisarlos.
                    Focus(
                      onFocusChange: (focused) {
                        if (!focused) {
                          _bloc.add(
                            const AdminExerciseFormEvent.namesSuggested(
                              onlyIfEmpty: true,
                            ),
                          );
                        }
                      },
                      child: TextField(
                        controller: _name,
                        maxLength: AdminExerciseDraft.nameMax,
                        onChanged: (v) => _update((d) => d.copyWith(name: v)),
                        decoration: InputDecoration(
                          labelText: l10n.adminFieldExerciseName,
                          errorText: show && !draft.isNameValid
                              ? l10n.adminValidationExerciseName
                              : null,
                        ),
                      ),
                    ),
                    gap,
                    TextField(
                      controller: _description,
                      maxLines: 4,
                      minLines: 2,
                      maxLength: AdminExerciseDraft.descriptionMax,
                      onChanged: (v) =>
                          _update((d) => d.copyWith(description: v)),
                      decoration: InputDecoration(
                        labelText: l10n.adminFieldDescription,
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
                _NamesSection(
                  state: state,
                  english: _nameEn,
                  french: _nameFr,
                  portuguese: _namePt,
                  onSuggest: () =>
                      _bloc.add(const AdminExerciseFormEvent.namesSuggested()),
                  onChanged: _updateNames,
                ),
                _Section(
                  title: l10n.adminFieldInstructions,
                  trailing: TextButton.icon(
                    onPressed:
                        _steps.length >= AdminExerciseDraft.instructionsMax
                        ? null
                        : _addStep,
                    icon: const Icon(AppIcons.add),
                    label: Text(l10n.adminExerciseAddStep),
                  ),
                  children: [
                    if (_steps.isEmpty)
                      Text(
                        l10n.adminExerciseNoSteps,
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    for (var i = 0; i < _steps.length; i++)
                      _StepRow(
                        key: ValueKey(_steps[i].id),
                        index: i,
                        count: _steps.length,
                        controller: _steps[i].controller,
                        onChanged: (_) => _update(
                          (d) => d.copyWith(
                            instructions: [
                              for (final step in _steps) step.controller.text,
                            ],
                          ),
                        ),
                        onMoveUp: () => _moveStep(i, -1),
                        onMoveDown: () => _moveStep(i, 1),
                        onRemove: () => _removeStep(i),
                      ),
                  ],
                ),
                _Section(
                  title: l10n.adminExerciseSectionClassification,
                  children: [
                    _Label(l10n.adminFieldDifficulty),
                    SegmentedButton<AdminExerciseDifficulty>(
                      showSelectedIcon: false,
                      segments: [
                        for (final v in AdminExerciseDifficulty.values)
                          ButtonSegment(value: v, label: Text(v.label(l10n))),
                      ],
                      selected: {draft.difficulty},
                      onSelectionChanged: (s) =>
                          _update((d) => d.copyWith(difficulty: s.first)),
                    ),
                    gap,
                    _Label(l10n.adminFieldModalityExercise),
                    Wrap(
                      spacing: TokensSpacing.s,
                      runSpacing: TokensSpacing.xs,
                      children: [
                        for (final v in AdminExerciseModality.values)
                          ChoiceChip(
                            label: Text(v.label(l10n)),
                            selected: draft.modality == v,
                            onSelected: (_) =>
                                _update((d) => d.copyWith(modality: v)),
                          ),
                      ],
                    ),
                    gap,
                    _Label(l10n.adminFieldPurposes),
                    Wrap(
                      spacing: TokensSpacing.s,
                      runSpacing: TokensSpacing.xs,
                      children: [
                        for (final v in AdminExercisePurpose.values)
                          FilterChip(
                            label: Text(v.label(l10n)),
                            selected: draft.purposes.contains(v),
                            onSelected: (on) => _update(
                              (d) => d.copyWith(
                                purposes: on
                                    ? {...d.purposes, v}
                                    : ({...d.purposes}..remove(v)),
                              ),
                            ),
                          ),
                      ],
                    ),
                    gap,
                    _Label(l10n.adminFieldMeasurementTypes),
                    Wrap(
                      spacing: TokensSpacing.s,
                      runSpacing: TokensSpacing.xs,
                      children: [
                        for (final v in AdminMeasurementType.values)
                          FilterChip(
                            label: Text(v.label(l10n)),
                            selected: draft.measurementTypes.contains(v),
                            onSelected: (on) => _update(
                              (d) => d.copyWith(
                                measurementTypes: on
                                    ? {...d.measurementTypes, v}
                                    : ({...d.measurementTypes}..remove(v)),
                              ),
                            ),
                          ),
                      ],
                    ),
                    gap,
                    AppFocusOutline(
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.adminFieldCircuit),
                        subtitle: Text(l10n.adminFieldCircuitHint),
                        value: draft.circuit,
                        onChanged: (v) =>
                            _update((d) => d.copyWith(circuit: v)),
                      ),
                    ),
                    gap,
                    TextField(
                      controller: _met,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      onChanged: (v) => _update(
                        (d) => d.copyWith(
                          met: double.tryParse(v.replaceAll(',', '.')) ?? 0,
                        ),
                      ),
                      decoration: InputDecoration(
                        labelText: l10n.adminFieldMet,
                        helperText: l10n.adminFieldMetHint,
                        errorText: show && !draft.isMetValid
                            ? l10n.adminValidationMet
                            : null,
                      ),
                    ),
                  ],
                ),
                _Section(
                  title: l10n.adminExerciseSectionMedia,
                  children: [
                    TextField(
                      controller: _gifUrl,
                      keyboardType: TextInputType.url,
                      maxLength: AdminExerciseDraft.urlMax,
                      onChanged: (v) => _update((d) => d.copyWith(gifUrl: v)),
                      decoration: InputDecoration(
                        labelText: l10n.adminFieldGifUrl,
                        prefixIcon: const Icon(Icons.gif_box_outlined),
                      ),
                    ),
                    gap,
                    TextField(
                      controller: _previewUrl,
                      keyboardType: TextInputType.url,
                      maxLength: AdminExerciseDraft.urlMax,
                      onChanged: (v) =>
                          _update((d) => d.copyWith(previewUrl: v)),
                      decoration: InputDecoration(
                        labelText: l10n.adminFieldPreviewUrl,
                        prefixIcon: const Icon(Icons.image_outlined),
                      ),
                    ),
                  ],
                ),
                _Section(
                  title: l10n.adminExerciseSectionAnatomy,
                  children: [
                    AdminMultiSelectField(
                      label: l10n.adminFieldBodyParts,
                      options: options.bodyParts,
                      selected: draft.bodyPartIds,
                      onChanged: (v) =>
                          _update((d) => d.copyWith(bodyPartIds: v)),
                    ),
                    gap,
                    AdminMultiSelectField(
                      label: l10n.adminFieldTargetMuscles,
                      options: options.muscles,
                      selected: draft.targetMuscleIds,
                      onChanged: (v) =>
                          _update((d) => d.copyWith(targetMuscleIds: v)),
                    ),
                    gap,
                    AdminMultiSelectField(
                      label: l10n.adminFieldSecondaryMuscles,
                      options: options.muscles,
                      selected: draft.secondaryMuscleIds,
                      onChanged: (v) =>
                          _update((d) => d.copyWith(secondaryMuscleIds: v)),
                    ),
                    gap,
                    AdminMultiSelectField(
                      label: l10n.adminFieldEquipment,
                      options: options.equipment,
                      selected: draft.equipmentIds,
                      onChanged: (v) =>
                          _update((d) => d.copyWith(equipmentIds: v)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.trailing});

  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.m),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: context.textStyles.titleMedium),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: TokensSpacing.s),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Nombre del ejercicio en inglés, francés y portugués: la IA lo propone y la
/// administración lo revisa antes de guardar.
class _NamesSection extends StatelessWidget with ErrorsMessageMixin {
  const _NamesSection({
    required this.state,
    required this.english,
    required this.french,
    required this.portuguese,
    required this.onSuggest,
    required this.onChanged,
  });

  final AdminExerciseFormState state;
  final TextEditingController english;
  final TextEditingController french;
  final TextEditingController portuguese;
  final VoidCallback onSuggest;
  final void Function(AdminExerciseNames Function(AdminExerciseNames n))
  onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final names = state.draft.translations;
    final suggesting = state.suggestingNames;
    final canSuggest = names != null && !suggesting && state.draft.isNameValid;
    final muted = context.textStyles.bodySmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    final fields = [
      (
        english,
        l10n.adminFieldNameEnglish,
        (AdminExerciseNames n, String v) => n.copyWith(en: v),
      ),
      (
        french,
        l10n.adminFieldNameFrench,
        (AdminExerciseNames n, String v) => n.copyWith(fr: v),
      ),
      (
        portuguese,
        l10n.adminFieldNamePortuguese,
        (AdminExerciseNames n, String v) => n.copyWith(pt: v),
      ),
    ];
    return _Section(
      title: l10n.adminExerciseSectionNames,
      trailing: TextButton.icon(
        onPressed: canSuggest ? onSuggest : null,
        icon: suggesting
            ? const SizedBox.square(
                dimension: TokensSize.iconS,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.auto_awesome_rounded),
        label: Text(l10n.adminExerciseNamesSuggest),
      ),
      children: [
        if (names == null)
          Text(l10n.adminExerciseNamesUnavailable, style: muted)
        else ...[
          Text(
            state.draft.isNameValid
                ? l10n.adminExerciseNamesHint
                : l10n.adminExerciseNamesNeedName,
            style: muted,
          ),
          // Se anuncia al empezar y al fallar: lo provoca quien edita.
          Semantics(
            liveRegion: true,
            child: switch ((suggesting, state.namesError)) {
              (true, _) => Padding(
                padding: const EdgeInsets.only(top: TokensSpacing.xs),
                child: Text(l10n.adminExerciseNamesSuggesting, style: muted),
              ),
              (false, final error?) => Padding(
                padding: const EdgeInsets.only(top: TokensSpacing.xs),
                child: Text(
                  errorMessage(context, error),
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.error,
                  ),
                ),
              ),
              _ => const SizedBox.shrink(),
            },
          ),
          for (final (controller, label, apply) in fields) ...[
            const SizedBox(height: TokensSpacing.m),
            TextField(
              controller: controller,
              enabled: !suggesting,
              maxLength: AdminExerciseDraft.nameMax,
              onChanged: (v) => onChanged((n) => apply(n, v)),
              decoration: InputDecoration(labelText: label),
            ),
          ],
        ],
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: TokensSpacing.xs),
    child: Text(text, style: context.textStyles.labelLarge),
  );
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    super.key,
    required this.index,
    required this.count,
    required this.controller,
    required this.onChanged,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  final int index;
  final int count;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: TokensSpacing.s),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: context.colors.secondaryContainer,
              child: Text(
                '${index + 1}',
                style: context.textStyles.labelMedium?.copyWith(
                  color: context.colors.onSecondaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(width: TokensSpacing.s),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              maxLength: AdminExerciseDraft.instructionMax,
              onChanged: onChanged,
              decoration: InputDecoration(
                labelText: l10n.adminExerciseStepHint(index + 1),
                counterText: '',
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.adminExerciseStepUp,
            onPressed: index == 0 ? null : onMoveUp,
            icon: const Icon(AppIcons.moveUp),
          ),
          IconButton(
            tooltip: l10n.adminExerciseStepDown,
            onPressed: index == count - 1 ? null : onMoveDown,
            icon: const Icon(AppIcons.moveDown),
          ),
          IconButton(
            tooltip: l10n.adminExerciseStepRemove,
            onPressed: onRemove,
            icon: const Icon(AppIcons.close),
          ),
        ],
      ),
    );
  }
}
