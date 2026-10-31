import 'package:flutter/material.dart';
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

  /// Confirmación breve antes de guardar: el servidor no permite deshacer un
  /// repaso, así que un toque accidental no debe registrarlo. La fila ya dice
  /// cuándo vuelve el repaso; el diálogo solo repite la opción elegida.
  Future<void> _confirm(BuildContext context, ReviewOption option) async {
    final l10n = context.localizations;
    final bloc = context.read<MaterialReviewBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.qualityLabel(option.quality)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            autofocus: true,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      bloc.add(MaterialReviewEvent.qualitySubmitted(option.quality));
    }
  }

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
                  icon: const Icon(Icons.bookmark_remove_outlined),
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
                    Text(
                      l10n.academicReviewQuestion,
                      style: context.textStyles.titleMedium,
                    ),
                    const SizedBox(height: TokensSpacing.xs),
                    if (state.preview != null)
                      _FatigueInfo(preview: state.preview!),
                    const SizedBox(height: TokensSpacing.s),
                    if (state.submitting) const LinearProgressIndicator(),
                    // Una sola tarjeta con las opciones en filas: se elige de
                    // un vistazo sin seis tarjetas apiladas.
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                        vertical: TokensSpacing.xs,
                      ),
                      child: Column(
                        children: [
                          for (final option
                              in state.preview?.options ??
                                  const <ReviewOption>[])
                            _QualityOption(
                              option: option,
                              enabled: !state.submitting,
                              onTap: () => _confirm(context, option),
                            ),
                        ],
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
        );
      },
    );
  }
}

/// Cabecera del material: título, dominio, próximo repaso y dos enlaces
/// (abrir el material y practicar). Intervalo y número de repasos se omiten:
/// el historial de abajo ya los cuenta.
class _MaterialHeader extends StatelessWidget {
  const _MaterialHeader({required this.material});

  final StudyMaterial material;

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
          if (material.nextReviewAt != null) ...[
            const SizedBox(height: TokensSpacing.xs),
            Text(
              l10n.academicNextReview(shortDate(material.nextReviewAt!)),
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: TokensSpacing.xs),
          // Enlaces de texto sin icono: pesan menos que dos botones y
          // conservan el área táctil de 48 dp del tema.
          Wrap(
            spacing: TokensSpacing.xs,
            children: [
              TextButton(
                onPressed: () => context.push(
                  material.originType == StudySourceType.note
                      ? AcademicPaths.note(material.originId)
                      : AcademicPaths.file(material.originId),
                ),
                child: Text(l10n.academicReviewOpenSource),
              ),
              TextButton(
                onPressed: () =>
                    context.push(AcademicPaths.practice(material.id)),
                child: Text(l10n.academicActionPractice),
              ),
            ],
          ),
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
    required this.onTap,
  });

  final ReviewOption option;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final color = option.quality >= 3
        ? context.palette.success
        : option.quality == 2
        ? context.palette.warning
        : context.colors.error;
    return AppFocusOutline(
      child: ListTile(
        enabled: enabled,
        onTap: onTap,
        minTileHeight: TokensSize.listTileMin,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: AppPill.tintAlpha),
          child: Text(
            '${option.quality}',
            style: context.textStyles.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(context.qualityLabel(option.quality)),
        trailing: Text(
          l10n.academicReviewInDays(option.intervalDays),
          style: context.textStyles.labelMedium?.copyWith(
            color: context.colors.onSurfaceVariant,
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
