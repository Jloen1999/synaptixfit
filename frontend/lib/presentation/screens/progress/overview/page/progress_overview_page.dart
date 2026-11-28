import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/usage_focus.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../../challenges/challenges_list/page/challenges_page.dart';
import '../../badges/page/badges_page.dart';
import '../../community/page/community_tab.dart';
import '../../progress_routes.dart';
import '../../widgets/study_by_subject_card.dart';
import '../../widgets/study_week_card.dart';
import '../../widgets/analytics_summary.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/next_badge_card.dart';
import '../../widgets/physical_load_card.dart';
import '../../widgets/progress_labels.dart';
import '../../widgets/streak_card.dart';
import '../../widgets/week_headline_card.dart';
import '../bloc/progress_overview_bloc.dart';

/// Pestaña «Tú» (antes «Progreso», ADR 0061): arriba tu foto y tu nombre, que
/// abren el Perfil; debajo «Resumen» (titular de la semana, nivel, racha y,
/// plegadas, las cifras), «Retos», «Insignias» y «Comunidad», cada uno con su
/// icono. Aquí viven el XP, las rachas, las insignias y los retos
/// (vocabulario.md §4); el resto de la app no enseña cifras de XP. El apartado
/// llega con `?tab=` (avisos, Inicio, celebraciones).
class ProgressOverviewPage extends StatefulWidget {
  const ProgressOverviewPage({super.key, this.tab = ProgressTab.summary});

  final ProgressTab tab;

  @override
  State<ProgressOverviewPage> createState() => _ProgressOverviewPageState();
}

class _ProgressOverviewPageState extends State<ProgressOverviewPage>
    with SingleTickerProviderStateMixin {
  late final _tabs = TabController(
    length: ProgressTab.values.length,
    vsync: this,
    initialIndex: widget.tab.index,
  );

  @override
  void initState() {
    super.initState();
    _tabs.addListener(_syncLocation);
  }

  /// La dirección sigue al apartado elegido a mano: así un enlace posterior a
  /// ese mismo apartado (`go('/progress?tab=…')`) vuelve a llevar a él.
  void _syncLocation() {
    if (_tabs.indexIsChanging || !mounted) return;
    final tab = ProgressTab.values[_tabs.index];
    if (tab == widget.tab) return;
    context.go(tab.path);
  }

  @override
  void didUpdateWidget(ProgressOverviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Un enlace nuevo (`go('/progress?tab=…')`) cambia de apartado.
    if (widget.tab != oldWidget.tab) _show(widget.tab);
  }

  void _show(ProgressTab tab) => _tabs.animateTo(
    tab.index,
    duration: context.motion(TokensDuration.normal),
  );

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final background =
        Theme.of(context).appBarTheme.backgroundColor ??
        Theme.of(context).scaffoldBackgroundColor;
    final large = context.largeText;
    return Scaffold(
      body: Column(
        children: [
          // Sin barra de título: la cabecera es la persona (abre el Perfil) y
          // las pestañas, alineadas con el contenido en pantallas anchas.
          ColoredBox(
            color: background,
            child: SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: TokensLayout.contentMaxWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _YouHeader(),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Se desplazan solo si algún apartado no cabe en su
                          // hueco (320 px, «Communauté», texto al 120 %...):
                          // se mide el ancho real, no solo el tamaño de letra.
                          final scroll = _tabsOverflow(
                            context,
                            constraints.maxWidth,
                          );
                          return TabBar(
                            controller: _tabs,
                            isScrollable: scroll,
                            tabAlignment: scroll ? TabAlignment.start : null,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: _tabPadding,
                            ),
                            tabs: [
                              for (final tab in ProgressTab.values)
                                Tab(
                                  icon: Icon(_tabIcon(tab)),
                                  text: _tabLabel(context, tab),
                                  iconMargin: const EdgeInsets.only(
                                    bottom: TokensSpacing.xxs,
                                  ),
                                  // Más baja que la de Material (72): deja
                                  // sitio al contenido. Con el texto grande,
                                  // la de siempre, para que no se corte.
                                  height: large
                                      ? null
                                      : TokensLayout.minTouchTarget +
                                            TokensSpacing.s,
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                AppKeepAlive(
                  child: BlocProvider(
                    create: (_) =>
                        getIt<ProgressOverviewBloc>()
                          ..add(const ProgressOverviewEvent.started()),
                    child: _ProgressOverviewView(
                      onOpenBadges: () => _show(ProgressTab.badges),
                    ),
                  ),
                ),
                const AppKeepAlive(child: ChallengesPage()),
                const AppKeepAlive(child: BadgesPage()),
                const AppKeepAlive(child: CommunityTab()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Margen a cada lado del texto de un apartado.
  static const _tabPadding = TokensSpacing.xs;

  /// `true` si el apartado más ancho no cabe en su parte de [width] (las
  /// pestañas fijas reparten el ancho a partes iguales).
  bool _tabsOverflow(BuildContext context, double width) {
    final theme = TabBarTheme.of(context);
    final styles = [
      theme.labelStyle ?? context.textStyles.titleSmall,
      theme.unselectedLabelStyle ?? context.textStyles.titleSmall,
    ];
    var widest = 0.0;
    for (final tab in ProgressTab.values) {
      for (final style in styles) {
        final w = context.textWidth(_tabLabel(context, tab), style);
        if (w > widest) widest = w;
      }
    }
    final slot = width / ProgressTab.values.length;
    return widest + _tabPadding * 2 > slot;
  }

  static IconData _tabIcon(ProgressTab tab) => switch (tab) {
    ProgressTab.summary => AppIcons.progressSummary,
    ProgressTab.challenges => AppIcons.challenge,
    ProgressTab.badges => AppIcons.badge,
    ProgressTab.community => AppIcons.communityTab,
  };

  static String _tabLabel(BuildContext context, ProgressTab tab) {
    final l10n = context.localizations;
    return switch (tab) {
      ProgressTab.summary => l10n.progressTabSummary,
      ProgressTab.challenges => l10n.challengesTitle,
      ProgressTab.badges => l10n.progressBadgesPageTitle,
      ProgressTab.community => l10n.progressTabCommunity,
    };
  }
}

/// Cabecera de «Tú»: tu foto y tu nombre, con «Ver perfil». Toda la fila es un
/// botón que abre el Perfil (pantalla completa, con `push`).
class _YouHeader extends StatelessWidget {
  const _YouHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final account = context.select((SessionBloc bloc) => bloc.account);
    final name = account?.fullName.trim() ?? '';
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: AppFocusOutline(
          child: InkWell(
            onTap: () => context.push(ProgressExternalPaths.profile),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: TokensSize.listTileMin,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TokensSpacing.m,
                  vertical: TokensSpacing.xs,
                ),
                child: Row(
                  children: [
                    ExcludeSemantics(
                      child: AppAvatar(
                        name: name,
                        imageUrl: account?.avatarUrl,
                        radius: TokensSize.thumbnailXs / 2,
                      ),
                    ),
                    const SizedBox(width: TokensSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // El encabezado de «Tú» para el lector: la
                          // pestaña no tiene barra de título.
                          if (name.isNotEmpty)
                            Semantics(
                              header: true,
                              child: Text(
                                name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.textStyles.titleMedium,
                              ),
                            ),
                          Text(
                            l10n.progressSeeProfile,
                            style: context.textStyles.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(AppIcons.next, color: context.colors.onSurfaceVariant),
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

class _ProgressOverviewView extends StatefulWidget {
  const _ProgressOverviewView({required this.onOpenBadges});

  /// Lleva al apartado «Insignias» de la misma pestaña.
  final VoidCallback onOpenBadges;

  @override
  State<_ProgressOverviewView> createState() => _ProgressOverviewViewState();
}

class _ProgressOverviewViewState extends State<_ProgressOverviewView>
    with ErrorsMessageMixin {
  /// «Ver más»: plegado de entrada para que el resumen vaya al grano.
  bool _more = false;

  Future<void> _refresh() {
    final bloc = context.read<ProgressOverviewBloc>()
      ..add(const ProgressOverviewEvent.refreshed());
    return bloc.stream.firstWhere(
      (s) => s is! ProgressOverviewLoaded || !s.refreshing,
    );
  }

  /// Abre otra pantalla del módulo y recarga al volver (pueden cambiar datos).
  Future<void> _open(String path) async {
    await context.push(path);
    if (mounted) unawaited(_refresh());
  }

  Future<void> _onLoaded(ProgressOverviewLoaded state) async {
    final account = state.overview.account;
    final session = context.read<SessionBloc>();
    final current = session.state;
    if (current is SessionAuthenticatedState && current.account != account) {
      session.add(SessionEvent.accountUpdated(account));
    }
    final error = state.refreshError;
    if (error != null) context.showSnack(errorMessage(context, error));
  }

  static ProgressOverviewLoaded _withoutReview(ProgressOverviewLoaded s) =>
      s.copyWith(
        openingReview: false,
        reviewQueue: null,
        reviewError: null,
        updatingStreak: false,
        streakJustPaused: null,
        streakError: null,
      );

  /// Racha recién pausada: lo dice con «Deshacer» (lo reversible no pregunta,
  /// vocabulario §4); o el error, con su texto.
  void _onStreak(ProgressOverviewLoaded state) {
    final bloc = context.read<ProgressOverviewBloc>()
      ..add(const ProgressOverviewEvent.streakHandled());
    if (state.streakError case final error?) {
      context.showSnack(errorMessage(context, error));
      return;
    }
    final until = state.streakJustPaused?.pausedUntil;
    if (until == null) return;
    context.showActionSnack(
      context.localizations.progressStreakPausedUntil(
        ProgressFormat.pauseDate(until),
      ),
      actionLabel: context.localizations.commonUndo,
      onAction: () => bloc.add(const ProgressOverviewEvent.streakResumed()),
    );
  }

  /// Abre la cola de repaso que pidió el bloc (en un toque, ADR 0041). Si ya
  /// no queda ninguno, lo avisa y recarga.
  void _onReview(ProgressOverviewLoaded state) {
    final bloc = context.read<ProgressOverviewBloc>();
    if (state.reviewError case final error?) {
      bloc.add(const ProgressOverviewEvent.reviewHandled());
      context.showSnack(errorMessage(context, error));
      return;
    }
    final queue = state.reviewQueue;
    if (queue == null) return;
    bloc.add(const ProgressOverviewEvent.reviewHandled());
    if (queue.isEmpty) {
      // Ya no queda ninguno (se repasaron en otro sitio): se dice aquí y la
      // cifra se pone al día, en vez de saltar a Académico sin explicación.
      context.showSnack(context.localizations.progressReviewsAllDone);
      bloc.add(const ProgressOverviewEvent.refreshed());
    } else {
      unawaited(
        _open(ProgressExternalPaths.review(queue.first, queue.skip(1))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<ProgressOverviewBloc, ProgressOverviewState>(
      // Pedir y abrir la cola de repaso no vuelve a avisar de la recarga.
      listenWhen: (previous, current) =>
          current is ProgressOverviewLoaded &&
          previous != current &&
          (current.reviewQueue != null ||
              current.reviewError != null ||
              current.streakJustPaused != null ||
              current.streakError != null ||
              previous is! ProgressOverviewLoaded ||
              _withoutReview(previous) != _withoutReview(current)),
      listener: (context, state) {
        if (state is! ProgressOverviewLoaded) return;
        if (state.streakJustPaused != null || state.streakError != null) {
          return _onStreak(state);
        }
        if (state.reviewQueue != null || state.reviewError != null) {
          return _onReview(state);
        }
        unawaited(_onLoaded(state));
      },
      builder: (context, state) {
        return switch (state) {
          ProgressOverviewLoading() => const _OverviewSkeleton(),
          ProgressOverviewFailure(:final error) => AppErrorView(
            error: error,
            onRetry: () => context.read<ProgressOverviewBloc>().add(
              const ProgressOverviewEvent.started(),
            ),
          ),
          ProgressOverviewLoaded(
            :final overview,
            :final today,
            :final todayError,
            :final loadingToday,
            :final openingReview,
            :final updatingStreak,
          ) =>
            _focusAware(
              context,
              (focus) => RefreshIndicator(
                onRefresh: _refresh,
                child: _Constrained(
                  children: [
                    // Al grano (vocabulario §4): el titular de la semana, el
                    // nivel y la racha; lo que sigue; y el resto, plegado.
                    WeekHeadlineCard(
                      account: overview.account,
                      streak: overview.streak,
                      focus: focus,
                      studyWeek: overview.studyWeek,
                      weekly: overview.weekly,
                      onRetry: () => context.read<ProgressOverviewBloc>().add(
                        const ProgressOverviewEvent.refreshed(),
                      ),
                      // Semana a cero: la acción útil es planificar algo.
                      onStart: () =>
                          context.go(ProgressExternalPaths.addEvent()),
                      updatingStreak: updatingStreak,
                      onPauseStreak: () => context
                          .read<ProgressOverviewBloc>()
                          .add(const ProgressOverviewEvent.streakPaused()),
                      onResumeStreak: () => context
                          .read<ProgressOverviewBloc>()
                          .add(const ProgressOverviewEvent.streakResumed()),
                    ),
                    if (focus.includesAcademic &&
                        (overview.studyWeek?.reviewsDue ?? 0) > 0)
                      AppPrimaryButton(
                        label: l10n.progressStudyReviewNow(
                          overview.studyWeek!.reviewsDue,
                        ),
                        icon: AppIcons.review,
                        loading: openingReview,
                        // Un toque: abre la cola de repaso, no Académico.
                        onPressed: () => context
                            .read<ProgressOverviewBloc>()
                            .add(const ProgressOverviewEvent.reviewRequested()),
                      ),
                    // Las ganadas están en «Insignias»: aquí solo la siguiente.
                    if (overview.nextBadge case final next?)
                      NextBadgeCard(badge: next, onOpen: widget.onOpenBadges),
                    _MoreToggle(
                      open: _more,
                      onToggle: () {
                        setState(() => _more = !_more);
                        // «Tu equilibrio» se pide al desplegar, no al entrar.
                        if (_more) {
                          context.read<ProgressOverviewBloc>().add(
                            const ProgressOverviewEvent.balanceRequested(),
                          );
                        }
                      },
                    ),
                    if (_more) ...[
                      // Carga cognitiva, carga física y energía de hoy: cifras
                      // técnicas que salieron de Inicio (ADR 0038).
                      if (today == null && loadingToday)
                        const AppSkeletonGroup(
                          child: AppSkeleton(height: TokensSize.skeletonCard),
                        )
                      else if (today != null)
                        BalanceCard(
                          cognitive: today.cognitive,
                          crossRegulation: today.crossRegulation,
                          wellbeing: today.wellbeing,
                          focus: focus,
                        )
                      else if (todayError != null)
                        _BalanceError(
                          focus: focus,
                          error: todayError,
                          onRetry: () => context
                              .read<ProgressOverviewBloc>()
                              .add(const ProgressOverviewEvent.refreshed()),
                        ),
                      StreakCard(streak: overview.streak),
                      // Cifras de estudio: solo si la persona estudia.
                      if (focus.includesAcademic) ...[
                        StudyWeekCard(
                          week: overview.studyWeek,
                          onFocus: () =>
                              context.push(ProgressExternalPaths.pomodoro),
                          onRetry: () => context
                              .read<ProgressOverviewBloc>()
                              .add(const ProgressOverviewEvent.refreshed()),
                        ),
                        StudyBySubjectCard(report: overview.studyBySubject),
                      ],
                      // Cifras de entrenamiento: solo si la persona hace deporte.
                      if (focus.includesFitness) ...[
                        WeeklySummaryCard(
                          weekly: overview.weekly,
                          onOpen: () => _open(ProgressPaths.analytics),
                        ),
                        PhysicalLoadCard(load: overview.physicalLoad),
                      ],
                    ],
                  ],
                ),
              ),
            ),
        };
      },
    );
  }
}

/// Construye con el enfoque de uso de la sesión (estudios, deporte o ambos).
Widget _focusAware(BuildContext context, Widget Function(UsageFocus) build) =>
    build(
      context.select(
        (SessionBloc bloc) => bloc.account?.usageFocus ?? UsageFocus.both,
      ),
    );

/// Lista centrada con ancho máximo para web y tablet.
class _Constrained extends StatelessWidget {
  const _Constrained({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(TokensSpacing.m),
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(height: TokensSpacing.m),
      itemBuilder: (context, index) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: TokensLayout.contentMaxWidth,
          ),
          child: children[index],
        ),
      ),
    );
  }
}

class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return const AppSkeletonGroup(
      child: _Constrained(
        children: [
          AppSkeleton(height: TokensSize.chartCompact),
          AppSkeleton(height: TokensSize.listTileMin),
          AppSkeleton(height: TokensSize.skeletonCard),
        ],
      ),
    );
  }
}

/// «Tu equilibrio» sin datos por un error: el título se conserva (la persona
/// sabe qué falta) y debajo el motivo con «Reintentar».
class _BalanceError extends StatelessWidget {
  const _BalanceError({
    required this.focus,
    required this.error,
    required this.onRetry,
  });

  /// Mismo título que la tarjeta con datos («Tu estado» con un solo enfoque).
  final UsageFocus focus;
  final AppError error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AppSectionHeader(
        title: focus == UsageFocus.both
            ? context.localizations.homeBalanceTitle
            : context.localizations.homeStateTitle,
      ),
      AppCard(
        child: AppErrorView(error: error, onRetry: onRetry),
      ),
    ],
  );
}

/// «Ver más» / «Ver menos»: despliega las cifras de detalle del resumen.
class _MoreToggle extends StatelessWidget {
  const _MoreToggle({required this.open, required this.onToggle});

  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Semantics(
      expanded: open,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        // Con borde: parece un botón (no un texto de color).
        child: OutlinedButton.icon(
          onPressed: onToggle,
          icon: Icon(open ? AppIcons.collapse : AppIcons.expand),
          label: Text(open ? l10n.commonShowLess : l10n.progressShowMore),
        ),
      ),
    );
  }
}
