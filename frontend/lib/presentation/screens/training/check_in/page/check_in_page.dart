import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/check_in_answers.dart';
import '../../../../../domain/models/training/wellbeing.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../l10n/gen_l10n/app_localizations.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../health_consent/page/health_consent_sheet.dart';
import '../../training_routes.dart';
import '../../widgets/check_in_questions.dart';
import '../../widgets/training_content.dart';
import '../../widgets/training_effect_handler.dart';
import '../bloc/check_in_bloc.dart';

/// Zonas de dolor que se ofrecen (valor técnico enviado a la API).
const _painZones = [
  'neck',
  'shoulders',
  'upper_back',
  'lower_back',
  'chest',
  'arms',
  'wrists',
  'hips',
  'knees',
  'ankles',
  'legs',
];

String _painZoneLabel(AppLocalizations l10n, String zone) => switch (zone) {
  'neck' => l10n.trainingPainNeck,
  'shoulders' => l10n.trainingPainShoulders,
  'upper_back' => l10n.trainingPainUpperBack,
  'lower_back' => l10n.trainingPainLowerBack,
  'chest' => l10n.trainingPainChest,
  'arms' => l10n.trainingPainArms,
  'wrists' => l10n.trainingPainWrists,
  'hips' => l10n.trainingPainHips,
  'knees' => l10n.trainingPainKnees,
  'ankles' => l10n.trainingPainAnkles,
  'legs' => l10n.trainingPainLegs,
  _ => zone,
};

/// «¿Qué tal estás hoy?»: el registro diario, uno solo en toda la app
/// (ADR 0039). Arriba, las tres preguntas de un toque (las mismas que la
/// tarjeta de Entreno); con la tercera se guarda. Debajo, plegado, «Añadir
/// detalles»: estrés, zonas con dolor, si estás para entrenar y notas. Con
/// [details] (desde «Añadir detalles») se abre ya desplegado.
class CheckInPage extends StatelessWidget {
  const CheckInPage({
    super.key,
    this.details = false,
    this.initialAnswers = const CheckInAnswers(),
  });

  final bool details;

  /// Lo ya contestado en la tarjeta de Gimnasio (no se pierde al venir).
  final CheckInAnswers initialAnswers;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<CheckInBloc>()
            ..add(CheckInEvent.started(initial: initialAnswers)),
      child: _CheckInView(details: details),
    );
  }
}

class _CheckInView extends StatelessWidget {
  const _CheckInView({required this.details});

  final bool details;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<CheckInBloc, CheckInState>(
      listenWhen: (p, c) => c.effect != null && p.effect != c.effect,
      listener: (context, state) =>
          const TrainingEffectHandler().handle(context, state.effect!),
      builder: (context, state) => Scaffold(
        appBar: AppPageBar.reading(title: Text(l10n.trainingCheckInTitle)),
        body: switch (state.status) {
          CheckInStatus.loading => const AppSkeletonList(
            count: 5,
            height: TokensSize.skeletonRow,
          ),
          CheckInStatus.failure => AppErrorView(
            error: state.error!,
            onRetry: () =>
                context.read<CheckInBloc>().add(const CheckInEvent.started()),
          ),
          CheckInStatus.ready => _Form(state: state, details: details),
        },
      ),
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({required this.state, required this.details});

  final CheckInState state;
  final bool details;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final _notes = TextEditingController(
    text: widget.state.input.notes ?? '',
  );

  /// «Añadir detalles» desplegado: si se pidió o si hoy ya hay alguno.
  late bool _details = widget.details || _hasDetails(widget.state.today);

  static bool _hasDetails(CheckIn? c) =>
      c != null &&
      (c.painZones.isNotEmpty ||
          (c.notes?.isNotEmpty ?? false) ||
          !c.readyToTrain ||
          c.stress != const CheckInInput().stress);

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _update(CheckInInput input) =>
      context.read<CheckInBloc>().add(CheckInEvent.inputChanged(input));

  Future<void> _save() async {
    // Datos de salud: antes, el permiso expreso (ADR 0034).
    final bloc = context.read<CheckInBloc>();
    if (await ensureHealthConsent(context)) {
      bloc.add(const CheckInEvent.submitted());
    }
  }

  /// Se avisa encima de las preguntas cuando la tercera respuesta guarda
  /// sola; la regla vive en el dominio y la aplica el bloc (`saveRequest`).
  bool get _autoSave => CheckInAnswers.savesOnLastAnswer(
    loggedToday: widget.state.today != null,
    withDetails: _details,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final state = widget.state;
    final input = state.input;
    final result = state.lastResult;
    return ListView(
      padding: const EdgeInsets.all(TokensSpacing.m),
      children: [
        TrainingContent(
          maxWidth: TokensLayout.readingMaxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (result != null && result.firstOfDay && result.xpAwarded > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: TokensSpacing.m),
                  child: AppCard(
                    color: context.palette.accentContainer,
                    child: Row(
                      children: [
                        Icon(Icons.star_rounded, color: context.palette.accent),
                        const SizedBox(width: TokensSpacing.s),
                        Expanded(
                          child: Text(
                            l10n.trainingCheckInThanks,
                            style: context.textStyles.titleSmall?.copyWith(
                              color: context.palette.onAccentContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (state.today != null) _TodaySummary(checkIn: state.today!),
              if (_autoSave) ...[
                Text(
                  l10n.trainingCheckInAutoSaveHint,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: TokensSpacing.s),
              ],
              BlocListener<CheckInBloc, CheckInState>(
                listenWhen: (a, b) => a.saveRequest != b.saveRequest,
                listener: (_, _) => _save(),
                child: CheckInQuestions(
                  answers: state.answers,
                  onAnswer: (q, v) => context.read<CheckInBloc>().add(
                    CheckInEvent.answered(q, v, withDetails: _details),
                  ),
                ),
              ),
              if (state.submitting && _autoSave)
                const LinearProgressIndicator(),
              MergeSemantics(
                child: Semantics(
                  expanded: _details,
                  child: AppFocusOutline(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.playlist_add_rounded),
                      title: Text(
                        l10n.trainingQuickFull,
                        style: context.textStyles.titleMedium,
                      ),
                      subtitle: Text(l10n.trainingCheckInDetailsHint),
                      trailing: Icon(
                        _details
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                      ),
                      onTap: () => setState(() => _details = !_details),
                    ),
                  ),
                ),
              ),
              if (_details) ..._detailFields(context, input),
              if (!_autoSave) ...[
                if (!state.answers.complete) ...[
                  Text(
                    l10n.trainingCheckInAnswerFirst,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: TokensSpacing.s),
                ],
                AppPrimaryButton(
                  label: state.today == null
                      ? l10n.trainingCheckInSave
                      : l10n.trainingCheckInUpdateAction,
                  loading: state.submitting,
                  onPressed: state.answers.complete ? _save : null,
                ),
              ],
              const SizedBox(height: TokensSpacing.m),
              // Opcional y para quien quiera: no se da por hecho por el género.
              AppCard(
                onTap: () => context.push<void>(TrainingPaths.cycle),
                child: Row(
                  children: [
                    Icon(
                      Icons.water_drop_outlined,
                      color: context.colors.primary,
                    ),
                    const SizedBox(width: TokensSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.trainingCycleEntryTitle,
                            style: context.textStyles.titleSmall,
                          ),
                          Text(
                            l10n.trainingCycleEntryHint,
                            style: context.textStyles.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
              if (state.history.isNotEmpty) ...[
                const SizedBox(height: TokensSpacing.xl),
                AppSectionHeader(title: l10n.trainingCheckInHistory),
                for (final c in state.history) _HistoryTile(checkIn: c),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Los detalles opcionales (se guardan con «Guardar», junto a las tres
  /// preguntas).
  List<Widget> _detailFields(BuildContext context, CheckInInput input) {
    final l10n = context.localizations;
    return [
      const SizedBox(height: TokensSpacing.s),
      _StressQuestion(
        // Sin contestar no sale ninguna marcada (antes salía «Algo»).
        value: widget.state.stressAnswered ? input.stress : null,
        onChanged: (v) =>
            context.read<CheckInBloc>().add(CheckInEvent.stressChanged(v)),
      ),
      Text(l10n.trainingPainZones, style: context.textStyles.titleSmall),
      const SizedBox(height: TokensSpacing.xs),
      Wrap(
        spacing: TokensSpacing.xs,
        runSpacing: TokensSpacing.xs,
        children: [
          for (final zone in {..._painZones, ...input.painZones})
            FilterChip(
              label: Text(_painZoneLabel(l10n, zone)),
              selected: input.painZones.contains(zone),
              onSelected: (on) {
                final zones = [...input.painZones];
                if (on) {
                  if (zones.length >= CheckInInput.maxPainZones) return;
                  zones.add(zone);
                } else {
                  zones.remove(zone);
                }
                _update(input.copyWith(painZones: zones));
              },
            ),
        ],
      ),
      const SizedBox(height: TokensSpacing.s),
      AppFocusOutline(
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.trainingReadyToTrain),
          value: input.readyToTrain,
          onChanged: (v) => _update(input.copyWith(readyToTrain: v)),
        ),
      ),
      AppTextField(
        label: l10n.trainingNotes,
        controller: _notes,
        maxLength: 1000,
        minLines: 2,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (v) => _update(input.copyWith(notes: v)),
      ),
    ];
  }
}

/// Estrés, en el mismo sentido que el resto: a la derecha, lo mejor (menos
/// estrés). Se guarda en la escala 1-5 de siempre (5 = mucho estrés).
class _StressQuestion extends StatelessWidget {
  const _StressQuestion({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final words = [
      l10n.trainingStressLot,
      l10n.trainingStressQuite,
      l10n.trainingStressSome,
      l10n.trainingStressLittle,
      l10n.trainingStressNone,
    ];
    // El sentido de la escala lo da el dominio: menos estrés es mejor.
    final values = CheckInScale.lowerIsBetter.worstToBest;
    final options = [
      for (var i = 0; i < values.length; i++) (values[i], words[i]),
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.m),
      child: Semantics(
        container: true,
        label: l10n.trainingStressQuestion,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Text(
                l10n.trainingStressQuestion,
                style: context.textStyles.titleSmall,
              ),
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
}

class _TodaySummary extends StatelessWidget {
  const _TodaySummary({required this.checkIn});

  final CheckIn checkIn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final color = checkIn.requiresAdaptation
        ? context.palette.warning
        : context.palette.success;
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.m),
      child: AppCard(
        child: Row(
          children: [
            // En palabras, sin la cifra de fatiga (vocabulario §4).
            ExcludeSemantics(
              child: Icon(
                checkIn.requiresAdaptation
                    ? Icons.battery_3_bar_rounded
                    : Icons.battery_full_rounded,
                color: color,
              ),
            ),
            const SizedBox(width: TokensSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.trainingFatigueTitle,
                    style: context.textStyles.titleSmall,
                  ),
                  Text(
                    checkIn.requiresAdaptation
                        ? l10n.trainingFatigueAdapt
                        : l10n.trainingFatigueOk,
                    style: context.textStyles.bodySmall?.copyWith(color: color),
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

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.checkIn});

  final CheckIn checkIn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final color = checkIn.requiresAdaptation
        ? context.palette.warning
        : context.palette.success;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        checkIn.requiresAdaptation
            ? Icons.warning_amber_rounded
            : Icons.check_circle_outline_rounded,
        color: color,
      ),
      title: Text(DateFormat.yMMMEd().format(checkIn.date)),
      // En palabras, como se contestó: los números mezclaban sentidos
      // (en sueño 5 es bueno; en agujetas, malo).
      subtitle: Text(
        l10n.trainingCheckInHistoryWords(
          CheckInQuestions.answer(
            l10n,
            CheckInQuestion.sleep,
            checkIn.sleepQuality,
          ),
          CheckInQuestions.answer(l10n, CheckInQuestion.energy, checkIn.energy),
          CheckInQuestions.answer(
            l10n,
            CheckInQuestion.soreness,
            checkIn.soreness,
          ),
        ),
      ),
    );
  }
}
