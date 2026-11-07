import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/enums/profile/activity_level.dart';
import '../../../../domain/enums/profile/fitness_goal.dart';
import '../../../../domain/enums/profile/sex.dart';
import '../../../../domain/models/profile/wellness_history.dart';
import '../../../../domain/models/profile/wellness_profile.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'profile_labels.dart';
import 'profile_layout.dart';
import 'profile_validators.dart';

/// Formulario del perfil físico. No conoce el bloc: recibe el estado y avisa
/// con callbacks (lo usan el onboarding y la pantalla de edición).
class WellnessProfileForm extends StatefulWidget {
  const WellnessProfileForm({
    super.key,
    required this.initial,
    required this.submitLabel,
    required this.saving,
    required this.suggesting,
    required this.suggestions,
    required this.onSubmit,
    required this.onSuggest,
    this.compact = false,
  });

  /// Onboarding corto: solo lo imprescindible (edad, sexo, medidas y
  /// objetivo); actividad, días y material quedan en «Más opciones» y, si no
  /// se abren, los decide el servidor.
  final bool compact;

  final WellnessProfile? initial;
  final String submitLabel;
  final bool saving;
  final bool suggesting;
  final GoalSuggestions? suggestions;
  final ValueChanged<WellnessProfileDraft> onSubmit;
  final void Function(int? age, Sex? sex, ActivityLevel? activityLevel)
  onSuggest;

  @override
  State<WellnessProfileForm> createState() => _WellnessProfileFormState();
}

class _WellnessProfileFormState extends State<WellnessProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weight;
  late final TextEditingController _height;
  Sex? _sex;
  ActivityLevel? _activity;
  FitnessGoal? _goal;
  late Set<int> _days;
  late Set<String> _equipment;
  late double _minutes;
  bool _showErrors = false;
  bool _showMore = false;

  bool get _extended => !widget.compact || _showMore;

  static const _minMinutes = 10.0;
  static const _maxMinutes = 180.0;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    final decimal = NumberFormat.decimalPattern();
    _weight = TextEditingController(
      text: p?.weightKg == null ? '' : decimal.format(p!.weightKg),
    );
    _height = TextEditingController(
      text: p?.heightCm == null ? '' : decimal.format(p!.heightCm),
    );
    _sex = p?.sex;
    _activity = p?.activityLevel;
    _goal = p?.primaryGoal;
    _days = {...?p?.availableDays};
    if (_days.isEmpty) _days = {1, 3, 5};
    _equipment = {...?p?.equipment};
    _minutes = (p?.minutesPerSession ?? 45).toDouble().clamp(
      _minMinutes,
      _maxMinutes,
    );
    _weight.addListener(_refresh);
    _height.addListener(_refresh);
  }

  @override
  void dispose() {
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _submit() {
    setState(() => _showErrors = true);
    final valid = _formKey.currentState!.validate();
    if (!valid ||
        _sex == null ||
        _goal == null ||
        (!widget.compact && _activity == null) ||
        (_extended && _days.isEmpty)) {
      return;
    }
    widget.onSubmit(
      WellnessProfileDraft(
        sex: _sex!,
        weightKg: ProfileValidators.parseDecimal(_weight.text)!,
        heightCm: ProfileValidators.parseDecimal(_height.text)!,
        activityLevel: _extended ? _activity : null,
        primaryGoal: _goal!,
        equipment: _equipment.toList(),
        availableDays: _extended ? (_days.toList()..sort()) : null,
        minutesPerSession: _extended ? _minutes.round() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileFormSection(
            title: l10n.profileWellnessAboutYou,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.profileFieldSex,
                  style: context.textStyles.labelLarge,
                ),
                const SizedBox(height: TokensSpacing.s),
                Wrap(
                  spacing: TokensSpacing.s,
                  runSpacing: TokensSpacing.s,
                  children: [
                    for (final sex in Sex.values)
                      ChoiceChip(
                        label: Text(sex.label(l10n)),
                        selected: _sex == sex,
                        onSelected: (_) => setState(() => _sex = sex),
                      ),
                  ],
                ),
                if (_showErrors && _sex == null)
                  ProfileFieldError(l10n.validationRequired),
              ],
            ),
          ),
          ProfileFormSection(
            title: l10n.profileWellnessMeasures,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: l10n.profileFieldWeight,
                        controller: _weight,
                        icon: Icons.monitor_weight_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) =>
                            ProfileValidators.requiredDecimal(l10n, v, 30, 250),
                      ),
                    ),
                    const SizedBox(width: TokensSpacing.m),
                    Expanded(
                      child: AppTextField(
                        label: l10n.profileFieldHeight,
                        controller: _height,
                        icon: Icons.height_rounded,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) => ProfileValidators.requiredDecimal(
                          l10n,
                          v,
                          120,
                          230,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TokensSpacing.s),
                _BmiPreview(
                  weightKg: ProfileValidators.parseDecimal(_weight.text),
                  heightCm: ProfileValidators.parseDecimal(_height.text),
                ),
              ],
            ),
          ),
          if (!widget.compact)
            ProfileFormSection(
              title: l10n.profileFieldActivityLevel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  RadioGroup<ActivityLevel>(
                    groupValue: _activity,
                    onChanged: (v) => setState(() => _activity = v),
                    child: Column(
                      children: [
                        for (final level in ActivityLevel.values)
                          AppFocusOutline(
                            child: RadioListTile<ActivityLevel>(
                              value: level,
                              contentPadding: EdgeInsets.zero,
                              title: Text(level.label(l10n)),
                              subtitle: Text(level.hint(l10n)),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_showErrors && _activity == null && !widget.compact)
                    ProfileFieldError(l10n.validationRequired),
                ],
              ),
            ),
          ProfileFormSection(
            title: l10n.profileFieldGoal,
            trailing: TextButton.icon(
              onPressed: widget.suggesting
                  ? null
                  // La edad la pone el servidor con la fecha de nacimiento.
                  : () => widget.onSuggest(null, _sex, _activity),
              icon: widget.suggesting
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lightbulb_outline_rounded),
              label: Text(l10n.profileGoalSuggestAction),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.suggestions case final suggestions?
                    when suggestions.suggestions.isNotEmpty) ...[
                  _GoalSuggestionsPanel(
                    suggestions: suggestions,
                    selected: _goal,
                    onSelected: (goal) => setState(() => _goal = goal),
                  ),
                  const SizedBox(height: TokensSpacing.m),
                ],
                _GoalGrid(
                  selected: _goal,
                  onSelected: (goal) => setState(() => _goal = goal),
                ),
                if (_showErrors && _goal == null)
                  ProfileFieldError(l10n.validationRequired),
              ],
            ),
          ),
          if (!widget.compact) ...[
            ProfileFormSection(
              title: l10n.profileFieldAvailableDays,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: TokensSpacing.s,
                    runSpacing: TokensSpacing.s,
                    children: [
                      for (var day = 1; day <= 7; day++)
                        FilterChip(
                          // Se lee el nombre completo del día; el chip conserva
                          // su estado, su acción y su foco.
                          label: Semantics(
                            label: ProfileWeekdays.long(l10n, day),
                            excludeSemantics: true,
                            child: Text(ProfileWeekdays.short(l10n, day)),
                          ),
                          showCheckmark: false,
                          selected: _days.contains(day),
                          onSelected: (on) => setState(
                            () => on ? _days.add(day) : _days.remove(day),
                          ),
                        ),
                    ],
                  ),
                  if (_showErrors && _days.isEmpty)
                    ProfileFieldError(l10n.profileValidationDays),
                  const SizedBox(height: TokensSpacing.m),
                  Text(
                    l10n.profileMinutesPerSession(_minutes.round()),
                    style: context.textStyles.labelLarge,
                  ),
                  Slider(
                    value: _minutes,
                    min: _minMinutes,
                    max: _maxMinutes,
                    divisions: ((_maxMinutes - _minMinutes) / 5).round(),
                    label: l10n.profileMinutesShort(_minutes.round()),
                    onChanged: (v) => setState(() => _minutes = v),
                  ),
                ],
              ),
            ),
            ProfileFormSection(
              title: l10n.profileFieldEquipment,
              subtitle: l10n.profileFieldEquipmentHint,
              child: Wrap(
                spacing: TokensSpacing.s,
                runSpacing: TokensSpacing.s,
                children: [
                  for (final item in ProfileEquipment.values)
                    FilterChip(
                      avatar: Icon(item.icon, size: 18),
                      label: Text(item.label(l10n)),
                      selected: _equipment.contains(item.value),
                      onSelected: (on) => setState(
                        () => on
                            ? _equipment.add(item.value)
                            : _equipment.remove(item.value),
                      ),
                    ),
                ],
              ),
            ),
          ],
          // Onboarding corto: lo opcional va después del botón que lo abre, para
          // que lo que aparece quede donde el usuario está mirando.
          if (widget.compact) ...[
            MergeSemantics(
              child: Semantics(
                expanded: _showMore,
                child: TextButton.icon(
                  onPressed: () => setState(() => _showMore = !_showMore),
                  icon: Icon(
                    _showMore
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                  ),
                  label: Text(
                    _showMore
                        ? l10n.profileWellnessLessOptions
                        : l10n.profileWellnessMoreOptions,
                  ),
                ),
              ),
            ),
            Text(
              l10n.profileWellnessMoreOptionsHint,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: TokensSpacing.m),
            if (_showMore) ...[
              ProfileFormSection(
                title: l10n.profileFieldActivityLevel,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RadioGroup<ActivityLevel>(
                      groupValue: _activity,
                      onChanged: (v) => setState(() => _activity = v),
                      child: Column(
                        children: [
                          for (final level in ActivityLevel.values)
                            AppFocusOutline(
                              child: RadioListTile<ActivityLevel>(
                                value: level,
                                contentPadding: EdgeInsets.zero,
                                title: Text(level.label(l10n)),
                                subtitle: Text(level.hint(l10n)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (_showErrors && _activity == null && !widget.compact)
                      ProfileFieldError(l10n.validationRequired),
                  ],
                ),
              ),
              ProfileFormSection(
                title: l10n.profileFieldAvailableDays,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: TokensSpacing.s,
                      runSpacing: TokensSpacing.s,
                      children: [
                        for (var day = 1; day <= 7; day++)
                          FilterChip(
                            // Se lee el nombre completo del día; el chip conserva
                            // su estado, su acción y su foco.
                            label: Semantics(
                              label: ProfileWeekdays.long(l10n, day),
                              excludeSemantics: true,
                              child: Text(ProfileWeekdays.short(l10n, day)),
                            ),
                            showCheckmark: false,
                            selected: _days.contains(day),
                            onSelected: (on) => setState(
                              () => on ? _days.add(day) : _days.remove(day),
                            ),
                          ),
                      ],
                    ),
                    if (_showErrors && _days.isEmpty)
                      ProfileFieldError(l10n.profileValidationDays),
                    const SizedBox(height: TokensSpacing.m),
                    Text(
                      l10n.profileMinutesPerSession(_minutes.round()),
                      style: context.textStyles.labelLarge,
                    ),
                    Slider(
                      value: _minutes,
                      min: _minMinutes,
                      max: _maxMinutes,
                      divisions: ((_maxMinutes - _minMinutes) / 5).round(),
                      label: l10n.profileMinutesShort(_minutes.round()),
                      onChanged: (v) => setState(() => _minutes = v),
                    ),
                  ],
                ),
              ),
              ProfileFormSection(
                title: l10n.profileFieldEquipment,
                subtitle: l10n.profileFieldEquipmentHint,
                child: Wrap(
                  spacing: TokensSpacing.s,
                  runSpacing: TokensSpacing.s,
                  children: [
                    for (final item in ProfileEquipment.values)
                      FilterChip(
                        avatar: Icon(item.icon, size: 18),
                        label: Text(item.label(l10n)),
                        selected: _equipment.contains(item.value),
                        onSelected: (on) => setState(
                          () => on
                              ? _equipment.add(item.value)
                              : _equipment.remove(item.value),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
          AppPrimaryButton(
            label: widget.submitLabel,
            loading: widget.saving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

/// Vista previa del IMC mientras se escribe. El valor que se guarda lo calcula el backend.
class _BmiPreview extends StatelessWidget {
  const _BmiPreview({required this.weightKg, required this.heightCm});

  final double? weightKg;
  final double? heightCm;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final w = weightKg;
    final h = heightCm;
    final bmi = w == null || h == null || w <= 0 || h <= 0
        ? null
        : w / ((h / 100) * (h / 100));
    final category = switch (bmi) {
      null => null,
      < 18.5 => l10n.profileBmiUnderweight,
      < 25 => l10n.profileBmiNormal,
      < 30 => l10n.profileBmiOverweight,
      _ => l10n.profileBmiObesity,
    };
    return AppCard(
      color: context.colors.surfaceContainerLow,
      child: Row(
        children: [
          Icon(Icons.speed_rounded, color: context.palette.sessions),
          const SizedBox(width: TokensSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bmi == null
                      ? l10n.profileBmiPreviewEmpty
                      : l10n.profileBmiPreview(
                          NumberFormat('0.0').format(bmi),
                          category!,
                        ),
                  style: context.textStyles.titleSmall,
                ),
                Text(
                  l10n.profileBmiPreviewHint,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalGrid extends StatelessWidget {
  const _GoalGrid({required this.selected, required this.onSelected});

  final FitnessGoal? selected;
  final ValueChanged<FitnessGoal> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 480 ? 3 : 2;
        final width =
            (constraints.maxWidth - TokensSpacing.s * (columns - 1)) / columns;
        return Wrap(
          spacing: TokensSpacing.s,
          runSpacing: TokensSpacing.s,
          children: [
            for (final goal in FitnessGoal.values)
              SizedBox(
                width: width,
                child: _GoalTile(
                  goal: goal,
                  label: goal.label(l10n),
                  selected: selected == goal,
                  onTap: () => onSelected(goal),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({
    required this.goal,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final FitnessGoal goal;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? colors.secondaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TokensRadius.m),
          side: BorderSide(
            color: selected ? colors.secondary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: AppFocusOutline(
          borderRadius: BorderRadius.circular(TokensRadius.m),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(TokensRadius.m),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.all(TokensSpacing.s),
                child: Row(
                  children: [
                    Icon(
                      goal.icon,
                      color: selected
                          ? colors.onSecondaryContainer
                          : colors.secondary,
                    ),
                    const SizedBox(width: TokensSpacing.s),
                    Expanded(
                      child: Text(
                        label,
                        style: context.textStyles.labelLarge?.copyWith(
                          color: selected
                              ? colors.onSecondaryContainer
                              : colors.onSurface,
                        ),
                      ),
                    ),
                    if (selected)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: colors.onSecondaryContainer,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalSuggestionsPanel extends StatelessWidget {
  const _GoalSuggestionsPanel({
    required this.suggestions,
    required this.selected,
    required this.onSelected,
  });

  final GoalSuggestions suggestions;
  final FitnessGoal? selected;
  final ValueChanged<FitnessGoal> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return AppCard(
      color: context.colors.tertiaryContainer.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: context.colors.tertiary,
              ),
              const SizedBox(width: TokensSpacing.xs),
              Expanded(
                child: Text(
                  l10n.profileGoalSuggestionsFromAi,
                  style: context.textStyles.labelLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
          for (final suggestion in suggestions.suggestions)
            AppFocusOutline(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(suggestion.goal.icon),
                title: Text(suggestion.label ?? suggestion.goal.label(l10n)),
                subtitle: suggestion.reason == null
                    ? null
                    : Text(suggestion.reason!),
                trailing: selected == suggestion.goal
                    ? Icon(
                        Icons.check_circle_rounded,
                        color: context.colors.secondary,
                      )
                    : TextButton(
                        onPressed: () => onSelected(suggestion.goal),
                        child: Text(l10n.profileGoalUseSuggestion),
                      ),
                onTap: () => onSelected(suggestion.goal),
              ),
            ),
        ],
      ),
    );
  }
}
