import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/profile/catalog.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../profile_routes.dart';
import '../../widgets/profile_layout.dart';
import '../bloc/subject_selector_bloc.dart';

/// Pantalla del selector de asignaturas del plan de estudios (`/profile/subjects`).
class SubjectSelectorPage extends StatelessWidget {
  const SubjectSelectorPage({super.key, required this.degreesPath});

  /// Ruta de «Mis carreras» para vincular una si no hay ninguna.
  final String degreesPath;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<SubjectSelectorBloc>()
            ..add(const SubjectSelectorEvent.started()),
      child: Builder(
        builder: (context) => Scaffold(
          appBar: AppPageBar.reading(
            title: Text(context.localizations.profileSubjectsTitle),
            actions: [
              // Atajo opcional: añadir las asignaturas desde la matrícula.
              IconButton(
                tooltip: context.localizations.profileEnrollmentEntry,
                icon: const Icon(Icons.upload_file_rounded),
                onPressed: () async {
                  await context.push<void>(ProfilePaths.enrollmentImport);
                  if (context.mounted) {
                    context.read<SubjectSelectorBloc>().add(
                      const SubjectSelectorEvent.started(),
                    );
                  }
                },
              ),
            ],
          ),
          body: SubjectSelectorView(
            onAdded: (count) => context.showSnack(
              context.localizations.profileSubjectsAdded(count),
            ),
            onLinkDegree: () async {
              await context.push<void>(degreesPath);
              if (context.mounted) {
                context.read<SubjectSelectorBloc>().add(
                  const SubjectSelectorEvent.started(),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

/// Selector reutilizable (pantalla propia y paso del onboarding). Necesita un
/// [SubjectSelectorBloc] en el contexto.
class SubjectSelectorView extends StatefulWidget {
  const SubjectSelectorView({
    super.key,
    required this.onAdded,
    this.onLinkDegree,
    this.secondaryAction,
    this.header,
  });

  final ValueChanged<int> onAdded;
  final VoidCallback? onLinkDegree;

  /// Acción extra en la barra inferior (p. ej. «Saltar» en el onboarding).
  final Widget? secondaryAction;
  final Widget? header;

  @override
  State<SubjectSelectorView> createState() => _SubjectSelectorViewState();
}

class _SubjectSelectorViewState extends State<SubjectSelectorView>
    with ErrorsMessageMixin {
  final _search = TextEditingController();
  Timer? _debounce;

  static const _courses = [1, 2, 3, 4, 5, 6];

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onQuery(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        context.read<SubjectSelectorBloc>().add(
          SubjectSelectorEvent.queryChanged(value),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<SubjectSelectorBloc, SubjectSelectorState>(
      listenWhen: (a, b) =>
          a.addedCount != b.addedCount || a.actionError != b.actionError,
      listener: (context, state) {
        if (state.actionError case final error?) {
          context.showSnack(errorMessage(context, error));
        } else if (state.addedCount case final count?) {
          widget.onAdded(count);
        }
      },
      builder: (context, state) {
        final bloc = context.read<SubjectSelectorBloc>();
        return Column(
          children: [
            ProfileConstrained(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  TokensSpacing.m,
                  TokensSpacing.s,
                  TokensSpacing.m,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ?widget.header,
                    TextField(
                      controller: _search,
                      onChanged: _onQuery,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        labelText: l10n.profileSubjectsSearch,
                      ),
                    ),
                    const SizedBox(height: TokensSpacing.s),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: l10n.profileSubjectsAllCourses,
                            selected: state.course == null,
                            onTap: () => bloc.add(
                              const SubjectSelectorEvent.courseChanged(null),
                            ),
                          ),
                          for (final c in _courses)
                            _FilterChip(
                              label: l10n.profileSubjectsCourse(c),
                              selected: state.course == c,
                              onTap: () => bloc.add(
                                SubjectSelectorEvent.courseChanged(c),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: l10n.profileSubjectsBothSemesters,
                            selected: state.semester == null,
                            onTap: () => bloc.add(
                              const SubjectSelectorEvent.semesterChanged(null),
                            ),
                          ),
                          for (final s in const [1, 2])
                            _FilterChip(
                              label: l10n.profileSubjectsSemester(s),
                              selected: state.semester == s,
                              onTap: () => bloc.add(
                                SubjectSelectorEvent.semesterChanged(s),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: _list(context, state)),
            _BottomBar(
              selected: state.selected.length,
              submitting: state.submitting,
              onSubmit: () => bloc.add(const SubjectSelectorEvent.submitted()),
              secondaryAction: widget.secondaryAction,
            ),
          ],
        );
      },
    );
  }

  Widget _list(BuildContext context, SubjectSelectorState state) {
    final l10n = context.localizations;
    final bloc = context.read<SubjectSelectorBloc>();
    switch (state.status) {
      case SubjectSelectorStatus.loading:
        return AppSkeletonGroup(
          child: ListView(
            padding: const EdgeInsets.all(TokensSpacing.m),
            children: [
              for (var i = 0; i < 6; i++)
                const ProfileConstrained(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: TokensSpacing.s),
                    child: AppSkeleton(height: 64),
                  ),
                ),
            ],
          ),
        );
      case SubjectSelectorStatus.failure:
        return AppErrorView(
          error: state.error!,
          onRetry: () => bloc.add(const SubjectSelectorEvent.started()),
        );
      case SubjectSelectorStatus.ready:
        final filtered =
            state.course != null ||
            state.semester != null ||
            state.query.trim().isNotEmpty;
        if (state.items.isEmpty) {
          return filtered
              ? AppEmptyState(
                  icon: Icons.filter_alt_off_rounded,
                  title: l10n.profileSubjectsNoMatches,
                )
              : AppEmptyState(
                  icon: Icons.menu_book_rounded,
                  title: l10n.profileSubjectsEmptyTitle,
                  message: l10n.profileSubjectsEmptyMessage,
                  action: widget.onLinkDegree == null
                      ? null
                      : AppSecondaryButton(
                          label: l10n.profileDegreesLinkAction,
                          onPressed: widget.onLinkDegree,
                        ),
                );
        }
        return NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.extentAfter < 300) {
              bloc.add(const SubjectSelectorEvent.moreRequested());
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: TokensSpacing.s),
            itemCount: state.items.length + (state.hasMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == state.items.length) {
                return const Padding(
                  padding: EdgeInsets.all(TokensSpacing.m),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final subject = state.items[i];
              return ProfileConstrained(
                child: _SubjectTile(
                  subject: subject,
                  selected: state.selected.contains(subject.id),
                  onToggle: () =>
                      bloc.add(SubjectSelectorEvent.toggled(subject.id)),
                ),
              );
            },
          ),
        );
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: TokensSpacing.s),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _SubjectTile extends StatelessWidget {
  const _SubjectTile({
    required this.subject,
    required this.selected,
    required this.onToggle,
  });

  final CatalogSubject subject;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final credits = subject.credits;
    final details = [
      if (subject.course != null) l10n.profileSubjectsCourse(subject.course!),
      if (subject.semester != null)
        l10n.profileSubjectsSemester(subject.semester!),
      if (credits != null)
        l10n.profileSubjectsCredits(
          NumberFormat.decimalPattern().format(credits),
        ),
      ?subject.character,
    ].join(' · ');
    if (subject.alreadyAdded) {
      return ListTile(
        leading: Icon(
          Icons.check_circle_rounded,
          color: context.palette.success,
        ),
        title: Text(subject.name),
        subtitle: Text(
          details.isEmpty
              ? l10n.profileSubjectsAlreadyAdded
              : '$details\n${l10n.profileSubjectsAlreadyAdded}',
        ),
        enabled: false,
      );
    }
    return AppFocusOutline(
      child: CheckboxListTile(
        value: selected,
        onChanged: (_) => onToggle(),
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(subject.name),
        subtitle: details.isEmpty ? null : Text(details),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.selected,
    required this.submitting,
    required this.onSubmit,
    required this.secondaryAction,
  });

  final int selected;
  final bool submitting;
  final VoidCallback onSubmit;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Material(
      color: context.colors.surface,
      child: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: context.colors.outlineVariant),
            ),
          ),
          child: ProfileConstrained(
            child: Padding(
              padding: const EdgeInsets.all(TokensSpacing.m),
              child: Row(
                children: [
                  if (secondaryAction != null) ...[
                    secondaryAction!,
                    const SizedBox(width: TokensSpacing.s),
                  ],
                  Expanded(
                    child: AppPrimaryButton(
                      label: l10n.profileSubjectsAddAction(selected),
                      loading: submitting,
                      onPressed: selected == 0 ? null : onSubmit,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
