import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/admin/admin_exercise_difficulty.dart';
import '../../../../../domain/enums/admin/admin_exercise_modality.dart';
import '../../../../../domain/models/admin/admin_exercise.dart';
import '../../../../../domain/models/admin/admin_queries.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../admin_routes.dart';
import '../../widgets/admin_dialogs.dart';
import '../../widgets/admin_labels.dart';
import '../../widgets/admin_status.dart';
import '../../widgets/admin_widgets.dart';
import '../bloc/admin_exercises_bloc.dart';

/// Pestaña Ejercicios del panel.
class AdminExercisesTab extends StatelessWidget {
  const AdminExercisesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<AdminExercisesBloc>()..add(const AdminExercisesEvent.started()),
      child: const _AdminExercisesView(),
    );
  }
}

class _AdminExercisesView extends StatefulWidget {
  const _AdminExercisesView();

  @override
  State<_AdminExercisesView> createState() => _AdminExercisesViewState();
}

class _AdminExercisesViewState extends State<_AdminExercisesView>
    with ErrorsMessageMixin {
  final _search = TextEditingController();
  Timer? _debounce;

  AdminExercisesBloc get _bloc => context.read<AdminExercisesBloc>();

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _setQuery(AdminExerciseQuery query) =>
      _bloc.add(AdminExercisesEvent.queryChanged(query));

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _setQuery(_bloc.state.query.copyWith(text: text));
    });
  }

  Future<void> _openForm([AdminExercise? exercise]) async {
    final saved = await context.push<bool>(
      exercise == null
          ? AdminPaths.exerciseNew
          : AdminPaths.exerciseEdit(exercise.id),
    );
    if (saved == true && mounted) {
      _bloc.add(const AdminExercisesEvent.refreshed());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<AdminExercisesBloc, AdminExercisesState>(
      listenWhen: (a, b) => a.effect != b.effect && b.effect != null,
      listener: (context, state) => context.showSnack(switch (state.effect!) {
        AdminExercisesActiveChangedEffect(:final active) =>
          active
              ? l10n.adminExercisesActivated
              : l10n.adminExercisesDeactivated,
        AdminExercisesDeletedEffect() => l10n.adminExercisesDeleted,
        AdminExercisesDeactivatedInsteadEffect() =>
          l10n.adminExercisesDeactivatedInstead,
        AdminExercisesFailureEffect(:final error) => errorMessage(
          context,
          error,
        ),
      }),
      builder: (context, state) {
        final query = state.query;
        return AdminContentWidth(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TokensSpacing.m,
                  TokensSpacing.m,
                  TokensSpacing.m,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          labelText: l10n.adminExercisesSearchHint,
                          prefixIcon: const Icon(Icons.search_rounded),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: TokensSpacing.s),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                      ),
                      onPressed: _openForm,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.adminExercisesNew),
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: TokensSpacing.m,
                  vertical: TokensSpacing.s,
                ),
                child: Row(
                  children: [
                    _EnumMenu<AdminExerciseDifficulty>(
                      label: l10n.adminFieldDifficulty,
                      value: query.difficulty,
                      values: AdminExerciseDifficulty.values,
                      itemLabel: (v) => v.label(l10n),
                      onChanged: (v) => _setQuery(
                        AdminExerciseQuery(
                          text: query.text,
                          difficulty: v,
                          modality: query.modality,
                          includeInactive: query.includeInactive,
                        ),
                      ),
                    ),
                    const SizedBox(width: TokensSpacing.s),
                    _EnumMenu<AdminExerciseModality>(
                      label: l10n.adminFieldModalityExercise,
                      value: query.modality,
                      values: AdminExerciseModality.values,
                      itemLabel: (v) => v.label(l10n),
                      onChanged: (v) => _setQuery(
                        AdminExerciseQuery(
                          text: query.text,
                          difficulty: query.difficulty,
                          modality: v,
                          includeInactive: query.includeInactive,
                        ),
                      ),
                    ),
                    const SizedBox(width: TokensSpacing.s),
                    FilterChip(
                      label: Text(l10n.adminExercisesIncludeInactive),
                      selected: query.includeInactive,
                      onSelected: (v) =>
                          _setQuery(query.copyWith(includeInactive: v)),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildList(context, state)),
              if (state.exercises != null && state.exercises!.totalItems > 0)
                AdminPaginationBar(
                  page: state.exercises!.page,
                  totalPages: state.exercises!.totalPages,
                  totalItems: state.exercises!.totalItems,
                  onPageSelected: (page) =>
                      _bloc.add(AdminExercisesEvent.pageRequested(page)),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(BuildContext context, AdminExercisesState state) {
    final l10n = context.localizations;
    if (state.status == AdminStatus.failure) {
      return AppErrorView(
        error: state.error!,
        onRetry: () => _bloc.add(const AdminExercisesEvent.refreshed()),
      );
    }
    final page = state.exercises;
    if (page == null) return const AppSkeletonList(count: 6);
    if (page.items.isEmpty) {
      return AppEmptyState(
        icon: Icons.fitness_center_outlined,
        title: l10n.adminExercisesEmptyTitle,
        message: l10n.adminExercisesEmptyMessage,
        action: AppPrimaryButton(
          label: l10n.adminExercisesNew,
          icon: Icons.add_rounded,
          onPressed: _openForm,
        ),
      );
    }
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            _bloc.add(const AdminExercisesEvent.refreshed());
            await _bloc.stream.firstWhere((s) => !s.status.isLoading);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(TokensSpacing.m),
            itemCount: page.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: TokensSpacing.s),
            itemBuilder: (context, index) {
              final exercise = page.items[index];
              return _ExerciseTile(
                exercise: exercise,
                busy: state.busyId == exercise.id,
                onEdit: () => _openForm(exercise),
              );
            },
          ),
        ),
        if (state.status.isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }
}

/// Selector compacto de un enum con opción «Todas».
class _EnumMenu<T extends Enum> extends StatelessWidget {
  const _EnumMenu({
    required this.label,
    required this.value,
    required this.values,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final List<T> values;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    // El índice -1 representa «Todas» (un valor nulo cerraría el menú sin aviso).
    return PopupMenuButton<int>(
      tooltip: label,
      onSelected: (index) => onChanged(index < 0 ? null : values[index]),
      itemBuilder: (_) => [
        PopupMenuItem<int>(value: -1, child: Text(l10n.adminFilterAll)),
        for (var i = 0; i < values.length; i++)
          PopupMenuItem<int>(value: i, child: Text(itemLabel(values[i]))),
      ],
      child: Chip(
        avatar: const Icon(Icons.arrow_drop_down_rounded, size: 18),
        label: Text(value == null ? label : '$label: ${itemLabel(value as T)}'),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
    required this.exercise,
    required this.busy,
    required this.onEdit,
  });

  final AdminExercise exercise;
  final bool busy;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final colors = context.colors;
    final bloc = context.read<AdminExercisesBloc>();
    final preview = exercise.previewUrl ?? exercise.gifUrl;
    return AppCard(
      onTap: onEdit,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(TokensRadius.m),
            child: Container(
              width: 56,
              height: 56,
              color: colors.secondaryContainer,
              child: preview == null || preview.isEmpty
                  ? Icon(
                      Icons.fitness_center_rounded,
                      color: colors.onSecondaryContainer,
                    )
                  : ExcludeSemantics(
                      child: CachedNetworkImage(
                        imageUrl: preview,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Icon(
                          Icons.fitness_center_rounded,
                          color: colors.onSecondaryContainer,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: TokensSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  style: context.textStyles.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: TokensSpacing.xs),
                Wrap(
                  spacing: TokensSpacing.xs,
                  runSpacing: TokensSpacing.xs,
                  children: [
                    AppPill(
                      label: exercise.modality.label(l10n),
                      color: colors.secondary,
                    ),
                    AppPill(
                      label: exercise.difficulty.label(l10n),
                      color: colors.primary,
                    ),
                    AppPill(
                      label: l10n.adminExercisesMet(
                        AdminFormat.decimal(exercise.met),
                      ),
                      color: context.palette.calories,
                    ),
                    if (!exercise.active)
                      AppPill(
                        label: l10n.adminTagInactive,
                        color: colors.error,
                        icon: Icons.pause_circle_outline_rounded,
                      ),
                  ],
                ),
              ],
            ),
          ),
          Semantics(
            label: l10n.adminExerciseActiveToggle(exercise.name),
            child: Switch(
              value: exercise.active,
              onChanged: busy
                  ? null
                  : (_) =>
                        bloc.add(AdminExercisesEvent.activeToggled(exercise)),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: l10n.adminMoreActions,
            enabled: !busy,
            onSelected: (value) async {
              if (value == 'edit') return onEdit();
              final ok = await showAdminConfirmDialog(
                context,
                title: l10n.adminExercisesDeleteTitle,
                message: l10n.adminExercisesDeleteMessage(exercise.name),
                confirmLabel: l10n.commonDelete,
                destructive: true,
              );
              if (ok) bloc.add(AdminExercisesEvent.deleteRequested(exercise));
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(l10n.commonEdit),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(
                    Icons.delete_outline_rounded,
                    color: colors.error,
                  ),
                  title: Text(l10n.commonDelete),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
