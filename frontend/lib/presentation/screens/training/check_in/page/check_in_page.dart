import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/wellbeing.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../l10n/gen_l10n/app_localizations.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../health_consent/page/health_consent_sheet.dart';
import '../../training_routes.dart';
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

/// Check-in diario de bienestar.
class CheckInPage extends StatelessWidget {
  const CheckInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CheckInBloc>()..add(const CheckInEvent.started()),
      child: const _CheckInView(),
    );
  }
}

class _CheckInView extends StatelessWidget {
  const _CheckInView();

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
          CheckInStatus.ready => _Form(state: state),
        },
      ),
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({required this.state});

  final CheckInState state;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final _notes = TextEditingController(
    text: widget.state.input.notes ?? '',
  );

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  void _update(CheckInInput input) =>
      context.read<CheckInBloc>().add(CheckInEvent.inputChanged(input));

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
                            l10n.trainingCheckInXp(result.xpAwarded),
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
              Text(
                state.today == null
                    ? l10n.trainingCheckInIntro
                    : l10n.trainingCheckInUpdate,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: TokensSpacing.m),
              _Scale(
                icon: Icons.bedtime_rounded,
                label: l10n.trainingSleepQuality,
                value: input.sleepQuality,
                low: l10n.trainingScaleBad,
                high: l10n.trainingScaleGreat,
                onChanged: (v) => _update(input.copyWith(sleepQuality: v)),
              ),
              _Scale(
                icon: Icons.psychology_alt_rounded,
                label: l10n.trainingStress,
                value: input.stress,
                low: l10n.trainingScaleLow,
                high: l10n.trainingScaleHigh,
                onChanged: (v) => _update(input.copyWith(stress: v)),
              ),
              _Scale(
                icon: Icons.bolt_rounded,
                label: l10n.trainingEnergy,
                value: input.energy,
                low: l10n.trainingScaleLow,
                high: l10n.trainingScaleHigh,
                onChanged: (v) => _update(input.copyWith(energy: v)),
              ),
              _Scale(
                icon: Icons.healing_rounded,
                label: l10n.trainingSoreness,
                value: input.soreness,
                low: l10n.trainingScaleNone,
                high: l10n.trainingScaleHigh,
                onChanged: (v) => _update(input.copyWith(soreness: v)),
              ),
              const SizedBox(height: TokensSpacing.s),
              Text(
                l10n.trainingPainZones,
                style: context.textStyles.titleSmall,
              ),
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
              TextField(
                controller: _notes,
                maxLength: 1000,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(labelText: l10n.trainingNotes),
                onChanged: (v) => _update(input.copyWith(notes: v)),
              ),
              const SizedBox(height: TokensSpacing.m),
              AppPrimaryButton(
                label: state.today == null
                    ? l10n.trainingCheckInSave
                    : l10n.trainingCheckInUpdateAction,
                loading: state.submitting,
                onPressed: () async {
                  // Datos de salud: antes, el permiso expreso (ADR 0034).
                  final bloc = context.read<CheckInBloc>();
                  if (await ensureHealthConsent(context)) {
                    bloc.add(const CheckInEvent.submitted());
                  }
                },
              ),
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
            SizedBox.square(
              dimension: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: checkIn.fatigueScore / 100,
                    color: color,
                    backgroundColor: context.colors.surfaceContainer,
                    strokeWidth: 6,
                  ),
                  Text(
                    '${checkIn.fatigueScore}',
                    style: context.textStyles.titleSmall,
                  ),
                ],
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

class _Scale extends StatelessWidget {
  const _Scale({
    required this.icon,
    required this.label,
    required this.value,
    required this.low,
    required this.high,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final int value;
  final String low;
  final String high;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: TokensSize.iconS,
                color: context.colors.secondary,
              ),
              const SizedBox(width: TokensSpacing.s),
              Expanded(
                child: Text(label, style: context.textStyles.titleSmall),
              ),
              Text(
                l10n.trainingScaleValue(value),
                style: context.textStyles.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.xs),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              for (var i = 1; i <= 5; i++)
                ButtonSegment(
                  value: i,
                  label: Text('$i'),
                  tooltip: l10n.trainingScaleSemantics(label, i),
                ),
            ],
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.first),
          ),
          Padding(
            padding: const EdgeInsets.only(top: TokensSpacing.xxs),
            child: Row(
              children: [
                Text(low, style: context.textStyles.labelSmall),
                const Spacer(),
                Text(high, style: context.textStyles.labelSmall),
              ],
            ),
          ),
        ],
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
      subtitle: Text(
        l10n.trainingCheckInHistoryLine(
          checkIn.sleepQuality,
          checkIn.stress,
          checkIn.energy,
          checkIn.soreness,
        ),
      ),
      trailing: Text(
        l10n.trainingFatigueScore(checkIn.fatigueScore),
        style: context.textStyles.labelLarge?.copyWith(color: color),
      ),
    );
  }
}
