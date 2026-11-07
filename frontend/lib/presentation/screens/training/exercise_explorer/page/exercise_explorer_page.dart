import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/training_enums.dart';
import '../../../../../domain/models/training/exercise.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../training_routes.dart';
import '../../widgets/exercise_thumbnail.dart';
import '../../widgets/training_labels.dart';
import '../bloc/exercise_explorer_bloc.dart';
import 'exercise_filters_sheet.dart';

/// Explorador del catálogo. En modo selección ([selectMode]) devuelve el
/// ejercicio elegido con `context.pop(exercise)`.
class ExerciseExplorerPage extends StatelessWidget {
  const ExerciseExplorerPage({super.key, this.selectMode = false});

  final bool selectMode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ExerciseExplorerBloc>()
            ..add(const ExerciseExplorerEvent.started()),
      child: _ExplorerView(selectMode: selectMode),
    );
  }
}

class _ExplorerView extends StatefulWidget {
  const _ExplorerView({required this.selectMode});

  final bool selectMode;

  @override
  State<_ExplorerView> createState() => _ExplorerViewState();
}

class _ExplorerViewState extends State<_ExplorerView> {
  final _search = TextEditingController();
  Timer? _debounce;
  bool _grid = true;

  ExerciseExplorerBloc get _bloc => context.read<ExerciseExplorerBloc>();

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onQuery(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _bloc.add(
        ExerciseExplorerEvent.criteriaChanged(
          _bloc.state.criteria.copyWith(query: text),
        ),
      );
    });
  }

  Future<void> _openFilters(ExerciseExplorerState state) async {
    final criteria = await showExerciseFiltersSheet(
      context,
      criteria: state.criteria,
      options: state.filters,
    );
    if (criteria != null && mounted) {
      _bloc.add(ExerciseExplorerEvent.criteriaChanged(criteria));
    }
  }

  void _onTap(Exercise exercise) {
    if (widget.selectMode) {
      context.pop(exercise);
    } else {
      context.push(TrainingPaths.exercise(exercise.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocBuilder<ExerciseExplorerBloc, ExerciseExplorerState>(
      builder: (context, state) {
        final active = state.criteria.activeFilters;
        return Scaffold(
          appBar: AppPageBar(
            title: Text(
              widget.selectMode
                  ? l10n.trainingPickExercise
                  : l10n.trainingExplorerTitle,
            ),
            actions: [
              IconButton(
                tooltip: _grid ? l10n.trainingListView : l10n.trainingGridView,
                onPressed: () => setState(() => _grid = !_grid),
                icon: Icon(
                  _grid ? Icons.view_list_rounded : Icons.grid_view_rounded,
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TokensSpacing.m,
                  TokensSpacing.s,
                  TokensSpacing.m,
                  TokensSpacing.s,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppSearchField(
                        label: l10n.trainingSearchExercises,
                        controller: _search,
                        onChanged: _onQuery,
                      ),
                    ),
                    const SizedBox(width: TokensSpacing.s),
                    Badge(
                      isLabelVisible: active > 0,
                      label: Text('$active'),
                      child: IconButton.filledTonal(
                        tooltip: l10n.trainingFilters,
                        onPressed: () => _openFilters(state),
                        icon: const Icon(AppIcons.filters),
                      ),
                    ),
                  ],
                ),
              ),
              _CategoryBar(
                selected: state.criteria.category,
                onSelected: (category) => _bloc.add(
                  ExerciseExplorerEvent.criteriaChanged(
                    state.criteria.copyWith(category: category),
                  ),
                ),
              ),
              if (state.status == ExplorerStatus.ready)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TokensSpacing.m,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.trainingResultsCount(state.totalItems),
                      style: context.textStyles.labelMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: switch (state.status) {
                  ExplorerStatus.loading => const AppSkeletonList(
                    count: 6,
                    height: 96,
                  ),
                  ExplorerStatus.failure => AppErrorView(
                    error: state.error!,
                    onRetry: () => _bloc.add(
                      ExerciseExplorerEvent.criteriaChanged(state.criteria),
                    ),
                  ),
                  ExplorerStatus.ready
                      when state.items.isEmpty &&
                          (state.criteria.query?.trim().isNotEmpty ?? false) =>
                    AppSearchEmpty(
                      query: state.criteria.query!.trim(),
                      message: active > 0 || state.criteria.category != null
                          ? l10n.trainingNoExercisesMessage
                          : null,
                      actionLabel: active > 0 || state.criteria.category != null
                          ? l10n.trainingClearFilters
                          : null,
                      actionIcon: AppIcons.clearFilters,
                      onAction: () => _bloc.add(
                        ExerciseExplorerEvent.criteriaChanged(
                          ExerciseSearchCriteria(query: state.criteria.query),
                        ),
                      ),
                    ),
                  ExplorerStatus.ready when state.items.isEmpty =>
                    AppEmptyState(
                      icon: Icons.search_off_rounded,
                      title: l10n.trainingNoExercisesTitle,
                      message: l10n.trainingNoExercisesMessage,
                      action: active > 0 || state.criteria.category != null
                          ? AppSecondaryButton(
                              label: l10n.trainingClearFilters,
                              onPressed: () => _bloc.add(
                                ExerciseExplorerEvent.criteriaChanged(
                                  ExerciseSearchCriteria(
                                    query: state.criteria.query,
                                  ),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ExplorerStatus.ready =>
                    NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.pixels >=
                            n.metrics.maxScrollExtent - 400) {
                          _bloc.add(
                            const ExerciseExplorerEvent.moreRequested(),
                          );
                        }
                        return false;
                      },
                      child: RefreshIndicator(
                        onRefresh: () async =>
                            _bloc.add(const ExerciseExplorerEvent.refreshed()),
                        child: _grid
                            ? _ExerciseGrid(state: state, onTap: _onTap)
                            : _ExerciseList(state: state, onTap: _onTap),
                      ),
                    ),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExerciseGrid extends StatelessWidget {
  const _ExerciseGrid({required this.state, required this.onTap});

  final ExerciseExplorerState state;
  final ValueChanged<Exercise> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(TokensSpacing.m),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: TokensSpacing.s,
              crossAxisSpacing: TokensSpacing.s,
              childAspectRatio: 0.78,
            ),
            itemCount: state.items.length,
            itemBuilder: (context, i) {
              final e = state.items[i];
              return AppCard(
                padding: EdgeInsets.zero,
                onTap: () => onTap(e),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, c) => ExerciseThumbnail(
                          url: e.thumbnailUrl,
                          size: c.maxWidth,
                          icon: e.category.icon,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(TokensSpacing.s),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.name,
                            style: context.textStyles.titleSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: TokensSpacing.xxs),
                          Text(
                            [
                              e.category.label(l10n),
                              e.difficulty.label(l10n),
                            ].join(' · '),
                            style: context.textStyles.labelSmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        if (state.loadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(TokensSpacing.m),
              child: AppLoadingView(),
            ),
          ),
      ],
    );
  }
}

class _ExerciseList extends StatelessWidget {
  const _ExerciseList({required this.state, required this.onTap});

  final ExerciseExplorerState state;
  final ValueChanged<Exercise> onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(TokensSpacing.m),
      itemCount: state.items.length + (state.loadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: TokensSpacing.s),
      itemBuilder: (context, i) {
        if (i >= state.items.length) return const AppLoadingView();
        final e = state.items[i];
        return AppCard(
          onTap: () => onTap(e),
          child: Row(
            children: [
              ExerciseThumbnail(url: e.thumbnailUrl, icon: e.category.icon),
              const SizedBox(width: TokensSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name, style: context.textStyles.titleSmall),
                    const SizedBox(height: TokensSpacing.xs),
                    Wrap(
                      spacing: TokensSpacing.xs,
                      runSpacing: TokensSpacing.xs,
                      children: [
                        AppPill(
                          icon: e.category.icon,
                          label: e.category.label(l10n),
                          color: context.colors.secondary,
                        ),
                        AppPill(
                          icon: Icons.signal_cellular_alt_rounded,
                          label: e.difficulty.label(l10n),
                        ),
                        if (e.targetMuscles.isNotEmpty)
                          AppPill(
                            icon: Icons.accessibility_new_rounded,
                            label: e.targetMuscles.first.name,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        );
      },
    );
  }
}

/// Categorías a un toque: lo que más se busca (estiramientos, movilidad,
/// cardio…) sin abrir la hoja de filtros. «Todas» quita la categoría.
class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.selected, required this.onSelected});

  final ExerciseCategory? selected;
  final ValueChanged<ExerciseCategory?> onSelected;

  static const _shown = [
    ExerciseCategory.strength,
    ExerciseCategory.calisthenics,
    ExerciseCategory.stretching,
    ExerciseCategory.mobility,
    ExerciseCategory.cardio,
    ExerciseCategory.plyometrics,
    ExerciseCategory.yoga,
    ExerciseCategory.pilates,
    ExerciseCategory.isometric,
    ExerciseCategory.olympic,
    ExerciseCategory.combat,
    ExerciseCategory.rehab,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return SizedBox(
      height: context.scaled(TokensLayout.minTouchTarget),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.m),
        children: [
          // Center: el ListView horizontal estiraría el chip a toda su altura.
          Center(
            child: ChoiceChip(
              label: Text(l10n.trainingCategoryAll),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final category in _shown) ...[
            const SizedBox(width: TokensSpacing.s),
            // Elegido, la marca sustituye al icono: el estado no depende solo
            // del color (WCAG 1.4.1).
            Center(
              child: ChoiceChip(
                avatar: Icon(category.icon, size: TokensSize.iconXs),
                label: Text(category.label(l10n)),
                selected: selected == category,
                onSelected: (on) => onSelected(on ? category : null),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
