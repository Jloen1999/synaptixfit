import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/session_adaptation.dart';
import '../../../../../domain/models/training/today_adaptation.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../l10n/gen_l10n/app_localizations.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../health_consent/page/health_consent_sheet.dart';
import '../../training_routes.dart';
import '../bloc/quick_check_in_bloc.dart';

/// Tarjeta «¿Qué tal estás hoy?» de Rutinas: tres preguntas de un toque y,
/// después, cómo se adapta hoy el entreno y por qué («Hoy harás menos series
/// porque dormiste mal»). El registro completo sigue a un toque.
class QuickCheckInCard extends StatelessWidget {
  const QuickCheckInCard({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<QuickCheckInBloc>()..add(const QuickCheckInEvent.started()),
    child: const _QuickCheckInView(),
  );
}

class _QuickCheckInView extends StatelessWidget {
  const _QuickCheckInView();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<QuickCheckInBloc, QuickCheckInState>(
        builder: (context, state) {
          if (state.loading) {
            return const AppSkeletonGroup(
              child: AppSkeleton(height: TokensSize.guideSkeleton),
            );
          }
          return AppCard(
            child: AnimatedSize(
              duration: context.motion(TokensDuration.normal),
              alignment: Alignment.topCenter,
              child: state.asking
                  ? _Questions(state: state)
                  : _Explanation(
                      adaptation: state.adaptation!,
                      announce: state.justSent,
                    ),
            ),
          );
        },
      );
}

/// Las tres preguntas: cómo dormiste, la energía y las agujetas.
class _Questions extends StatefulWidget {
  const _Questions({required this.state});

  final QuickCheckInState state;

  @override
  State<_Questions> createState() => _QuestionsState();
}

class _QuestionsState extends State<_Questions> with ErrorsMessageMixin {
  int? _sleep;
  int? _energy;
  int? _soreness;

  @override
  void initState() {
    super.initState();
    // Al cambiar, se parte de lo que ya se contestó hoy.
    final answers = widget.state.adaptation?.todayAnswers;
    _sleep = answers?.sleepQuality;
    _energy = answers?.energy;
    _soreness = answers?.soreness;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final ready = _sleep != null && _energy != null && _soreness != null;
    // Escalas 1-5 del registro diario: bien/alta/nada son los extremos buenos.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: context.colors.secondaryContainer,
              child: Icon(
                Icons.mood_rounded,
                color: context.colors.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: TokensSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l10n.trainingQuickCheckInTitle,
                      style: context.textStyles.titleMedium,
                    ),
                  ),
                  Text(
                    l10n.trainingQuickCheckInHint,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: TokensSpacing.m),
        _Question(
          label: l10n.trainingQuickSleep,
          options: [
            (5, l10n.trainingQuickGood),
            (3, l10n.trainingQuickSoSo),
            (1, l10n.trainingQuickBad),
          ],
          value: _sleep,
          onChanged: (v) => setState(() => _sleep = v),
        ),
        _Question(
          label: l10n.trainingQuickEnergy,
          options: [
            (5, l10n.trainingQuickHigh),
            (3, l10n.trainingQuickMid),
            (1, l10n.trainingQuickLow),
          ],
          value: _energy,
          onChanged: (v) => setState(() => _energy = v),
        ),
        _Question(
          label: l10n.trainingQuickSoreness,
          options: [
            (1, l10n.trainingQuickSoreNone),
            (3, l10n.trainingQuickSoreSome),
            (5, l10n.trainingQuickSoreLot),
          ],
          value: _soreness,
          onChanged: (v) => setState(() => _soreness = v),
        ),
        if (widget.state.error case final error?) ...[
          AppInlineMessage(message: errorMessage(context, error)),
          const SizedBox(height: TokensSpacing.s),
        ],
        AppPrimaryButton(
          label: l10n.trainingQuickSave,
          icon: Icons.check_rounded,
          loading: widget.state.sending,
          onPressed: ready
              ? () async {
                  final bloc = context.read<QuickCheckInBloc>();
                  final input = QuickCheckIn(
                    sleepQuality: _sleep!,
                    energy: _energy!,
                    soreness: _soreness!,
                  );
                  // Datos de salud: antes, el permiso expreso (ADR 0034).
                  if (await ensureHealthConsent(context)) {
                    bloc.add(QuickCheckInEvent.submitted(input));
                  }
                }
              : null,
        ),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: TokensSpacing.s,
          children: [
            if (widget.state.editing)
              TextButton(
                onPressed: () => context.read<QuickCheckInBloc>().add(
                  const QuickCheckInEvent.editCancelled(),
                ),
                child: Text(l10n.commonCancel),
              ),
            TextButton(
              onPressed: () => context.push<void>(TrainingPaths.checkIn),
              child: Text(l10n.trainingQuickFull),
            ),
          ],
        ),
      ],
    );
  }
}

class _Question extends StatelessWidget {
  const _Question({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<(int, String)> options;
  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: TokensSpacing.m),
    child: Semantics(
      container: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Text(label, style: context.textStyles.titleSmall),
          ),
          const SizedBox(height: TokensSpacing.xs),
          Wrap(
            spacing: TokensSpacing.s,
            runSpacing: TokensSpacing.s,
            children: [
              for (final (score, text) in options)
                ChoiceChip(
                  label: Text(text),
                  selected: value == score,
                  onSelected: (_) => onChanged(score),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Después de registrar: entreno normal o cuánto se recorta y por qué.
class _Explanation extends StatelessWidget {
  const _Explanation({required this.adaptation, required this.announce});

  final TodayAdaptation adaptation;

  /// Anunciar al lector (solo justo después de enviar).
  final bool announce;

  /// Sin causa del servidor no se inventa una: frase neutra.
  static String _fatigueReason(AppLocalizations l10n, FatigueCause? cause) =>
      switch (cause) {
        null => l10n.trainingQuickReasonFatigueGeneric,
        FatigueCause.poorSleep => l10n.trainingQuickReasonFatigue(
          l10n.trainingQuickCauseSleep,
        ),
        FatigueCause.stress => l10n.trainingQuickReasonFatigue(
          l10n.trainingQuickCauseStress,
        ),
        FatigueCause.lowEnergy => l10n.trainingQuickReasonFatigue(
          l10n.trainingQuickCauseEnergy,
        ),
        FatigueCause.soreness => l10n.trainingQuickReasonFatigue(
          l10n.trainingQuickCauseSoreness,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final adapted = adaptation.adapted;
    final color = adapted ? context.palette.warning : context.palette.success;
    return Semantics(
      liveRegion: announce,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                adapted ? Icons.tune_rounded : Icons.check_circle_rounded,
                color: color,
              ),
              const SizedBox(width: TokensSpacing.s),
              Expanded(
                child: Text(
                  adapted
                      ? l10n.trainingQuickAdapted(
                          (adaptation.volumeFactor * 100).round(),
                        )
                      : l10n.trainingQuickAllGood,
                  style: context.textStyles.titleSmall,
                ),
              ),
            ],
          ),
          for (final reason in adaptation.reasons) ...[
            const SizedBox(height: TokensSpacing.xs),
            Text(switch (reason) {
              SessionAdaptationReason.highFatigue => _fatigueReason(
                l10n,
                adaptation.fatigueCause,
              ),
              SessionAdaptationReason.examSoon => l10n.trainingQuickReasonExam,
              SessionAdaptationReason.overtraining =>
                l10n.trainingQuickReasonOvertraining,
              SessionAdaptationReason.cycleDiscomfort =>
                l10n.trainingQuickReasonCycle,
            }, style: context.textStyles.bodyMedium),
          ],
          Wrap(
            alignment: WrapAlignment.end,
            spacing: TokensSpacing.s,
            children: [
              TextButton(
                onPressed: () => context.push<void>(TrainingPaths.checkIn),
                child: Text(l10n.trainingQuickFull),
              ),
              TextButton.icon(
                onPressed: () => context.read<QuickCheckInBloc>().add(
                  const QuickCheckInEvent.editRequested(),
                ),
                icon: const Icon(Icons.edit_rounded),
                label: Text(l10n.trainingQuickChange),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
