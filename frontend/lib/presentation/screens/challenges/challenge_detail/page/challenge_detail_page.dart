import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/challenge_link_type.dart';
import '../../../../../domain/enums/challenge_status.dart';
import '../../../../../domain/enums/challenge_type.dart';
import '../../../../../domain/models/challenges/challenge.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../challenges_routes.dart';
import '../../quick_challenge/page/quick_challenge_sheet.dart';
import '../../widgets/challenge_content_width.dart';
import '../../widgets/challenge_feedback.dart';
import '../../widgets/challenge_focus.dart';
import '../../widgets/challenge_labels.dart';
import '../../widgets/challenge_next_step.dart';
import '../../widgets/challenge_progress_bar.dart';
import '../../widgets/dependency_graph.dart';
import '../../widgets/milestone_tile.dart';
import '../bloc/challenge_detail_bloc.dart';
import 'challenge_detail_dialogs.dart';

/// Detalle de un reto (`/challenges/:challengeId`).
class ChallengeDetailPage extends StatelessWidget {
  const ChallengeDetailPage({super.key, required this.challengeId});

  final String challengeId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ChallengeDetailBloc>()
            ..add(ChallengeDetailEvent.started(challengeId)),
      child: _DetailView(challengeId: challengeId),
    );
  }
}

enum _MenuAction {
  recordProgress,
  edit,
  editTasks,
  reorder,
  visibility,
  delete,
}

class _DetailView extends StatelessWidget with ErrorsMessageMixin {
  const _DetailView({required this.challengeId});

  final String challengeId;

  ChallengeDetailBloc _bloc(BuildContext context) =>
      context.read<ChallengeDetailBloc>();

  Future<void> _onEffect(
    BuildContext context,
    ChallengeDetailEffect effect,
  ) async {
    final l10n = context.localizations;
    switch (effect) {
      case ChallengeDetailOutcome(
        :final xpDelta,
        :final unlockedTitles,
        :final challengeCompleted,
        :final progressRecorded,
        :final account,
      ):
        if (account != null) {
          context.read<SessionBloc>().add(SessionEvent.accountUpdated(account));
        }
        final hasMilestones =
            _bloc(context).state.challenge?.hasMilestones ?? false;
        final String base;
        if (challengeCompleted) {
          base = l10n.challengesChallengeDone;
        } else if (progressRecorded) {
          base = l10n.challengesProgressSaved;
        } else if (xpDelta < 0) {
          base = hasMilestones
              ? l10n.challengesMilestoneUndone
              : l10n.challengesChallengeUndone;
        } else {
          base = l10n.challengesMilestoneDone;
        }
        context.showSnack(
          challengeFeedbackMessage(
            context,
            base: base,
            xpDelta: xpDelta,
            unlockedTitles: unlockedTitles,
          ),
        );
      case ChallengeDetailDeleted(:final xpLost, :final account):
        if (account != null) {
          context.read<SessionBloc>().add(SessionEvent.accountUpdated(account));
        }
        context.showSnack(
          challengeFeedbackMessage(
            context,
            base: l10n.challengesDeleted,
            xpDelta: -xpLost,
          ),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(ChallengesPaths.root);
        }
      case ChallengeDetailCloned(:final challengeId):
        context.showSnack(l10n.challengesCloned);
        context.pushReplacement(ChallengesPaths.detail(challengeId));
      case ChallengeDetailSaved():
        context.showSnack(l10n.commonSaved);
      case ChallengeDetailOpenUrl(:final url):
        final ok = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
        if (!ok && context.mounted) context.showSnack(l10n.errorUnknown);
      case ChallengeDetailActionFailed(:final error):
        context.showSnack(errorMessage(context, error));
    }
  }

  Future<void> _onMenu(
    BuildContext context,
    _MenuAction action,
    Challenge challenge,
  ) async {
    final bloc = _bloc(context);
    switch (action) {
      case _MenuAction.recordProgress:
        await _recordProgress(context);
      case _MenuAction.edit:
        await _edit(context, challenge);
      case _MenuAction.editTasks:
        await _editTasks(context, challenge);
      case _MenuAction.reorder:
        final ids = await showReorderMilestonesSheet(
          context,
          challenge.milestones,
        );
        if (ids != null) {
          bloc.add(ChallengeDetailEvent.milestonesReordered(ids));
        }
      case _MenuAction.visibility:
        final visibility = await showVisibilityDialog(
          context,
          challenge.visibility,
        );
        if (visibility != null) {
          bloc.add(ChallengeDetailEvent.visibilityChanged(visibility));
        }
      case _MenuAction.delete:
        final confirmed = await showDeleteChallengeDialog(
          context,
          challenge.totalXpAwarded,
        );
        if (confirmed) bloc.add(const ChallengeDetailEvent.deleteRequested());
    }
  }

  /// Edita los datos básicos (también la fecha de fin de un reto vencido).
  Future<void> _edit(BuildContext context, Challenge challenge) async {
    final bloc = _bloc(context);
    final result = await showQuickChallengeSheet(context, editing: challenge);
    if (result is QuickChallengeSaved) {
      bloc.add(ChallengeDetailEvent.challengeReplaced(result.challenge));
    }
  }

  Future<void> _editTasks(BuildContext context, Challenge challenge) async {
    final bloc = _bloc(context);
    final saved = await context.push<String>(
      ChallengesPaths.editMilestones(challenge.id),
    );
    if (saved != null) bloc.add(const ChallengeDetailEvent.refreshed());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<ChallengeDetailBloc, ChallengeDetailState>(
      listenWhen: (_, s) => s.effect != null,
      listener: (context, state) => _onEffect(context, state.effect!),
      builder: (context, state) {
        final challenge = state.challenge;
        return Scaffold(
          appBar: AppPageBar(
            title: Text(l10n.challengesDetailTitle),
            actions: [
              if (challenge != null && challenge.owned)
                PopupMenuButton<_MenuAction>(
                  tooltip: l10n.challengesDetailMore,
                  enabled: !state.busy,
                  onSelected: (a) => _onMenu(context, a, challenge),
                  itemBuilder: (context) => [
                    // «¿Cuánto llevas?» solo en retos sin tareas (las tareas son
                    // de sí o no) que no complete su entrega.
                    if (challenge.status == ChallengeStatus.active &&
                        !challenge.hasMilestones &&
                        !challenge.completedByLink)
                      _menuItem(
                        _MenuAction.recordProgress,
                        Icons.add_chart_rounded,
                        l10n.challengesDetailRecordProgress,
                      ),
                    _menuItem(
                      _MenuAction.edit,
                      Icons.edit_outlined,
                      l10n.challengesDetailEdit,
                    ),
                    _menuItem(
                      _MenuAction.editTasks,
                      Icons.checklist_rounded,
                      challenge.hasMilestones
                          ? l10n.challengesDetailEditTasks
                          : l10n.challengesDetailAddTasks,
                    ),
                    if (challenge.milestones.length > 1)
                      _menuItem(
                        _MenuAction.reorder,
                        Icons.swap_vert_rounded,
                        l10n.challengesDetailReorder,
                      ),
                    _menuItem(
                      _MenuAction.visibility,
                      challenge.visibility.challengeIcon,
                      l10n.challengesDetailVisibility,
                    ),
                    _menuItem(
                      _MenuAction.delete,
                      Icons.delete_outline_rounded,
                      l10n.challengesDetailDelete,
                    ),
                  ],
                ),
            ],
          ),
          bottomNavigationBar: challenge == null
              ? null
              : _BottomActions(
                  challenge: challenge,
                  busy: state.busy,
                  onExtend: () => _edit(context, challenge),
                ),
          body: switch (state.status) {
            ChallengeDetailStatus.loading => const _DetailSkeleton(),
            ChallengeDetailStatus.failure => AppErrorView(
              error: state.error!,
              onRetry: () =>
                  _bloc(context).add(ChallengeDetailEvent.started(challengeId)),
            ),
            ChallengeDetailStatus.ready => RefreshIndicator(
              onRefresh: () async {
                _bloc(context).add(const ChallengeDetailEvent.refreshed());
                await _bloc(context).stream.first;
              },
              child: _DetailContent(
                state: state,
                onEditTasks: () => _editTasks(context, state.challenge!),
              ),
            ),
          },
        );
      },
    );
  }

  PopupMenuItem<_MenuAction> _menuItem(
    _MenuAction action,
    IconData icon,
    String label,
  ) => PopupMenuItem(
    value: action,
    child: ListTile(
      leading: Icon(icon),
      title: Text(label),
      contentPadding: EdgeInsets.zero,
    ),
  );
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.state, required this.onEditTasks});

  final ChallengeDetailState state;
  final VoidCallback onEditTasks;

  /// Un día de rutina se marca entrenando: se va a la pestaña Entreno (con
  /// `go`, porque es una pestaña); una entrega o un examen, a esa entrega en
  /// Entregas y exámenes, la primera y destacada. Sin su id la lista solo
  /// enseñaba la primera página de pendientes y la de la tarea no aparecía.
  static void openLink(BuildContext context, ChallengeLink link) =>
      link.type == ChallengeLinkType.routineDay
      ? context.go(ChallengesExternalPaths.training)
      : context.push(ChallengesExternalPaths.deadline(link.entityId));

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final challenge = state.challenge!;
    final bloc = context.read<ChallengeDetailBloc>();
    final titles = {for (final m in challenge.milestones) m.id: m.title};
    final link = challenge.link;
    final expired = challenge.status == ChallengeStatus.expired;
    // Solo en plazo se marca o desmarca a mano (lo dice el servidor): ni antes
    // de empezar ni vencido, donde desmarcar haría perder XP para siempre.
    final open = challenge.open;
    final nextId = challenge.nextMilestone?.id;
    final dependent = challenge.milestones
        .where((m) => m.dependencies.isNotEmpty)
        .length;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(TokensSpacing.m),
      children: [
        ChallengeContentWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Arriba, cómo va y qué toca (tras el aviso si el reto es ajeno):
              // progreso, siguiente paso y motivación. Los datos, después.
              if (!challenge.owned) ...[
                AppCard(
                  color: context.colors.primaryContainer,
                  child: Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        color: context.colors.onPrimaryContainer,
                      ),
                      const SizedBox(width: TokensSpacing.s),
                      Expanded(
                        child: Text(
                          l10n.challengesDetailReadOnly(
                            challenge.ownerName ?? l10n.challengesUnknownAuthor,
                          ),
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: context.colors.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: TokensSpacing.m),
              ],
              _SummaryCard(challenge: challenge),
              const SizedBox(height: TokensSpacing.l),
              AppSectionHeader(
                title: l10n.challengesDetailTasks,
                // Editar tareas a la vista, no solo en el menú «Más opciones».
                actionLabel: challenge.owned && challenge.hasMilestones
                    ? l10n.challengesDetailEditTasks
                    : null,
                onAction: onEditTasks,
              ),
              if (challenge.milestones.isEmpty)
                AppCard(
                  child: challenge.owned
                      ? AppEmptyState.compact(
                          icon: Icons.checklist_rounded,
                          title: l10n.challengesDetailNoTasksTitle,
                          message: l10n.challengesDetailNoTasksHint,
                          action: AppSecondaryButton(
                            label: l10n.challengesDetailAddTasks,
                            icon: const Icon(Icons.playlist_add_rounded),
                            onPressed: state.busy ? null : onEditTasks,
                          ),
                        )
                      : AppEmptyState.compact(
                          icon: Icons.checklist_rounded,
                          title: l10n.challengesDetailNoTasksReadOnly,
                        ),
                )
              else
                for (final m in challenge.milestones)
                  Padding(
                    padding: const EdgeInsets.only(bottom: TokensSpacing.s),
                    child: MilestoneTile(
                      milestone: m,
                      isNext: challenge.owned && !expired && m.id == nextId,
                      expired: expired,
                      dependencyTitles: [
                        for (final d in m.dependencies) ?titles[d],
                      ],
                      busy: state.busyMilestoneId == m.id,
                      // Fuera de plazo, o si la completa su entrega o sus
                      // bloques, no se ofrece un toque que el servidor rechaza.
                      onToggle:
                          challenge.owned &&
                              !state.busy &&
                              open &&
                              !m.completedByLink
                          ? () => bloc.add(
                              ChallengeDetailEvent.milestoneToggled(m.id),
                            )
                          : null,
                      onOpenNote: m.noteId == null
                          ? null
                          : () => context.push(
                              ChallengesExternalPaths.note(m.noteId!),
                            ),
                      onOpenFile: m.fileId == null
                          ? null
                          : () => bloc.add(
                              ChallengeDetailEvent.fileRequested(m.fileId!),
                            ),
                      onOpenLink: m.link == null || !challenge.owned
                          ? null
                          : () => openLink(context, m.link!),
                    ),
                  ),
              if (challenge.hasDependencies) ...[
                const SizedBox(height: TokensSpacing.l),
                AppSectionHeader(title: l10n.challengesDetailGraph),
                Text(
                  l10n.challengesDetailGraphSummary(dependent),
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: TokensSpacing.s),
                AppCard(
                  child: DependencyGraph(milestones: challenge.milestones),
                ),
              ],
              const SizedBox(height: TokensSpacing.l),
              AppSectionHeader(title: l10n.challengesFormSectionDetails),
              _DetailsCard(
                challenge: challenge,
                subjectName: state.subjectName,
              ),
              if (link != null) ...[
                const SizedBox(height: TokensSpacing.s),
                AppCard(
                  onTap: challenge.owned
                      ? () => openLink(context, link)
                      : null,
                  child: Row(
                    children: [
                      Icon(link.type.icon, color: context.colors.tertiary),
                      const SizedBox(width: TokensSpacing.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              challenge.linkTitle ??
                                  link.type.linkedLabel(context),
                              style: context.textStyles.bodyLarge,
                            ),
                            if (challenge.linkDueAt case final due?)
                              Text(
                                l10n.challengesFeedbackJoin(
                                  link.type.label(context),
                                  ChallengeFormats.dateTime(due),
                                ),
                                style: context.textStyles.labelMedium?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                            // Con tareas, el vínculo del reto es una referencia:
                            // lo completan sus tareas.
                            if (challenge.completedByLink)
                              Text(
                                l10n.challengesLinkDrivesChallenge,
                                style: context.textStyles.labelMedium?.copyWith(
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Toda la tarjeta abre el planificador: basta la flecha,
                      // que no le quita ancho al título con el texto grande.
                      if (challenge.owned)
                        Icon(
                          Icons.chevron_right_rounded,
                          color: context.colors.onSurfaceVariant,
                        ),
                    ],
                  ),
                ),
              ],
              if (challenge.owned) ...[
                const SizedBox(height: TokensSpacing.l),
                AppSectionHeader(title: l10n.challengesDetailHistory),
                if (state.history.isEmpty)
                  Text(
                    l10n.challengesDetailHistoryEmpty,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  )
                else
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final e in state.history)
                          ListTile(
                            leading: Icon(
                              Icons.trending_up_rounded,
                              color: context.palette.success,
                            ),
                            title: Text(
                              e.milestoneId == null
                                  ? l10n.challengesDetailHistoryGeneral
                                  : titles[e.milestoneId] ??
                                        l10n.challengesProgressTask,
                            ),
                            subtitle: Text(
                              ChallengeFormats.dateTime(e.recordedAt),
                            ),
                            trailing: Text(
                              l10n.challengesDetailHistoryEntry(
                                ChallengeFormats.number(e.amount),
                              ),
                              style: context.textStyles.labelLarge,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: TokensSpacing.xl),
            ],
          ),
        ),
      ],
    );
  }
}

/// Cabecera del detalle: plazo, título, progreso grande, siguiente paso y
/// cifras de motivación (racha, mejor racha y recompensa).
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final status = challenge.status;
    final accent = challenge.type.color(context);
    final goal = challenge.goal;
    final percent = (challenge.progressFraction * 100).round();
    final nextStep = challengeNextStepText(context, challenge);
    final counts = challenge.tracksTrainingSessions
        ? l10n.challengesSessionsProgress(
            challenge.sessionsCompleted,
            challenge.sessionTarget ?? 0,
          )
        : challenge.hasMilestones
        ? l10n.challengesMilestonesProgress(
            challenge.completedMilestoneCount,
            challenge.milestoneCount,
          )
        : null;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: TokensSpacing.s,
            runSpacing: TokensSpacing.xs,
            children: [
              ChallengeTimePill(challenge: challenge),
              AppPill(
                icon: challenge.type.icon,
                label: challenge.type.label(context),
                color: accent,
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.m),
          Semantics(
            header: true,
            child: Text(
              challenge.title,
              style: context.textStyles.headlineSmall,
            ),
          ),
          if (goal != null && goal.isNotEmpty && goal != challenge.title) ...[
            const SizedBox(height: TokensSpacing.s),
            Text(goal, style: context.textStyles.bodyMedium),
          ],
          const SizedBox(height: TokensSpacing.m),
          Wrap(
            spacing: TokensSpacing.s,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              // La cifra grande es visual; la barra ya anuncia el porcentaje.
              ExcludeSemantics(
                child: Text(
                  l10n.challengesProgressPercent(percent),
                  style: context.textStyles.headlineMedium,
                ),
              ),
              if (counts != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: TokensSpacing.xs),
                  child: Text(
                    counts,
                    style: context.textStyles.labelLarge?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
          ChallengeProgressBar(
            value: challenge.progressFraction,
            showLabel: false,
            color: status == ChallengeStatus.completed
                ? context.palette.success
                : accent,
          ),
          if (challenge.tracksTrainingSessions) ...[
            const SizedBox(height: TokensSpacing.s),
            Text(
              l10n.challengesDetailSessionsInfo,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          if (nextStep != null) ...[
            const SizedBox(height: TokensSpacing.m),
            _NextStepBox(challenge: challenge, text: nextStep),
          ],
          const SizedBox(height: TokensSpacing.m),
          // En rejilla: con el texto al 200 % pasa a filas de la mitad en
          // lugar de cortar «Recompensa». La racha solo cuenta en retos propios.
          AppTileGrid(
            children: [
              if (challenge.owned) ...[
                _Stat(
                  icon: Icons.local_fire_department_rounded,
                  color: context.palette.streak,
                  label: l10n.challengesDetailStreak,
                  value: l10n.challengesDetailDaysValue(
                    challenge.currentStreak,
                  ),
                ),
                _Stat(
                  icon: Icons.military_tech_outlined,
                  color: context.palette.streak,
                  label: l10n.challengesDetailBestStreak,
                  value: l10n.challengesDetailDaysValue(challenge.bestStreak),
                ),
              ],
              // Con tareas, la XP la reparte el servidor con un tope por reto:
              // la ganada y la que puede dar en total (ya con el tope).
              _Stat(
                icon: Icons.bolt_rounded,
                color: context.palette.accent,
                label: challenge.hasMilestones
                    ? l10n.challengesDetailXpEarned
                    : l10n.challengesDetailReward,
                value: challenge.hasMilestones
                    ? l10n.challengesXpOfTotal(
                        challenge.totalXpAwarded,
                        challenge.xpReward,
                      )
                    : l10n.challengesXpGain(challenge.xpReward),
              ),
            ],
          ),
          if (challenge.owned &&
              status == ChallengeStatus.active &&
              challenge.currentStreak == 0) ...[
            const SizedBox(height: TokensSpacing.s),
            Text(
              l10n.challengesStreakStart,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Caja «Siguiente paso» con el tinte del estado (lima si toca avanzar,
/// naranja de logro si está conseguido, aviso si venció).
class _NextStepBox extends StatelessWidget {
  const _NextStepBox({required this.challenge, required this.text});

  final Challenge challenge;
  final String text;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final color = switch (challenge.status) {
      ChallengeStatus.completed => context.palette.accent,
      ChallengeStatus.expired => context.palette.warning,
      ChallengeStatus.upcoming => context.colors.onSurfaceVariant,
      ChallengeStatus.active => context.colors.primary,
    };
    final next = challenge.nextMilestone;
    final active = challenge.status == ChallengeStatus.active;
    return MergeSemantics(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(TokensSpacing.sm),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            color.withValues(alpha: AppPill.tintAlpha),
            context.colors.surface,
          ),
          borderRadius: BorderRadius.circular(TokensRadius.m),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              challengeNextStepIcon(challenge),
              color: color,
              size: TokensSize.iconS,
            ),
            const SizedBox(width: TokensSpacing.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (active)
                    Text(
                      l10n.challengesNextStepTitle,
                      style: context.textStyles.labelMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  Text(
                    // Con tarea siguiente, su nombre a secas (la etiqueta
                    // «Siguiente paso» ya va encima).
                    active && next != null && !challenge.tracksTrainingSessions
                        ? next.title
                        : text,
                    style: context.textStyles.titleSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Datos del reto (tipo, esfuerzo, visibilidad, fechas, asignatura y autor).
class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.challenge, this.subjectName});

  final Challenge challenge;
  final String? subjectName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final origin = challenge.originOwnerName;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: TokensSpacing.s,
            runSpacing: TokensSpacing.xs,
            children: [
              AppPill(
                icon: challenge.difficulty.icon,
                label: challenge.difficulty.effortLabel(context),
              ),
              if (challenge.owned)
                AppPill(
                  icon: challenge.visibility.challengeIcon,
                  label: challenge.visibility.challengeLabel(context),
                ),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
          _InfoRow(
            icon: Icons.date_range_outlined,
            text: l10n.challengesDetailDates(
              ChallengeFormats.longDate(challenge.startAt),
              ChallengeFormats.longDate(challenge.endAt),
            ),
          ),
          if (subjectName != null)
            _InfoRow(icon: Icons.menu_book_outlined, text: subjectName!),
          if (!challenge.owned)
            _InfoRow(
              icon: Icons.person_outline_rounded,
              text: l10n.challengesByAuthor(
                challenge.ownerName ?? l10n.challengesUnknownAuthor,
              ),
            ),
          if (origin != null)
            _InfoRow(
              icon: Icons.copy_all_rounded,
              text: l10n.challengesClonedFrom(origin),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: TokensSpacing.xs),
      child: Row(
        children: [
          Icon(
            icon,
            size: TokensSize.iconXs,
            color: context.colors.onSurfaceVariant,
          ),
          const SizedBox(width: TokensSpacing.s),
          Expanded(
            child: Text(
              text,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cifra pequeña con icono; se lee como una sola frase («Racha, 3 días»).
class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: TokensSize.iconS),
          const SizedBox(height: TokensSpacing.xs),
          Text(value, style: context.textStyles.titleSmall),
          Text(
            label,
            style: context.textStyles.labelSmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra inferior con la acción principal según el estado del reto: avanzar
/// (siguiente tarea, completar o ir a Rutinas), ampliar la fecha si venció o
/// añadirlo a los propios si es ajeno. Como mucho, una acción secundaria.
class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.challenge,
    required this.busy,
    required this.onExtend,
  });

  final Challenge challenge;
  final bool busy;
  final VoidCallback onExtend;

  Future<void> _toggleCompletion(BuildContext context) async {
    final bloc = context.read<ChallengeDetailBloc>();
    if (challenge.completed) {
      final confirmed = await showUncompleteDialog(context);
      if (!confirmed) return;
    }
    bloc.add(const ChallengeDetailEvent.completionToggled());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<ChallengeDetailBloc>();
    Widget? primary;
    Widget? secondary;
    if (!challenge.owned) {
      primary = AppPrimaryButton(
        label: l10n.challengesClone,
        icon: Icons.library_add_outlined,
        loading: busy,
        onPressed: () => bloc.add(const ChallengeDetailEvent.cloneRequested()),
      );
    } else {
      switch (challenge.status) {
        case ChallengeStatus.expired:
          primary = AppPrimaryButton(
            label: l10n.challengesDetailExtend,
            icon: Icons.update_rounded,
            onPressed: busy ? null : onExtend,
          );
        case ChallengeStatus.completed:
          // Deshacer no es la acción que se busca: va como secundaria. No se
          // ofrece si lo completó su entrega ni con el plazo ya cerrado.
          if (!challenge.hasMilestones &&
              !challenge.completedByLink &&
              challenge.open) {
            secondary = AppSecondaryButton(
              label: l10n.challengesDetailUncomplete,
              loading: busy,
              onPressed: () => _toggleCompletion(context),
            );
          }
        case ChallengeStatus.upcoming:
          // Aún no empieza (la pastilla del resumen dice cuándo): lo que se
          // puede hacer es ajustar las fechas.
          primary = AppPrimaryButton(
            label: l10n.challengesDetailEdit,
            icon: Icons.edit_calendar_outlined,
            onPressed: busy ? null : onExtend,
          );
        case ChallengeStatus.active:
          final next = challenge.nextMilestone;
          // Sin Rutinas en el enfoque de uso, la pestaña no existe.
          if (challenge.tracksTrainingSessions &&
              context.allowedChallengeTypes.contains(ChallengeType.fitness)) {
            primary = AppPrimaryButton(
              label: l10n.challengesDetailGoTraining,
              icon: Icons.fitness_center_rounded,
              onPressed: () => context.go(ChallengesExternalPaths.training),
            );
          } else if (challenge.completedByLink) {
            // Lo completa su entrega o examen: se va a marcarlo allí.
            final link = challenge.link;
            final linkType = link?.type ?? ChallengeLinkType.delivery;
            primary = AppPrimaryButton(
              label: linkType == ChallengeLinkType.routineDay
                  ? l10n.challengesLinkOpenRoutine
                  : l10n.challengesLinkOpen,
              icon: linkType == ChallengeLinkType.routineDay
                  ? Icons.fitness_center_rounded
                  : Icons.event_available_outlined,
              onPressed: () => link == null
                  ? context.push(ChallengesExternalPaths.deadlines)
                  : _DetailContent.openLink(context, link),
            );
          } else if (challenge.hasMilestones) {
            // «Completar siguiente tarea» salta las que avanzan solas.
            if (next != null) {
              primary = AppPrimaryButton(
                label: l10n.challengesDetailCompleteNext,
                icon: Icons.check_rounded,
                loading: busy,
                onPressed: () =>
                    bloc.add(ChallengeDetailEvent.milestoneToggled(next.id)),
              );
            }
          } else {
            primary = AppPrimaryButton(
              label: l10n.challengesDetailComplete,
              icon: Icons.check_rounded,
              loading: busy,
              onPressed: () => _toggleCompletion(context),
            );
            secondary = AppSecondaryButton(
              label: l10n.challengesDetailRecordProgress,
              icon: const Icon(Icons.add_chart_rounded),
              onPressed: busy ? null : () => _recordProgress(context),
            );
          }
      }
    }
    final buttons = [?secondary, ?primary];
    if (buttons.isEmpty) return const SizedBox.shrink();
    // Con el texto grande, uno debajo de otro (la principal arriba) para que
    // las etiquetas no se corten.
    final stacked = context.scaled(1) > 1.3;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(TokensSpacing.m),
        child: ChallengeContentWidth(
          child: stacked
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, b) in buttons.reversed.indexed) ...[
                      if (i > 0) const SizedBox(height: TokensSpacing.s),
                      b,
                    ],
                  ],
                )
              : Row(
                  children: [
                    for (final (i, b) in buttons.indexed) ...[
                      if (i > 0) const SizedBox(width: TokensSpacing.s),
                      Expanded(child: b),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// Abre el diálogo de progreso manual y lo registra en el bloc del detalle.
Future<void> _recordProgress(BuildContext context) async {
  final bloc = context.read<ChallengeDetailBloc>();
  final challenge = bloc.state.challenge;
  if (challenge == null) return;
  final result = await showRecordProgressDialog(context, challenge);
  if (result != null) {
    bloc.add(ChallengeDetailEvent.progressRecorded(value: result.value));
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(TokensSpacing.m),
    children: const [
      AppSkeletonGroup(
        child: ChallengeContentWidth(
          child: Column(
            children: [
              AppSkeleton(height: 260),
              SizedBox(height: TokensSpacing.l),
              AppSkeleton(height: 96),
              SizedBox(height: TokensSpacing.s),
              AppSkeleton(height: 96),
            ],
          ),
        ),
      ),
    ],
  );
}
