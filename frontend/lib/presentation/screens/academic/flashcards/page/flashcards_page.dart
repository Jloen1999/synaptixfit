import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/academic/quiz.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/academic_widgets.dart';
import '../../widgets/result_summary.dart';
import '../bloc/flashcards_bloc.dart';

/// Tarjetas de estudio: pregunta → respuesta → dominada, dudosa o fallada.
class FlashcardsPage extends StatelessWidget {
  const FlashcardsPage({super.key, required this.materialId});

  final String materialId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<FlashcardsBloc>()..add(FlashcardsEvent.started(materialId)),
    child: const _FlashcardsView(),
  );
}

class _FlashcardsView extends StatelessWidget with ErrorsMessageMixin {
  const _FlashcardsView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<FlashcardsBloc, FlashcardsState>(
      listenWhen: (a, b) =>
          a.actionError != b.actionError ||
          a.updatedAccount != b.updatedAccount ||
          a.ankiExports != b.ankiExports,
      listener: (context, state) {
        if (state.ankiExports > 0) {
          context.showSnack(l10n.academicFlashcardsAnkiExported);
        }
        if (state.updatedAccount != null) {
          syncSessionAccount(context, state.updatedAccount!);
        }
        if (state.actionError != null) {
          context.showSnack(errorMessage(context, state.actionError!));
        }
      },
      builder: (context, state) {
        final bloc = context.read<FlashcardsBloc>();
        return Scaffold(
          appBar: AppPageBar.reading(
            title: Text(l10n.academicFlashcardsTitle),
            actions: [
              if (state.cards.isNotEmpty)
                IconButton(
                  tooltip: l10n.academicFlashcardsExportAnki,
                  icon: const Icon(AppIcons.export),
                  onPressed: state.exportingAnki
                      ? null
                      : () => bloc.add(
                          FlashcardsEvent.ankiExportRequested(
                            l10n.academicFlashcardsAnkiDeck,
                          ),
                        ),
                ),
            ],
            bottom: state.cards.isEmpty || state.finished
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(4),
                    child: LinearProgressIndicator(
                      value: state.index / state.cards.length,
                    ),
                  ),
          ),
          body: switch (state) {
            FlashcardsState(loading: true) => const AppLoadingView(),
            FlashcardsState(:final error?) => AppErrorView(
              error: error,
              onRetry: () => context.pop(),
            ),
            FlashcardsState(finished: true) => _Finished(state: state),
            _ => AcademicBody(
              maxWidth: TokensLayout.readingMaxWidth,
              child: Padding(
                padding: const EdgeInsets.all(TokensSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.academicQuestionOf(
                        state.index + 1,
                        state.cards.length,
                      ),
                      textAlign: TextAlign.center,
                      style: context.textStyles.labelLarge,
                    ),
                    const SizedBox(height: TokensSpacing.m),
                    Expanded(
                      child: _CardFace(
                        card: state.current!,
                        flipped: state.flipped,
                        onTap: () => bloc.add(const FlashcardsEvent.flipped()),
                      ),
                    ),
                    const SizedBox(height: TokensSpacing.m),
                    if (!state.flipped)
                      AppPrimaryButton(
                        label: l10n.academicFlashcardsShowAnswer,
                        icon: Icons.flip_rounded,
                        onPressed: () =>
                            bloc.add(const FlashcardsEvent.flipped()),
                      )
                    else
                      Row(
                        children: [
                          for (final rating in FlashcardRating.values) ...[
                            if (rating != FlashcardRating.mastered)
                              const SizedBox(width: TokensSpacing.s),
                            Expanded(child: _RateButton(rating: rating)),
                          ],
                        ],
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

(String, Color, IconData) _ratingStyle(
  BuildContext context,
  FlashcardRating r,
) {
  final l10n = context.localizations;
  return switch (r) {
    FlashcardRating.mastered => (
      l10n.academicFlashcardsMastered,
      context.palette.success,
      Icons.check_circle_rounded,
    ),
    FlashcardRating.doubtful => (
      l10n.academicFlashcardsDoubtful,
      context.palette.warning,
      Icons.help_rounded,
    ),
    FlashcardRating.failed => (
      l10n.academicFlashcardsFailed,
      context.colors.error,
      Icons.cancel_rounded,
    ),
  };
}

class _RateButton extends StatelessWidget {
  const _RateButton({required this.rating});

  final FlashcardRating rating;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = _ratingStyle(context, rating);
    return OutlinedButton.icon(
      style:
          OutlinedButton.styleFrom(
            foregroundColor: color,
            minimumSize: const Size.fromHeight(48),
          ).copyWith(
            // Borde del color de la valoración; con foco de teclado, el mismo
            // anillo exterior que el resto de botones del tema.
            side: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? BorderSide(
                      color: context.colors.onSurface,
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignOutside,
                    )
                  : BorderSide(color: color),
            ),
          ),
      onPressed: () =>
          context.read<FlashcardsBloc>().add(FlashcardsEvent.rated(rating)),
      icon: Icon(icon),
      label: Text(label, overflow: TextOverflow.ellipsis),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.card,
    required this.flipped,
    required this.onTap,
  });

  final Question card;
  final bool flipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Semantics(
      button: true,
      label: flipped
          ? l10n.academicFlashcardsAnswer
          : l10n.academicFlashcardsQuestion,
      child: AnimatedSwitcher(
        duration: context.motion(TokensDuration.normal),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: AppCard(
          key: ValueKey(flipped),
          onTap: onTap,
          color: flipped
              ? context.colors.tertiaryContainer.withValues(alpha: 0.5)
              : null,
          padding: const EdgeInsets.all(TokensSpacing.l),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    flipped
                        ? l10n.academicFlashcardsAnswer
                        : l10n.academicFlashcardsQuestion,
                    style: context.textStyles.labelLarge?.copyWith(
                      color: context.colors.tertiary,
                    ),
                  ),
                  const SizedBox(height: TokensSpacing.m),
                  Text(
                    flipped ? card.correctAnswer : card.statement,
                    textAlign: TextAlign.center,
                    style: context.textStyles.headlineSmall,
                  ),
                  if (flipped &&
                      card.explanation != null &&
                      card.explanation!.isNotEmpty) ...[
                    const SizedBox(height: TokensSpacing.m),
                    Text(
                      card.explanation!,
                      textAlign: TextAlign.center,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (!flipped) ...[
                    const SizedBox(height: TokensSpacing.l),
                    Text(
                      l10n.academicFlashcardsTapHint,
                      style: context.textStyles.labelSmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Finished extends StatelessWidget {
  const _Finished({required this.state});

  final FlashcardsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<FlashcardsBloc>();
    if (state.submitting) return const AppLoadingView();
    return AcademicBody(
      child: ListView(
        padding: const EdgeInsets.all(TokensSpacing.l),
        children: [
          ResultSummary(
            title: l10n.academicFlashcardsDone,
            correct: state.count(FlashcardRating.mastered),
            total: state.cards.length,
            xp: state.result?.xpAwarded ?? 0,
            extra: Wrap(
              spacing: TokensSpacing.s,
              runSpacing: TokensSpacing.s,
              alignment: WrapAlignment.center,
              children: [
                for (final rating in FlashcardRating.values)
                  Builder(
                    builder: (context) {
                      final (label, color, icon) = _ratingStyle(
                        context,
                        rating,
                      );
                      return AppPill(
                        label: '$label · ${state.count(rating)}',
                        color: color,
                        icon: icon,
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: TokensSpacing.xl),
          if (state.result == null)
            AppPrimaryButton(
              label: l10n.commonRetry,
              onPressed: () => bloc.add(const FlashcardsEvent.submitRetried()),
            )
          else ...[
            AppPrimaryButton(
              label: l10n.academicFlashcardsAgain,
              icon: Icons.replay_rounded,
              onPressed: () => bloc.add(const FlashcardsEvent.restarted()),
            ),
            const SizedBox(height: TokensSpacing.s),
            AppSecondaryButton(
              label: l10n.commonBack,
              onPressed: () => context.pop(true),
            ),
          ],
        ],
      ),
    );
  }
}
