import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/item_time_status.dart';
import '../../../../../domain/enums/planner_enums.dart';
import '../../../../../domain/models/planner/deadline.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../widgets/deadline_form_sheet.dart';
import '../../widgets/planner_visuals.dart';
import '../bloc/deadlines_bloc.dart';

/// Qué se sabe ya de la entrega que se va a apuntar al abrir la pantalla con
/// el formulario abierto (`?new=1`, ver `PlannerPaths.newDeadline`).
class DeadlineCreateRequest {
  const DeadlineCreateRequest({this.subjectId, this.exam = false, this.due});

  final String? subjectId;
  final bool exam;
  final DateTime? due;
}

/// Entregas y exámenes (`/planner/deadlines`). Con [focusId] (desde su
/// aviso), esa entrega sale la primera y destacada. Con [create], el
/// formulario de una nueva se abre nada más cargar.
class DeadlinesPage extends StatelessWidget {
  const DeadlinesPage({super.key, this.focusId, this.create});

  final String? focusId;
  final DeadlineCreateRequest? create;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<DeadlinesBloc>()..add(DeadlinesEvent.started(focusId: focusId)),
      child: _DeadlinesView(create: create),
    );
  }
}

class _DeadlinesView extends StatefulWidget {
  const _DeadlinesView({this.create});

  final DeadlineCreateRequest? create;

  @override
  State<_DeadlinesView> createState() => _DeadlinesViewState();
}

class _DeadlinesViewState extends State<_DeadlinesView>
    with ErrorsMessageMixin {
  /// Última entrega marcada o desmarcada aquí: el aviso de completar no dice
  /// cuál fue y «Deshacer» la necesita.
  String? _toggledId;

  /// El formulario pedido al abrir ya se abrió (solo una vez).
  bool _createOpened = false;

  /// Último aviso mostrado: el oyente también salta al cambiar el estado.
  int _lastNoticeId = 0;

  /// Foco del botón «Marcar como hecho» de cada entrega, estable por id: al
  /// guardar el botón sigue ahí (desactivado) y el foco no se pierde.
  final _toggleFocus = <String, FocusNode>{};

  FocusNode _toggleFocusOf(String id) => _toggleFocus.putIfAbsent(
    id,
    () => FocusNode(debugLabel: 'deadline-toggle-$id'),
  );

  @override
  void dispose() {
    for (final node in _toggleFocus.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _openForm(
    BuildContext context, {
    Deadline? deadline,
    DeadlineCreateRequest? preset,
  }) async {
    final bloc = context.read<DeadlinesBloc>();
    final draft = await DeadlineFormSheet.show(
      context,
      deadline: deadline,
      subjects: bloc.state.subjects,
      initialType: preset?.exam ?? false ? DeadlineType.exam : null,
      initialSubjectId: preset?.subjectId,
      initialDue: preset?.due,
      onDelete: deadline == null ? null : () => _delete(context, deadline.id),
    );
    if (draft != null) {
      bloc.add(DeadlinesEvent.saved(id: deadline?.id, draft: draft));
    } else if (preset != null && context.mounted) {
      // Se vino a apuntar una entrega y se canceló: se vuelve a donde se
      // estaba, no a una lista que no se pidió.
      context.pop();
    }
  }

  /// Borrar (deslizando la fila o desde el formulario): desaparece ya y el
  /// aviso ofrece «Deshacer».
  void _delete(BuildContext context, String id) {
    FocusScope.of(context).nextFocus();
    context.read<DeadlinesBloc>().add(DeadlinesEvent.deleted(id));
  }

  /// Abre el formulario pedido al entrar, cuando ya están las asignaturas.
  void _openPendingCreate(BuildContext context, DeadlinesState state) {
    final create = widget.create;
    if (create == null || _createOpened) return;
    // Sin cargar (o con error) no se abre: la pantalla enseña el motivo.
    if (state.status != DeadlinesStatus.ready) return;
    _createOpened = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_openForm(this.context, preset: create));
    });
  }

  void _onNotice(BuildContext context, DeadlinesNotice notice) {
    final l10n = context.localizations;
    switch (notice) {
      case DeadlinesNoticeSaved(:final created):
        context.showSnack(
          created ? l10n.plannerDeadlineCreated : l10n.plannerDeadlineUpdated,
        );
      case DeadlinesNoticeDeleted(:final id):
        final bloc = context.read<DeadlinesBloc>();
        context.showUndoSnack(
          l10n.plannerDeadlineDeleted,
          onUndo: () {
            if (!bloc.isClosed) bloc.add(DeadlinesEvent.deleteUndone(id));
          },
          onCommit: () {
            if (!bloc.isClosed) bloc.add(DeadlinesEvent.deleteCommitted(id));
          },
        );
      case DeadlinesNoticeCompletion(:final completed, :final account):
        if (account != null) {
          context.read<SessionBloc>().add(SessionEvent.accountUpdated(account));
        }
        final message = completed
            ? l10n.plannerDeadlineCompleted
            : l10n.plannerDeadlinePending;
        final bloc = context.read<DeadlinesBloc>();
        final id = _toggledId;
        // «Deshacer» vuelve a cambiarla con el mismo caso de uso (y el
        // servidor devuelve el XP). Con el filtro «Por hacer» la entrega hecha
        // sale de la lista y ya no se puede cambiar desde aquí.
        if (id != null && bloc.state.items.any((d) => d.id == id)) {
          context.showActionSnack(
            message,
            actionLabel: l10n.commonUndo,
            duration: TokensDuration.undoWindow,
            onAction: () {
              if (!bloc.isClosed) {
                bloc.add(DeadlinesEvent.completionToggled(id));
              }
            },
          );
        } else {
          context.showSnack(message);
        }
      case DeadlinesNoticeFailure(:final error):
        context.showSnack(errorMessage(context, error));
    }
  }

  @override
  Widget build(BuildContext context) => AppUndoShortcut(
    onUndo: () {
      final bloc = context.read<DeadlinesBloc>();
      final last = bloc.state.pendingDeletionIds.lastOrNull;
      if (last == null) return;
      bloc.add(DeadlinesEvent.deleteUndone(last));
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    },
    child: _content(context),
  );

  Widget _content(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<DeadlinesBloc, DeadlinesState>(
      listenWhen: (a, b) =>
          (a.noticeId != b.noticeId && b.notice != null) ||
          (a.status != b.status && !_createOpened),
      listener: (context, state) {
        _openPendingCreate(context, state);
        if (state.notice != null && state.noticeId > _lastNoticeId) {
          _lastNoticeId = state.noticeId;
          _onNotice(context, state.notice!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppPageBar.reading(title: Text(l10n.plannerDeadlinesTitle)),
          // Con la lista vacía el estado vacío ya lleva «Nueva entrega».
          floatingActionButton:
              state.status == DeadlinesStatus.ready &&
                  state.visibleItems.isEmpty
              ? null
              : FloatingActionButton.extended(
                  heroTag: 'planner-add-deadline',
                  onPressed: state.saving ? null : () => _openForm(context),
                  icon: const Icon(AppIcons.add),
                  label: Text(l10n.plannerNewDeadline),
                ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: TokensLayout.readingMaxWidth,
              ),
              child: Column(
                children: [
                  _Filters(state: state),
                  Expanded(child: _list(context, state)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _list(BuildContext context, DeadlinesState state) {
    final l10n = context.localizations;
    final bloc = context.read<DeadlinesBloc>();
    switch (state.status) {
      case DeadlinesStatus.loading:
        return AppSkeletonGroup(
          child: ListView(
            padding: const EdgeInsets.all(TokensSpacing.m),
            children: [
              for (var i = 0; i < 5; i++) ...[
                const AppSkeleton(height: 76),
                const SizedBox(height: TokensSpacing.s),
              ],
            ],
          ),
        );
      case DeadlinesStatus.failure:
        return AppErrorView(
          error: state.error!,
          onRetry: () => bloc.add(const DeadlinesEvent.started()),
        );
      case DeadlinesStatus.ready:
        return RefreshIndicator(
          onRefresh: () async {
            bloc.add(const DeadlinesEvent.refreshed());
            await bloc.stream.first.timeout(
              const Duration(seconds: 10),
              onTimeout: () => bloc.state,
            );
          },
          child: state.visibleItems.isEmpty
              ? ListView(
                  children: [
                    if (state.focusMissing)
                      Padding(
                        padding: const EdgeInsets.all(TokensSpacing.m),
                        child: AppInlineMessage(
                          message: l10n.plannerDeadlineGone,
                          tone: AppMessageTone.warning,
                        ),
                      ),
                    AppEmptyState(
                      icon: Icons.event_available_rounded,
                      title: l10n.plannerDeadlinesEmptyTitle,
                      message: l10n.plannerDeadlinesEmptyMessage,
                      action: AppPrimaryButton(
                        label: l10n.plannerNewDeadline,
                        icon: AppIcons.add,
                        onPressed: () => _openForm(context),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    TokensSpacing.m,
                    TokensSpacing.s,
                    TokensSpacing.m,
                    TokensLayout.fabClearance,
                  ),
                  itemCount:
                      state.visibleItems.length +
                      (state.hasMore ? 1 : 0) +
                      (state.focusMissing ? 1 : 0),
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: TokensSpacing.s),
                  itemBuilder: (context, index) {
                    // Aviso de una entrega borrada: se dice y debajo están
                    // las demás (la acción útil es elegir otra o crearla).
                    if (state.focusMissing && index == 0) {
                      return AppInlineMessage(
                        message: l10n.plannerDeadlineGone,
                        tone: AppMessageTone.warning,
                      );
                    }
                    final i = state.focusMissing ? index - 1 : index;
                    if (i == state.visibleItems.length) {
                      return Center(
                        child: state.loadingMore
                            ? const Padding(
                                padding: EdgeInsets.all(TokensSpacing.s),
                                child: CircularProgressIndicator(),
                              )
                            : TextButton(
                                onPressed: () => bloc.add(
                                  const DeadlinesEvent.moreRequested(),
                                ),
                                child: Text(l10n.plannerLoadMore),
                              ),
                      );
                    }
                    final d = state.visibleItems[i];
                    final tile = _DeadlineTile(
                      deadline: d,
                      highlighted: d.id == state.focusId,
                      subjectName: state.subjectName(d.subjectId),
                      busy: state.busyIds.contains(d.id),
                      toggleFocus: _toggleFocusOf(d.id),
                      onToggle: () {
                        _toggledId = d.id;
                        bloc.add(DeadlinesEvent.completionToggled(d.id));
                      },
                      onEdit: () => _openForm(context, deadline: d),
                      onDelete: () => _delete(context, d.id),
                    );
                    // Una línea sobre la primera: borrar es deslizar (el
                    // lector tiene la acción en la fila).
                    if (i != 0) return tile;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ExcludeSemantics(
                          child: Row(
                            children: [
                              Icon(
                                Icons.swipe_left_rounded,
                                size: TokensSize.iconXs,
                                color: context.colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: TokensSpacing.xs),
                              Expanded(
                                child: Text(
                                  l10n.plannerDeadlinesSwipeHint,
                                  style: context.textStyles.bodySmall?.copyWith(
                                    color: context.colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: TokensSpacing.xs),
                        tile,
                      ],
                    );
                  },
                ),
        );
    }
  }
}

class _Filters extends StatelessWidget {
  const _Filters({required this.state});

  final DeadlinesState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<DeadlinesBloc>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TokensSpacing.m,
        TokensSpacing.s,
        TokensSpacing.m,
        0,
      ),
      child: Wrap(
        spacing: TokensSpacing.s,
        runSpacing: TokensSpacing.s,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: true,
                label: Text(l10n.plannerFilterPending),
              ),
              ButtonSegment(value: false, label: Text(l10n.plannerFilterAll)),
            ],
            selected: {state.pendingOnly},
            onSelectionChanged: (s) =>
                bloc.add(DeadlinesEvent.pendingFilterChanged(s.first)),
          ),
          if (state.subjects.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: TokensLayout.filterMaxWidth,
              ),
              child: DropdownButtonFormField<String?>(
                initialValue: state.subjectId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.plannerFieldSubject,
                  isDense: true,
                ),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(l10n.plannerFilterSubjectAll),
                  ),
                  for (final s in state.subjects)
                    DropdownMenuItem(value: s.id, child: Text(s.name)),
                ],
                onChanged: (v) =>
                    bloc.add(DeadlinesEvent.subjectFilterChanged(v)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tarjeta de una entrega o examen, leída en el orden en que se actúa:
/// cuándo (bloque de fecha a la izquierda y «Vence mañana · 23:59», en aviso si
/// es hoy o mañana y en error si venció sin hacerse), qué (título) y de qué
/// (tipo, asignatura, dificultad, en pastillas). La zona de texto abre la
/// edición; marcar como hecha es un botón aparte (sin toques anidados).
/// Borrar no ocupa sitio en cada fila (ADR 0039): se desliza hacia la
/// izquierda (con «Deshacer»), está en el formulario y, para el lector de
/// pantalla, es una acción de la fila. Con el texto grande o poco ancho, la
/// fecha va encima y el botón debajo.
class _DeadlineTile extends StatelessWidget {
  const _DeadlineTile({
    required this.deadline,
    this.highlighted = false,
    required this.subjectName,
    required this.busy,
    this.toggleFocus,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Deadline deadline;

  /// La entrega del aviso que abrió la pantalla: lleva una marca y un borde.
  final bool highlighted;
  final String? subjectName;
  final bool busy;
  final FocusNode? toggleFocus;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final d = deadline;
    final now = DateTime.now();
    final missed = !d.completed && d.timeStatus == ItemTimeStatus.missed;
    final soon = !d.completed && AppDueDates.isSoon(d.dueAt, now);
    final color = d.completed
        ? context.palette.success
        : missed
        ? context.colors.error
        : soon
        ? context.palette.warning
        : context.colors.tertiary;
    final when = d.completed
        ? l10n.plannerDeadlineDoneCaption
        : '${AppDueDates.text(context, d.dueAt, now, overdue: missed)} · '
              '${DateFormat.Hm().format(d.dueAt)}';
    final subject = subjectName;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (highlighted) ...[
          Row(
            children: [
              Icon(
                Icons.notifications_active_rounded,
                size: TokensSize.iconXs,
                color: context.colors.primary,
              ),
              const SizedBox(width: TokensSpacing.xs),
              Flexible(
                child: Text(
                  l10n.plannerDeadlineFromReminder,
                  style: context.textStyles.labelMedium?.copyWith(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.xxs),
        ],
        Text(
          when,
          style: context.textStyles.labelLarge?.copyWith(
            color: missed || soon ? color : context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: TokensSpacing.xxs),
        Text(
          d.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: context.textStyles.titleMedium?.copyWith(
            decoration: d.completed ? TextDecoration.lineThrough : null,
            color: d.completed ? context.colors.onSurfaceVariant : null,
          ),
        ),
        const SizedBox(height: TokensSpacing.s),
        Wrap(
          spacing: TokensSpacing.s,
          runSpacing: TokensSpacing.xs,
          children: [
            AppPill(
              icon: d.type.icon,
              label: d.type.label(context),
              color: context.colors.tertiary,
            ),
            if (subject != null)
              AppPill(icon: Icons.school_outlined, label: subject),
            AppPill(
              icon: Icons.signal_cellular_alt_rounded,
              label: d.difficulty.label(context),
            ),
            if (d.imported)
              AppPill(
                icon: Icons.cloud_download_outlined,
                label: l10n.plannerImported,
              ),
          ],
        ),
      ],
    );
    // Mientras se guarda, el botón sigue (desactivado, con el progreso dentro)
    // para no perder el foco, como la casilla de la agenda de Inicio.
    final toggle = IconButton(
      focusNode: toggleFocus,
      tooltip: d.completed
          ? l10n.plannerUnmarkNamed(d.title)
          : l10n.plannerMarkDoneNamed(d.title),
      onPressed: busy ? null : onToggle,
      icon: busy
          ? const SizedBox.square(
              dimension: TokensSize.iconM,
              child: CircularProgressIndicator(
                strokeWidth: TokensSize.spinnerStroke,
              ),
            )
          : Icon(
              d.completed ? AppIcons.done : AppIcons.todo,
              color: d.completed
                  ? context.palette.success
                  : context.colors.onSurfaceVariant,
            ),
    );
    // «Eliminar» para el lector, en el mismo nodo que recibe el foco.
    final actions = busy
        ? null
        : {
            CustomSemanticsAction(
              label: l10n.plannerDeleteDeadlineNamed(d.title),
            ): onDelete,
          };
    final card = AppCard(
      padding: const EdgeInsets.all(TokensSpacing.xs),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = AppDateBlock.sideBySide(context, constraints.maxWidth);
          final block = AppDateBlock.due(
            context,
            due: d.dueAt,
            now: now,
            color: color,
            overdue: missed,
            compact: !side,
          );
          if (side) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppCardTapArea(
                    onTap: onEdit,
                    semanticHint: l10n.plannerEditDeadline,
                    semanticActions: actions,
                    padding: const EdgeInsets.all(TokensSpacing.s),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        block,
                        const SizedBox(width: TokensSpacing.m),
                        Expanded(child: content),
                      ],
                    ),
                  ),
                ),
                toggle,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCardTapArea(
                onTap: onEdit,
                semanticHint: l10n.plannerEditDeadline,
                semanticActions: actions,
                padding: const EdgeInsets.all(TokensSpacing.s),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    block,
                    const SizedBox(height: TokensSpacing.s),
                    content,
                  ],
                ),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [toggle]),
            ],
          );
        },
      ),
    );
    // Borde de color además de la marca con texto: no solo color (1.4.1).
    final framed = !highlighted
        ? card
        : DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: context.colors.primary,
                width: TokensSize.focusRing,
              ),
              borderRadius: BorderRadius.circular(TokensRadius.l),
            ),
            child: card,
          );
    return Dismissible(
      key: ValueKey('deadline-${d.id}'),
      direction: busy ? DismissDirection.none : DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: _DeleteBackground(label: l10n.plannerDeleteDeadline),
      child: framed,
    );
  }
}

/// Fondo que asoma al deslizar una entrega para borrarla: icono y verbo, no
/// solo color.
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.colors.errorContainer,
      borderRadius: BorderRadius.circular(TokensRadius.l),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: TokensSpacing.l),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label,
            style: context.textStyles.labelLarge?.copyWith(
              color: context.colors.onErrorContainer,
            ),
          ),
          const SizedBox(width: TokensSpacing.s),
          Icon(AppIcons.delete, color: context.colors.onErrorContainer),
        ],
      ),
    ),
  );
}
