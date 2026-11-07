import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/study_source_type.dart';
import '../../../../../domain/models/academic/study_material.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_visuals.dart';
import '../../widgets/academic_widgets.dart';
import '../bloc/material_review_bloc.dart';

/// Repaso espaciado de un material con autoevaluación de 6 niveles.
class MaterialReviewPage extends StatelessWidget {
  const MaterialReviewPage({
    super.key,
    required this.materialId,
    this.queue = const [],
  });

  final String materialId;

  /// Materiales que se repasan después, seguidos («Repasar todos» de Inicio).
  final List<String> queue;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<MaterialReviewBloc>()
          ..add(MaterialReviewEvent.started(materialId)),
    child: _MaterialReviewView(queue: queue),
  );
}

/// Abre el siguiente repaso de la cola en lugar del actual (Atrás vuelve a
/// donde empezó la tanda, no a cada repaso hecho).
void _openNext(BuildContext context, List<String> queue) =>
    context.pushReplacement(
      '/academic/materials/${queue.first}/review'
      '${queue.length > 1 ? '?queue=${queue.skip(1).join(',')}' : ''}',
    );

class _MaterialReviewView extends StatelessWidget with ErrorsMessageMixin {
  const _MaterialReviewView({required this.queue});

  final List<String> queue;

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = context.localizations;
    final bloc = context.read<MaterialReviewBloc>();
    final ok = await confirmDestructive(
      context,
      title: l10n.academicMaterialRemoveTitle,
      message: l10n.academicMaterialRemoveMessage,
      confirmLabel: l10n.academicMaterialRemove,
    );
    if (ok) bloc.add(const MaterialReviewEvent.removeRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocListener<MaterialReviewBloc, MaterialReviewState>(
      // Paso 1 hecho dentro de la pantalla (no al abrirla ya practicado): las
      // respuestas se desbloquean sin mover el foco, así que se anuncia.
      listenWhen: (a, b) =>
          !a.loading && a.material != null && !a.reviewed && b.reviewed,
      listener: (context, _) => unawaited(
        SemanticsService.sendAnnouncement(
          View.of(context),
          l10n.academicReviewStep1Announce,
          Directionality.of(context),
        ),
      ),
      child: _content(context),
    );
  }

  Widget _content(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<MaterialReviewBloc, MaterialReviewState>(
      listenWhen: (a, b) =>
          a.actionError != b.actionError ||
          a.updatedAccount != b.updatedAccount ||
          a.removed != b.removed,
      listener: (context, state) {
        if (state.removed) {
          context.showSnack(l10n.academicMaterialRemoved);
          if (queue.isNotEmpty) {
            _openNext(context, queue);
          } else {
            context.pop(true);
          }
          return;
        }
        if (state.updatedAccount != null) {
          syncSessionAccount(context, state.updatedAccount!);
        }
        if (state.actionError != null) {
          context.showSnack(errorMessage(context, state.actionError!));
        }
      },
      builder: (context, state) {
        final material = state.material;
        return Scaffold(
          appBar: AppPageBar(
            title: Text(l10n.academicReviewTitle),
            actions: [
              if (material != null)
                IconButton(
                  tooltip: l10n.academicMaterialRemove,
                  icon: const Icon(AppIcons.remove),
                  onPressed: state.removing
                      ? null
                      : () => _confirmDelete(context),
                ),
            ],
            bottom: state.removing
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(TokensSize.progressBar),
                    child: LinearProgressIndicator(),
                  )
                : null,
          ),
          body: switch (state) {
            MaterialReviewState(loading: true) => const AppSkeletonList(
              count: 5,
              height: 88,
            ),
            MaterialReviewState(:final error?) => AppErrorView(
              error: error,
              onRetry: () => context.read<MaterialReviewBloc>().add(
                MaterialReviewEvent.started(state.materialId),
              ),
            ),
            _ => AcademicBody(
              child: ListView(
                padding: const EdgeInsets.all(TokensSpacing.m),
                children: [
                  _MaterialHeader(material: material!),
                  const SizedBox(height: TokensSpacing.l),
                  if (state.outcome != null)
                    _OutcomeCard(
                      material: state.outcome!.material,
                      xpAwarded: state.outcome!.xpAwarded,
                      queue: queue,
                    )
                  else ...[
                    // Paso 1: repasar. Valorar sin haber repasado no dice
                    // cuánto se recuerda.
                    _PrepareStep(material: material, state: state),
                    const SizedBox(height: TokensSpacing.m),
                    _StepTitle(
                      number: 2,
                      state: state.reviewed
                          ? AppStepState.active
                          : AppStepState.locked,
                      title: l10n.academicReviewQuestion,
                    ),
                    const SizedBox(height: TokensSpacing.xs),
                    if (!state.reviewed)
                      Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: TokensSize.iconXs,
                            color: context.colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: TokensSpacing.xs),
                          Expanded(
                            child: Text(
                              l10n.academicReviewLocked,
                              style: context.textStyles.bodyMedium?.copyWith(
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (state.preview?.practice case final p?)
                      Text(
                        l10n.academicReviewSuggested(
                          p.correct,
                          p.answered,
                          context.qualityLabel(p.suggestedQuality),
                        ),
                        style: context.textStyles.bodyMedium,
                      ),
                    if (state.preview?.sameIntervalForAll ?? false) ...[
                      const SizedBox(height: TokensSpacing.xs),
                      Text(
                        l10n.academicReviewSameInterval,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: TokensSpacing.xs),
                    if (state.preview != null)
                      _FatigueInfo(preview: state.preview!),
                    const SizedBox(height: TokensSpacing.s),
                    if (state.submitting) const LinearProgressIndicator(),
                    // Una sola tarjeta con las opciones en filas: se elige de
                    // un vistazo sin seis tarjetas apiladas. Bloqueadas (y
                    // atenuadas por la propia fila) hasta repasar.
                    if (state.preview?.options.isNotEmpty ?? false)
                      AppCard(
                        padding: const EdgeInsets.symmetric(
                          vertical: TokensSpacing.xs,
                        ),
                        child: Column(
                          children: [
                            for (final option in state.preview!.options)
                              _QualityOption(
                                option: option,
                                selected:
                                    state.selectedQuality == option.quality,
                                enabled: state.reviewed && !state.submitting,
                                onTap: () =>
                                    context.read<MaterialReviewBloc>().add(
                                      MaterialReviewEvent.qualitySelected(
                                        option.quality,
                                      ),
                                    ),
                              ),
                          ],
                        ),
                      )
                    else
                      AppEmptyState.compact(
                        icon: Icons.cloud_off_rounded,
                        title: l10n.academicReviewNoOptions,
                        action: AppSecondaryButton(
                          label: l10n.commonRetry,
                          icon: const Icon(AppIcons.refresh),
                          onPressed: () =>
                              context.read<MaterialReviewBloc>().add(
                                MaterialReviewEvent.started(state.materialId),
                              ),
                        ),
                      ),
                  ],
                  const SizedBox(height: TokensSpacing.l),
                  AppSectionHeader(title: l10n.academicReviewHistory),
                  if (state.history.isEmpty)
                    Text(
                      l10n.academicReviewHistoryEmpty,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    )
                  else
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final r in state.history)
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    context.colors.tertiaryContainer,
                                child: Text(
                                  '${r.realQuality}',
                                  style: context.textStyles.labelLarge
                                      ?.copyWith(
                                        color:
                                            context.colors.onTertiaryContainer,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              title: Text(context.qualityLabel(r.realQuality)),
                              subtitle: Text(dateTime(r.reviewedAt)),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: TokensSpacing.xl),
                ],
              ),
            ),
          },
          bottomNavigationBar:
              material == null || state.loading || state.outcome != null
              ? null
              : _SaveBar(state: state),
        );
      },
    );
  }
}

/// Botón de guardar abajo, al alcance del pulgar: dice qué falta («Primero
/// repásalo», «Elige cómo te fue») hasta que se puede guardar.
class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.state});

  final MaterialReviewState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final quality = state.selectedQuality;
    final label = !state.reviewed
        ? l10n.academicReviewDoFirst
        : quality == null
        ? l10n.academicReviewChooseFirst
        : l10n.academicReviewSave;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        border: Border(top: BorderSide(color: context.colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(TokensSpacing.m),
          child: AppPrimaryButton(
            label: label,
            icon: Icons.check_rounded,
            loading: state.submitting,
            onPressed: !state.reviewed || quality == null || state.submitting
                ? null
                : () => context.read<MaterialReviewBloc>().add(
                    MaterialReviewEvent.qualitySubmitted(quality),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Título numerado de cada paso: activo, bloqueado (neutro) o hecho (con una
/// marca de verificación).
class _StepTitle extends StatelessWidget {
  const _StepTitle({
    required this.number,
    required this.state,
    required this.title,
  });

  final int number;
  final AppStepState state;
  final String title;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Row(
      children: [
        AppStepBadge(number: number, state: state),
        const SizedBox(width: TokensSpacing.s),
        Expanded(child: Text(title, style: context.textStyles.titleMedium)),
      ],
    ),
  );
}

/// Paso 1: practicar con preguntas (recomendado), recordarlo sin mirar o
/// abrir el material. Cualquiera de los tres desbloquea la valoración.
class _PrepareStep extends StatelessWidget {
  const _PrepareStep({required this.material, required this.state});

  final StudyMaterial material;
  final MaterialReviewState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<MaterialReviewBloc>();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepTitle(
            number: 1,
            state: state.reviewed ? AppStepState.done : AppStepState.active,
            title: state.reviewed
                ? l10n.academicReviewStep1Done
                : l10n.academicReviewStep1,
          ),
          const SizedBox(height: TokensSpacing.s),
          AppPrimaryButton(
            label: l10n.academicReviewPractice,
            icon: Icons.quiz_rounded,
            onPressed: () async {
              await context.push<void>(AcademicPaths.practice(material.id));
              bloc.add(const MaterialReviewEvent.practiceReturned());
            },
          ),
          const SizedBox(height: TokensSpacing.xxs),
          Text(
            l10n.academicReviewPracticeHint,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TokensSpacing.s),
          Wrap(
            spacing: TokensSpacing.s,
            runSpacing: TokensSpacing.xs,
            children: [
              AppSecondaryButton(
                label: l10n.academicReviewRecall,
                onPressed: () => bloc.add(const MaterialReviewEvent.prepared()),
              ),
              AppSecondaryButton(
                label: l10n.academicReviewOpenSource,
                onPressed: () async {
                  await context.push<void>(
                    material.originType == StudySourceType.note
                        ? AcademicPaths.note(material.originId)
                        : AcademicPaths.file(material.originId),
                  );
                  bloc.add(const MaterialReviewEvent.prepared());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Cabecera del material: título, dominio y próximo repaso (practicar y abrir
/// el material están en el paso 1). Intervalo y número de repasos se omiten:
/// el historial de abajo ya los cuenta.
class _MaterialHeader extends StatelessWidget {
  const _MaterialHeader({required this.material});

  final StudyMaterial material;

  /// Tocaba antes de hoy (lo de hoy no va con retraso).
  static bool _overdue(DateTime next) {
    final now = DateTime.now();
    return next.toLocal().isBefore(DateTime(now.year, now.month, now.day));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  material.title,
                  style: context.textStyles.titleLarge,
                ),
              ),
              AppPill(
                label: context.masteryLabel(material.masteryState),
                color: context.masteryColor(material.masteryState),
              ),
            ],
          ),
          if (material.nextReviewAt case final next?) ...[
            const SizedBox(height: TokensSpacing.xs),
            if (_overdue(next))
              // Tocaba un día anterior: aviso con icono y texto, no solo color.
              Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: TokensSize.iconXs,
                    color: context.palette.warning,
                  ),
                  const SizedBox(width: TokensSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.academicReviewOverdue(shortDate(next)),
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.palette.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              )
            else
              Text(
                l10n.academicNextReview(shortDate(next)),
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _FatigueInfo extends StatelessWidget {
  const _FatigueInfo({required this.preview});

  final ReviewPreview preview;

  @override
  Widget build(BuildContext context) {
    final ratio = preview.maxDailyLoad <= 0
        ? 0.0
        : preview.loadToday / preview.maxDailyLoad;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.localizations.academicReviewFatigue((ratio * 100).round()),
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: TokensSpacing.xs),
        AcademicProgressBar(
          value: ratio,
          color: ratio > 0.8 ? context.palette.warning : context.palette.study,
        ),
      ],
    );
  }
}

/// Fila de una respuesta: nota, cómo la recordaste y cuándo vuelve el repaso.
class _QualityOption extends StatelessWidget {
  const _QualityOption({
    required this.option,
    required this.enabled,
    required this.selected,
    required this.onTap,
  });

  final ReviewOption option;
  final bool enabled;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final color = option.quality >= 3
        ? context.palette.success
        : option.quality == 2
        ? context.palette.warning
        : context.colors.error;
    // Bloqueada: la fila ya se atenúa sola; el círculo pasa a neutro (no se
    // atenúa dos veces). Tinte opaco sobre la superficie: la cifra mantiene
    // su contraste también en la fila elegida.
    final circle = enabled
        ? Color.alphaBlend(
            color.withValues(alpha: AppPill.tintAlpha),
            context.colors.surface,
          )
        : context.colors.surfaceContainerHigh;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: AppFocusOutline(
        child: ListTile(
          enabled: enabled,
          selected: selected,
          selectedTileColor: context.colors.primaryContainer,
          selectedColor: context.colors.onPrimaryContainer,
          // La elegida se distingue también por el borde y la marca (no solo
          // por el fondo, que apenas contrasta con la tarjeta).
          shape: selected
              ? RoundedRectangleBorder(
                  side: BorderSide(
                    color: context.colors.primary,
                    width: TokensSize.focusRing,
                  ),
                  borderRadius: BorderRadius.circular(TokensRadius.m),
                )
              : null,
          onTap: onTap,
          minTileHeight: TokensSize.listTileMin,
          leading: CircleAvatar(
            backgroundColor: circle,
            child: Text(
              '${option.quality}',
              style: context.textStyles.labelLarge?.copyWith(
                color: enabled ? color : context.colors.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          title: Text(context.qualityLabel(option.quality)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.academicReviewInDays(option.intervalDays),
                style: context.textStyles.labelMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: TokensSpacing.xs),
                Icon(
                  Icons.check_circle_rounded,
                  color: context.colors.primary,
                  size: TokensSize.iconS,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({
    required this.material,
    required this.xpAwarded,
    required this.queue,
  });

  final StudyMaterial material;
  final int xpAwarded;

  /// Repasos que quedan en la tanda: si hay, el botón principal es «Siguiente».
  final List<String> queue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    // Región viva: al guardar, el lector anuncia «Repaso guardado» y cuándo toca
    // el siguiente (las opciones desaparecen y el foco no se mueve solo).
    return Semantics(
      container: true,
      liveRegion: true,
      child: AppCard(
        color: context.palette.success.withValues(alpha: AppPill.tintAlpha),
        padding: const EdgeInsets.all(TokensSpacing.l),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: context.palette.success,
              size: TokensSize.iconL,
            ),
            const SizedBox(height: TokensSpacing.s),
            Text(
              l10n.academicReviewDone,
              style: context.textStyles.titleMedium,
            ),
            const SizedBox(height: TokensSpacing.xs),
            Text(
              material.nextReviewAt == null
                  ? l10n.academicReviewInterval(material.intervalDays)
                  : l10n.academicNextReview(longDate(material.nextReviewAt!)),
              textAlign: TextAlign.center,
            ),
            if (xpAwarded > 0) ...[
              const SizedBox(height: TokensSpacing.m),
              AppPill(
                label: l10n.academicXpEarned(xpAwarded),
                color: context.palette.accent,
                icon: Icons.bolt_rounded,
              ),
            ],
            const SizedBox(height: TokensSpacing.m),
            if (queue.isNotEmpty) ...[
              AppPrimaryButton(
                label: l10n.academicReviewNext(queue.length),
                icon: Icons.skip_next_rounded,
                onPressed: () => _openNext(context, queue),
              ),
              const SizedBox(height: TokensSpacing.s),
              TextButton(
                onPressed: () => context.pop(true),
                child: Text(l10n.academicReviewStopQueue),
              ),
            ] else
              AppSecondaryButton(
                label: l10n.commonBack,
                onPressed: () => context.pop(true),
              ),
          ],
        ),
      ),
    );
  }
}
