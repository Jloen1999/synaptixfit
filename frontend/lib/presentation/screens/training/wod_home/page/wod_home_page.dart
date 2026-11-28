import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/wod.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../training_routes.dart';
import '../../widgets/training_section_bar.dart';
import '../../widgets/wod_labels.dart';
import '../bloc/wod_home_bloc.dart';
import 'wod_board_card.dart';
import 'wod_result_sheet.dart';

/// Apartado «WOD» de la pestaña Entreno (ADR 0069): «Añadir mi WOD», la
/// pizarra de hoy (mía o de ejemplo), «Empezar cronómetro» como única acción
/// principal, «Apuntar marca» sin cronómetro y «Mis marcas».
class WodHomePage extends StatelessWidget {
  const WodHomePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<WodHomeBloc>()..add(const WodHomeEvent.started()),
    child: const _WodHomeView(),
  );
}

class _WodHomeView extends StatelessWidget with ErrorsMessageMixin {
  const _WodHomeView();

  /// Tope de espera de «tirar para recargar» si el bloc no emite nada nuevo.
  static const _refreshWait = Duration(seconds: 10);

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<WodHomeBloc, WodHomeState>(
      listenWhen: (p, c) =>
          (c.saved != null && p.saved != c.saved) ||
          (c.actionError != null && p.actionError != c.actionError),
      listener: (context, state) {
        if (state.actionError case final error?) {
          context.showSnack(errorMessage(context, error));
        } else if (state.saved case final mark?) {
          context.showSnack(
            mark.best ? l10n.wodMarkSavedBest : l10n.wodMarkSaved,
          );
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppPageBar(
          title: Text(l10n.tabTraining),
          bottom: const TrainingSectionBar(current: TrainingSection.wod),
        ),
        body: switch (state.status) {
          WodHomeStatus.loading => const AppSkeletonList(
            height: TokensSize.skeletonCard,
          ),
          WodHomeStatus.failure => AppErrorView(
            error: state.error!,
            onRetry: () =>
                context.read<WodHomeBloc>().add(const WodHomeEvent.started()),
          ),
          WodHomeStatus.ready => RefreshIndicator(
            onRefresh: () async {
              final bloc = context.read<WodHomeBloc>()
                ..add(const WodHomeEvent.refreshed());
              await bloc.stream.first.timeout(
                _refreshWait,
                onTimeout: () => bloc.state,
              );
            },
            child: _Content(state: state),
          ),
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.state});

  final WodHomeState state;

  /// Abre una pantalla completa y vuelve a leer al volver (marca o WOD nuevo).
  Future<void> _open(
    BuildContext context,
    String location, {
    Object? extra,
  }) async {
    final bloc = context.read<WodHomeBloc>();
    await context.push<Object?>(location, extra: extra);
    if (!bloc.isClosed) bloc.add(const WodHomeEvent.refreshed());
  }

  Future<void> _logMark(BuildContext context, Wod wod) async {
    final bloc = context.read<WodHomeBloc>();
    final titled = WodLabels.titled(context.localizations, wod);
    final draft = await showWodResultSheet(
      context,
      wod: wod,
      division: state.division,
    );
    if (draft == null || bloc.isClosed) return;
    bloc.add(WodHomeEvent.resultSubmitted(titled, draft));
  }

  Future<void> _changeExample(BuildContext context) async {
    final bloc = context.read<WodHomeBloc>();
    final code = await showWodTemplateSheet(context, state.templates);
    if (code == null || bloc.isClosed) return;
    bloc.add(WodHomeEvent.templateChosen(code));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final board = state.board!;
    final wod = board.wod;
    return AppContentWidth(
      child: ListView(
        padding: const EdgeInsets.all(TokensSpacing.m),
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: () => _open(context, TrainingPaths.wodEditor),
              icon: const Icon(AppIcons.add),
              label: Text(l10n.wodAddMine),
            ),
          ),
          const SizedBox(height: TokensSpacing.m),
          WodBoardCard(
            board: board,
            division: state.division,
            onDivisionChanged: (d) => context.read<WodHomeBloc>().add(
              WodHomeEvent.divisionChanged(d),
            ),
            onEdit: () => _open(context, TrainingPaths.wodEditor, extra: wod),
            onChangeExample: board.example && state.templates.length > 1
                ? () => _changeExample(context)
                : null,
          ),
          const SizedBox(height: TokensSpacing.m),
          AppPrimaryButton(
            label: l10n.wodStartTimer,
            icon: AppIcons.focusTimer,
            onPressed: () => _open(
              context,
              TrainingPaths.wodLive,
              extra: (
                wod: WodLabels.titled(l10n, wod),
                division: state.division,
              ),
            ),
          ),
          const SizedBox(height: TokensSpacing.s),
          OutlinedButton(
            onPressed: state.saving ? null : () => _logMark(context, wod),
            child: Text(l10n.wodLogMark),
          ),
          const SizedBox(height: TokensSpacing.l),
          AppSectionHeader(title: l10n.wodMarksTitle),
          const SizedBox(height: TokensSpacing.s),
          if (state.marks.isEmpty)
            AppCard(
              child: AppEmptyState.compact(
                icon: AppIcons.finish,
                title: l10n.wodMarksEmptyTitle,
                message: l10n.wodMarksEmptyMessage,
                action: FilledButton.tonal(
                  onPressed: state.saving ? null : () => _logMark(context, wod),
                  child: Text(l10n.wodLogMark),
                ),
              ),
            )
          else
            for (final mark in state.marks)
              Padding(
                padding: const EdgeInsets.only(bottom: TokensSpacing.s),
                child: _MarkTile(mark: mark),
              ),
        ],
      ),
    );
  }
}

/// Una marca de «Mis marcas»: de qué WOD, cómo quedó, en qué división y
/// cuándo; la mejor lleva su pastilla (icono y texto, no solo color).
class _MarkTile extends StatelessWidget {
  const _MarkTile({required this.mark});

  final WodMark mark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final result = mark.result;
    final muted = context.textStyles.bodySmall?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    return Semantics(
      container: true,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mark.title ?? WodLabels.templateName(l10n, mark.templateCode),
              style: context.textStyles.titleSmall,
            ),
            const SizedBox(height: TokensSpacing.xxs),
            Text(
              l10n.wodMarkLine(
                WodLabels.score(l10n, result),
                WodLabels.division(l10n, result.division),
              ),
              style: context.textStyles.titleMedium,
            ),
            const SizedBox(height: TokensSpacing.xxs),
            Text(
              '${WodLabels.format(l10n, mark.format)} · '
              '${DateFormat.yMMMd(l10n.localeName).format(result.performedAt)}',
              style: muted,
            ),
            if (mark.best) ...[
              const SizedBox(height: TokensSpacing.xs),
              AppPill(label: l10n.wodMarkBest, icon: AppIcons.badge),
            ],
          ],
        ),
      ),
    );
  }
}

/// Hoja «Elige un WOD de ejemplo»: devuelve el código de la plantilla.
Future<String?> showWodTemplateSheet(
  BuildContext context,
  List<Wod> templates,
) {
  final l10n = context.localizations;
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheet) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: TokensSpacing.m),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TokensSpacing.l,
              0,
              TokensSpacing.l,
              TokensSpacing.s,
            ),
            child: Semantics(
              header: true,
              child: Text(
                l10n.wodTemplatesTitle,
                style: sheet.textStyles.titleLarge,
              ),
            ),
          ),
          for (final t in templates)
            AppFocusOutline(
              child: ListTile(
                title: Text(WodLabels.templateName(l10n, t.templateCode)),
                subtitle: Text(
                  [
                    WodLabels.headline(l10n, t),
                    t.movements
                        .map((m) => WodLabels.movementName(l10n, m))
                        .join(', '),
                  ].join(' · '),
                ),
                onTap: () => Navigator.of(sheet).pop(t.templateCode),
              ),
            ),
        ],
      ),
    ),
  );
}
