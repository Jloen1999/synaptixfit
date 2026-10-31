import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/subject_priority.dart';
import '../../../../../domain/models/academic/subject.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_visuals.dart';
import '../../widgets/academic_widgets.dart';
import '../bloc/subject_form_bloc.dart';

/// Alta manual o edición de una asignatura.
class SubjectFormPage extends StatelessWidget {
  const SubjectFormPage({super.key, this.subjectId});

  final String? subjectId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<SubjectFormBloc>()
          ..add(SubjectFormEvent.started(subjectId: subjectId)),
    child: _SubjectFormView(isNew: subjectId == null),
  );
}

class _SubjectFormView extends StatefulWidget {
  const _SubjectFormView({required this.isNew});

  final bool isNew;

  @override
  State<_SubjectFormView> createState() => _SubjectFormViewState();
}

class _SubjectFormViewState extends State<_SubjectFormView>
    with ErrorsMessageMixin {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _code = TextEditingController();
  final _teacher = TextEditingController();
  final _description = TextEditingController();
  final _credits = TextEditingController();
  int _difficulty = 3;
  SubjectPriority _priority = SubjectPriority.medium;
  DateTime? _nextAssessment;
  int? _course;
  int? _semester;
  bool _filled = false;

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _teacher.dispose();
    _description.dispose();
    _credits.dispose();
    super.dispose();
  }

  void _fill(SubjectFormState state) {
    final subject = state.subject;
    if (_filled || subject == null) return;
    _filled = true;
    setState(() {
      _name.text = subject.name;
      _code.text = subject.code ?? '';
      _teacher.text = subject.teacher ?? '';
      _description.text = subject.description ?? '';
      _credits.text = subject.credits > 0 ? '${subject.credits}' : '';
      _difficulty = subject.perceivedDifficulty.clamp(1, 5);
      _priority = subject.priority;
      _nextAssessment = subject.nextAssessmentAt;
      _course = state.semester?.course;
      _semester = state.semester?.semester;
    });
  }

  String? _trimmed(TextEditingController c) {
    final value = c.text.trim();
    return value.isEmpty ? null : value;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final hasSemester = _course != null && _semester != null;
    context.read<SubjectFormBloc>().add(
      SubjectFormEvent.submitted(
        input: SubjectInput(
          name: _name.text.trim(),
          code: _trimmed(_code),
          teacher: _trimmed(_teacher),
          description: _trimmed(_description),
          credits: int.tryParse(_credits.text.trim()),
          perceivedDifficulty: _difficulty,
          priority: _priority,
          nextAssessmentAt: _nextAssessment,
        ),
        course: hasSemester ? _course : null,
        semester: hasSemester ? _semester : null,
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _nextAssessment ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) setState(() => _nextAssessment = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<SubjectFormBloc, SubjectFormState>(
      listener: (context, state) {
        _fill(state);
        final saved = state.savedSubjectId;
        if (saved != null) {
          context.showSnack(l10n.commonSaved);
          if (widget.isNew) {
            context.pushReplacement(AcademicPaths.subject(saved));
          } else {
            context.pop(true);
          }
        } else if (state.saveError != null) {
          context.showSnack(errorMessage(context, state.saveError!));
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppPageBar.reading(
            title: Text(
              widget.isNew
                  ? l10n.academicSubjectNewTitle
                  : l10n.academicSubjectEditTitle,
            ),
          ),
          body: switch (state) {
            SubjectFormState(loading: true) => const AppLoadingView(),
            SubjectFormState(:final loadError?) => AppErrorView(
              error: loadError,
              onRetry: () => context.pop(),
            ),
            _ => AcademicBody(
              maxWidth: TokensLayout.readingMaxWidth,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(TokensSpacing.m),
                  children: [
                    AppTextField(
                      label: l10n.academicSubjectName,
                      controller: _name,
                      icon: Icons.school_outlined,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v ?? '').trim().length < 2
                          ? l10n.validationTooShort
                          : null,
                    ),
                    const SizedBox(height: TokensSpacing.m),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: l10n.academicSubjectCode,
                            controller: _code,
                            icon: Icons.tag_rounded,
                          ),
                        ),
                        const SizedBox(width: TokensSpacing.m),
                        Expanded(
                          child: TextFormField(
                            controller: _credits,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              labelText: l10n.academicSubjectCredits,
                              prefixIcon: const Icon(Icons.stars_outlined),
                            ),
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if ((v ?? '').isEmpty) return null;
                              return n == null || n < 1 || n > 30
                                  ? l10n.academicSubjectCreditsInvalid
                                  : null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TokensSpacing.m),
                    AppTextField(
                      label: l10n.academicSubjectTeacher,
                      controller: _teacher,
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: TokensSpacing.l),
                    Text(
                      l10n.academicSubjectDifficulty(_difficulty),
                      style: context.textStyles.labelLarge,
                    ),
                    Slider(
                      value: _difficulty.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: '$_difficulty',
                      onChanged: (v) => setState(() => _difficulty = v.round()),
                    ),
                    const SizedBox(height: TokensSpacing.s),
                    Text(
                      l10n.academicSubjectPriority,
                      style: context.textStyles.labelLarge,
                    ),
                    const SizedBox(height: TokensSpacing.s),
                    SegmentedButton<SubjectPriority>(
                      segments: [
                        for (final p in SubjectPriority.values)
                          ButtonSegment(
                            value: p,
                            label: Text(context.priorityLabel(p)),
                          ),
                      ],
                      selected: {_priority},
                      onSelectionChanged: (s) =>
                          setState(() => _priority = s.first),
                    ),
                    const SizedBox(height: TokensSpacing.l),
                    Card(
                      child: AppFocusOutline(
                        child: ListTile(
                          leading: const Icon(Icons.event_rounded),
                          title: Text(l10n.academicSubjectNextAssessment),
                          subtitle: Text(
                            _nextAssessment == null
                                ? l10n.academicSubjectNoDate
                                : longDate(_nextAssessment!),
                          ),
                          trailing: _nextAssessment == null
                              ? null
                              : IconButton(
                                  tooltip: l10n.academicSubjectClearDate,
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () =>
                                      setState(() => _nextAssessment = null),
                                ),
                          onTap: _pickDate,
                        ),
                      ),
                    ),
                    const SizedBox(height: TokensSpacing.m),
                    Text(
                      l10n.academicSubjectCourseSemester,
                      style: context.textStyles.labelLarge,
                    ),
                    const SizedBox(height: TokensSpacing.s),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            initialValue: _course,
                            decoration: InputDecoration(
                              labelText: l10n.academicSubjectCourse,
                            ),
                            items: [
                              DropdownMenuItem(
                                child: Text(l10n.academicSubjectNone),
                              ),
                              for (var c = 1; c <= 6; c++)
                                DropdownMenuItem(
                                  value: c,
                                  child: Text(l10n.academicCourseLabel(c)),
                                ),
                            ],
                            onChanged: (v) => setState(() => _course = v),
                          ),
                        ),
                        const SizedBox(width: TokensSpacing.m),
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            initialValue: _semester,
                            decoration: InputDecoration(
                              labelText: l10n.academicSubjectSemester,
                            ),
                            items: [
                              DropdownMenuItem(
                                child: Text(l10n.academicSubjectNone),
                              ),
                              for (var s = 1; s <= 2; s++)
                                DropdownMenuItem(
                                  value: s,
                                  child: Text(l10n.academicSemesterLabel(s)),
                                ),
                            ],
                            onChanged: (v) => setState(() => _semester = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TokensSpacing.m),
                    AppTextField(
                      label: l10n.academicSubjectDescription,
                      controller: _description,
                      maxLines: 4,
                    ),
                    const SizedBox(height: TokensSpacing.l),
                    AppPrimaryButton(
                      label: l10n.commonSave,
                      loading: state.saving,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          },
        );
      },
    );
  }
}
