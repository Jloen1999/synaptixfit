import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/enums/profile/study_modality.dart';
import '../../../../domain/models/profile/academic_profile.dart';
import '../../../../domain/models/profile/catalog.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'profile_labels.dart';
import 'profile_layout.dart';
import 'profile_validators.dart';

/// Formulario del perfil académico. La carrera se elige del catálogo
/// ([onPickDegree]) o, si no aparece, se escribe a mano.
class AcademicProfileForm extends StatefulWidget {
  const AcademicProfileForm({
    super.key,
    required this.initial,
    required this.selectedDegree,
    required this.submitLabel,
    required this.saving,
    required this.onPickDegree,
    required this.onClearDegree,
    required this.onSubmit,
  });

  final AcademicProfile? initial;
  final Degree? selectedDegree;
  final String submitLabel;
  final bool saving;
  final VoidCallback onPickDegree;
  final VoidCallback onClearDegree;
  final ValueChanged<AcademicProfileDraft> onSubmit;

  @override
  State<AcademicProfileForm> createState() => _AcademicProfileFormState();
}

class _AcademicProfileFormState extends State<AcademicProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _university;
  late final TextEditingController _degree;
  late final TextEditingController _credits;
  late final TextEditingController _hours;
  late final TextEditingController _gpa;
  int? _semester;
  StudyModality? _modality;
  DateTime? _start;
  DateTime? _end;
  late bool _manual;
  bool _showErrors = false;

  static const _maxSemester = 12;

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _university = TextEditingController(text: p?.university ?? '');
    _degree = TextEditingController(text: p?.degree ?? '');
    _credits = TextEditingController(text: p?.semesterCredits?.toString());
    _hours = TextEditingController(text: p?.weeklyStudyHoursGoal?.toString());
    _gpa = TextEditingController(
      text: p?.targetGpa == null
          ? ''
          : NumberFormat.decimalPattern('es').format(p!.targetGpa),
    );
    _semester = p?.semester;
    _modality = p?.modality;
    _start = p?.classesStartDate;
    _end = p?.classesEndDate;
    _manual = false;
  }

  @override
  void dispose() {
    _university.dispose();
    _degree.dispose();
    _credits.dispose();
    _hours.dispose();
    _gpa.dispose();
    super.dispose();
  }

  bool get _datesInvalid =>
      _start != null && _end != null && _end!.isBefore(_start!);

  Future<void> _pickDate({required bool start}) async {
    final now = DateTime.now();
    final initial = (start ? _start : _end) ?? _start ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 3),
      locale: const Locale('es'),
    );
    if (picked == null) return;
    setState(() => start ? _start = picked : _end = picked);
  }

  void _submit() {
    setState(() => _showErrors = true);
    if (!_formKey.currentState!.validate() || _datesInvalid) return;
    String? text(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    // Con carrera del catálogo elegida, el bloc sustituye estos textos.
    widget.onSubmit(
      AcademicProfileDraft(
        university: text(_university),
        degree: text(_degree),
        semester: _semester,
        modality: _modality,
        semesterCredits: ProfileValidators.parseInt(_credits.text),
        weeklyStudyHoursGoal: ProfileValidators.parseInt(_hours.text),
        targetGpa: ProfileValidators.parseDecimal(_gpa.text),
        classesStartDate: _start,
        classesEndDate: _end,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final dateFormat = DateFormat.yMMMd('es');
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProfileFormSection(
            title: l10n.profileAcademicDegreeSection,
            subtitle: l10n.profileAcademicDegreeSectionHint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DegreeTile(
                  degree: widget.selectedDegree,
                  fallbackUniversity: widget.initial?.university,
                  fallbackDegree: widget.initial?.degree,
                  onPick: widget.onPickDegree,
                  onClear: widget.onClearDegree,
                ),
                if (widget.selectedDegree == null) ...[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => setState(() => _manual = !_manual),
                      child: Text(
                        _manual
                            ? l10n.profileAcademicHideManual
                            : l10n.profileAcademicManualEntry,
                      ),
                    ),
                  ),
                  if (_manual) ...[
                    AppTextField(
                      label: l10n.profileFieldUniversity,
                      controller: _university,
                      icon: Icons.account_balance_outlined,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: TokensSpacing.m),
                    AppTextField(
                      label: l10n.profileFieldDegree,
                      controller: _degree,
                      icon: Icons.school_outlined,
                    ),
                  ],
                ],
              ],
            ),
          ),
          ProfileFormSection(
            title: l10n.profileAcademicCourseSection,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _semester != null && _semester! <= _maxSemester
                      ? _semester
                      : null,
                  decoration: InputDecoration(
                    labelText: l10n.profileFieldSemester,
                    prefixIcon: const Icon(Icons.timeline_rounded),
                  ),
                  items: [
                    for (var s = 1; s <= _maxSemester; s++)
                      DropdownMenuItem(
                        value: s,
                        child: Text(l10n.profileSemesterValue(s)),
                      ),
                  ],
                  onChanged: (v) => setState(() => _semester = v),
                ),
                const SizedBox(height: TokensSpacing.m),
                Text(
                  l10n.profileFieldModality,
                  style: context.textStyles.labelLarge,
                ),
                const SizedBox(height: TokensSpacing.s),
                SegmentedButton<StudyModality>(
                  emptySelectionAllowed: true,
                  showSelectedIcon: false,
                  segments: [
                    for (final m in StudyModality.values)
                      ButtonSegment(value: m, label: Text(m.label(l10n))),
                  ],
                  selected: {?_modality},
                  onSelectionChanged: (s) =>
                      setState(() => _modality = s.isEmpty ? null : s.first),
                ),
                const SizedBox(height: TokensSpacing.m),
                AppTextField(
                  label: l10n.profileFieldCredits,
                  controller: _credits,
                  icon: Icons.stars_outlined,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      ProfileValidators.optionalInt(l10n, v, 1, 60),
                ),
              ],
            ),
          ),
          ProfileFormSection(
            title: l10n.profileAcademicGoalsSection,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: l10n.profileFieldWeeklyHours,
                  controller: _hours,
                  icon: Icons.schedule_rounded,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      ProfileValidators.optionalInt(l10n, v, 0, 80),
                ),
                const SizedBox(height: TokensSpacing.m),
                AppTextField(
                  label: l10n.profileFieldTargetGpa,
                  hint: l10n.profileFieldTargetGpaHint,
                  controller: _gpa,
                  icon: Icons.grade_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) =>
                      ProfileValidators.optionalDecimal(l10n, v, 0, 5),
                ),
              ],
            ),
          ),
          ProfileFormSection(
            title: l10n.profileAcademicDatesSection,
            subtitle: l10n.profileAcademicDatesHint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _DateButton(
                        label: l10n.profileFieldClassesStart,
                        value: _start == null
                            ? null
                            : dateFormat.format(_start!),
                        onTap: () => _pickDate(start: true),
                      ),
                    ),
                    const SizedBox(width: TokensSpacing.s),
                    Expanded(
                      child: _DateButton(
                        label: l10n.profileFieldClassesEnd,
                        value: _end == null ? null : dateFormat.format(_end!),
                        onTap: () => _pickDate(start: false),
                      ),
                    ),
                  ],
                ),
                if (_showErrors && _datesInvalid)
                  ProfileFieldError(l10n.profileErrorInvalidClassDates),
              ],
            ),
          ),
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

class _DegreeTile extends StatelessWidget {
  const _DegreeTile({
    required this.degree,
    required this.fallbackUniversity,
    required this.fallbackDegree,
    required this.onPick,
    required this.onClear,
  });

  final Degree? degree;
  final String? fallbackUniversity;
  final String? fallbackDegree;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final title = degree?.name ?? fallbackDegree;
    final subtitle = degree?.universityName ?? fallbackUniversity;
    return AppCard(
      onTap: onPick,
      child: Row(
        children: [
          Icon(Icons.school_rounded, color: context.palette.study),
          const SizedBox(width: TokensSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? l10n.profileAcademicPickDegree,
                  style: context.textStyles.titleSmall,
                ),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (degree != null)
            IconButton(
              tooltip: l10n.profileAcademicClearDegree,
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
            )
          else
            Icon(
              Icons.search_rounded,
              color: context.colors.onSurfaceVariant,
              semanticLabel: l10n.profileAcademicPickDegree,
            ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        alignment: Alignment.centerLeft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: context.textStyles.labelSmall),
          Text(
            value ?? context.localizations.profileDateNotSet,
            style: context.textStyles.bodyMedium,
          ),
        ],
      ),
    );
  }
}
