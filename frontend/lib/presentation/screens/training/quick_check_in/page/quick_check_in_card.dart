import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/check_in_answers.dart';
import '../../../../../domain/models/training/session_adaptation.dart';
import '../../../../../domain/models/training/today_adaptation.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../l10n/gen_l10n/app_localizations.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../health_consent/page/health_consent_sheet.dart';
import '../../training_routes.dart';
import '../../widgets/check_in_questions.dart';
import '../bloc/quick_check_in_bloc.dart';

/// «¿Qué tal estás hoy?» en Entreno › Gimnasio: el único registro diario
/// (ADR 0039). Plegado en una línea mientras no se contesta, para no ocupar
/// la pantalla; al abrirlo, tres preguntas de un toque y se guarda solo con la
/// tercera. Después dice cómo se adapta hoy el entreno y por qué («Hoy harás
/// menos series porque dormiste mal»). «Añadir detalles» (estrés, dolores,
/// notas) abre la pantalla del registro.
class QuickCheckInCard extends StatelessWidget {
  const QuickCheckInCard({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<QuickCheckInBloc>()..add(const QuickCheckInEvent.started()),
    child: const _QuickCheckInView(),
  );
}

class _QuickCheckInView extends StatefulWidget {
  const _QuickCheckInView();

  @override
  State<_QuickCheckInView> createState() => _QuickCheckInViewState();
}

class _QuickCheckInViewState extends State<_QuickCheckInView> {
  final _headerFocus = FocusNode(debugLabel: 'check-in-header');

  @override
  void dispose() {
    _headerFocus.dispose();
    super.dispose();
  }

  /// Preguntas desplegadas (de entrada, plegadas en una línea).
  bool _open = false;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<QuickCheckInBloc, QuickCheckInState>(
        builder: (context, state) {
          if (state.loading) {
            return const AppSkeletonGroup(
              child: AppSkeleton(height: TokensSize.skeletonRow),
            );
          }
          final open = _open || state.editing;
          return AppCard(
            padding: EdgeInsets.zero,
            child: AnimatedSize(
              duration: context.motion(TokensDuration.normal),
              alignment: Alignment.topCenter,
              child: !state.asking
                  ? Padding(
                      padding: const EdgeInsets.all(TokensSpacing.m),
                      child: _Explanation(
                        adaptation: state.adaptation!,
                        announce: state.justSent,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // La fila sigue ahí al abrir: pliega y despliega, y
                        // el foco no se pierde.
                        _Header(
                          focusNode: _headerFocus,
                          open: open,
                          onToggle: state.editing
                              ? null
                              : () => setState(() => _open = !_open),
                          // Plegada y sin contestar: las caras responden ya
                          // la energía y abren las otras dos (ADR 0055).
                          onFace: open || state.answers.values.isNotEmpty
                              ? null
                              : (value) {
                                  context.read<QuickCheckInBloc>().add(
                                    QuickCheckInEvent.answered(
                                      CheckInQuestion.energy,
                                      value,
                                    ),
                                  );
                                  setState(() => _open = true);
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (mounted) _headerFocus.requestFocus();
                                  });
                                },
                        ),
                        if (open)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              TokensSpacing.m,
                              0,
                              TokensSpacing.m,
                              TokensSpacing.m,
                            ),
                            child: _Questions(state: state),
                          ),
                      ],
                    ),
            ),
          );
        },
      );
}

/// Fila «¿Qué tal estás hoy?» que pliega y despliega las preguntas.
class _Header extends StatelessWidget {
  const _Header({
    required this.open,
    required this.onToggle,
    required this.focusNode,
    this.onFace,
  });

  final bool open;

  /// Al contestar con una cara, las caras desaparecen: el foco vuelve aquí
  /// para no perderse (WCAG 2.4.3).
  final FocusNode focusNode;

  /// Respuesta de un toque a la energía con una cara; nula si no se ofrece.
  final ValueChanged<int>? onFace;

  /// Nulo al cambiar un registro ya hecho (se cierra con «Cancelar»).
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final header = MergeSemantics(
      child: Semantics(
        header: true,
        expanded: onToggle == null ? null : open,
        child: AppFocusOutline(
          child: ListTile(
            focusNode: focusNode,
            leading: Icon(Icons.mood_rounded, color: context.colors.secondary),
            title: Text(
              l10n.trainingQuickCheckInTitle,
              style: context.textStyles.titleMedium,
            ),
            // Se avisa antes de que la tercera respuesta guarda (WCAG 3.2.2).
            // Con las caras a la vista, dice qué contestan: la energía, no
            // el ánimo. Si no, se avisa de que la tercera respuesta guarda
            // (WCAG 3.2.2).
            subtitle: Text(
              onToggle == null
                  ? l10n.trainingCheckInChangeHint
                  : onFace != null
                  ? l10n.trainingQuickEnergy
                  : l10n.trainingQuickCheckInHint,
            ),
            trailing: onToggle == null || onFace != null
                ? null
                : Icon(
                    open
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                  ),
            onTap: onToggle,
          ),
        ),
      ),
    );
    // Las caras, fuera de la fila que pliega: botones propios, no dentro de
    // otro botón (el lector las leería fundidas con la cabecera).
    final answer = onFace;
    if (answer == null) return header;
    return Row(
      children: [
        Expanded(child: header),
        _Faces(onFace: answer),
        const SizedBox(width: TokensSpacing.xs),
      ],
    );
  }
}

/// Tres caras, de peor a mejor, que contestan la energía de un toque. Cada una
/// lleva su respuesta para el lector («¿Cómo va tu energía? Baja»).
class _Faces extends StatelessWidget {
  const _Faces({required this.onFace});

  final ValueChanged<int> onFace;

  static const _icons = [
    Icons.sentiment_dissatisfied_rounded,
    Icons.sentiment_neutral_rounded,
    Icons.sentiment_satisfied_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final options = CheckInQuestions.options(l10n, CheckInQuestion.energy);
    final title = CheckInQuestions.title(l10n, CheckInQuestion.energy);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < options.length; i++)
          IconButton(
            tooltip: '$title ${options[i].$2}',
            onPressed: () => onFace(options[i].$1),
            icon: Icon(_icons[i], color: context.colors.secondary),
          ),
      ],
    );
  }
}

/// Las tres preguntas. La primera vez del día, la tercera respuesta guarda
/// (tres toques, avisado en la fila de arriba). Al cambiar un registro ya
/// hecho, las tres vienen contestadas: se guarda con «Guardar».
class _Questions extends StatefulWidget {
  const _Questions({required this.state});

  final QuickCheckInState state;

  @override
  State<_Questions> createState() => _QuestionsState();
}

class _QuestionsState extends State<_Questions> with ErrorsMessageMixin {
  CheckInAnswers get _answers => widget.state.answers;

  Future<void> _save() async {
    final answers = _answers;
    if (!answers.complete) return;
    final bloc = context.read<QuickCheckInBloc>();
    if (bloc.state.sending) return;
    final input = QuickCheckIn(
      sleepQuality: answers[CheckInQuestion.sleep]!,
      energy: answers[CheckInQuestion.energy]!,
      soreness: answers[CheckInQuestion.soreness]!,
    );
    // Datos de salud: antes, el permiso expreso (ADR 0034).
    if (await ensureHealthConsent(context)) {
      bloc.add(QuickCheckInEvent.submitted(input));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final editing = widget.state.editing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // La regla de los tres toques la aplica el bloc (`saveRequest`).
        BlocListener<QuickCheckInBloc, QuickCheckInState>(
          listenWhen: (a, b) => a.saveRequest != b.saveRequest,
          listener: (_, _) => _save(),
          child: CheckInQuestions(
            answers: _answers,
            onAnswer: (q, v) => context.read<QuickCheckInBloc>().add(
              QuickCheckInEvent.answered(q, v),
            ),
          ),
        ),
        if (widget.state.sending && !editing) const LinearProgressIndicator(),
        if (widget.state.error case final error?) ...[
          AppInlineMessage(message: errorMessage(context, error)),
          const SizedBox(height: TokensSpacing.s),
          if (!editing)
            AppSecondaryButton(
              label: l10n.commonRetry,
              icon: const Icon(AppIcons.refresh),
              onPressed: _answers.complete ? _save : null,
            ),
        ],
        // Secundario: en Gimnasio la acción principal es empezar el entreno.
        if (editing)
          AppSecondaryButton(
            label: l10n.trainingCheckInUpdateAction,
            loading: widget.state.sending,
            onPressed: _answers.complete ? _save : null,
          ),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: TokensSpacing.s,
          children: [
            if (editing)
              TextButton(
                onPressed: () => context.read<QuickCheckInBloc>().add(
                  const QuickCheckInEvent.editCancelled(),
                ),
                child: Text(l10n.commonCancel),
              ),
            TextButton(
              // Lo ya contestado viaja a la pantalla del registro.
              onPressed: () => context.push<void>(
                TrainingPaths.checkInDetailsWith(_answers),
              ),
              child: Text(l10n.trainingQuickFull),
            ),
          ],
        ),
      ],
    );
  }
}

/// Después de registrar: entreno normal o cuánto se recorta y por qué.
class _Explanation extends StatefulWidget {
  const _Explanation({required this.adaptation, required this.announce});

  final TodayAdaptation adaptation;

  /// Anunciar al lector (solo justo después de enviar).
  final bool announce;

  @override
  State<_Explanation> createState() => _ExplanationState();
}

class _ExplanationState extends State<_Explanation> {
  /// Al guardar, las preguntas desaparecen: el foco pasa a «Cambiar» para no
  /// perderse (WCAG 2.4.3).
  final _changeFocus = FocusNode(debugLabel: 'check-in-change');

  @override
  void initState() {
    super.initState();
    if (widget.announce) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _changeFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _changeFocus.dispose();
    super.dispose();
  }

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
    final adaptation = widget.adaptation;
    final adapted = adaptation.adapted;
    final color = adapted ? context.palette.warning : context.palette.success;
    return Semantics(
      liveRegion: widget.announce,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                adapted ? AppIcons.filters : Icons.check_circle_rounded,
                color: color,
              ),
              const SizedBox(width: TokensSpacing.s),
              Expanded(
                child: Text(
                  adapted
                      ? l10n.trainingQuickAdapted
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
                onPressed: () =>
                    context.push<void>(TrainingPaths.checkInDetails),
                child: Text(l10n.trainingQuickFull),
              ),
              TextButton.icon(
                focusNode: _changeFocus,
                onPressed: () => context.read<QuickCheckInBloc>().add(
                  const QuickCheckInEvent.editRequested(),
                ),
                icon: const Icon(AppIcons.edit),
                label: Text(l10n.trainingQuickChange),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
