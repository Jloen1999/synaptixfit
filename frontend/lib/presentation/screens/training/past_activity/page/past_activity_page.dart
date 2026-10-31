import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../bloc/past_activity_bloc.dart';

/// «Apuntar actividad» (`/training/past-activity`): deporte hecho sin la app
/// («ayer jugué al fútbol una hora»). Se elige qué, cuándo, a qué hora y cuánto;
/// al guardar se pide el esfuerzo, como al marcar un bloque de deporte.
class PastActivityPage extends StatelessWidget {
  const PastActivityPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<PastActivityBloc>(),
    child: const _PastActivityView(),
  );
}

class _PastActivityView extends StatefulWidget {
  const _PastActivityView();

  @override
  State<_PastActivityView> createState() => _PastActivityViewState();
}

class _PastActivityViewState extends State<_PastActivityView>
    with ErrorsMessageMixin {
  /// Días que se pueden elegir: hoy y los 6 anteriores (el servidor admite 7).
  static const _days = 7;

  final _title = TextEditingController();
  late DateTime _day = DateUtils.dateOnly(DateTime.now());
  TimeOfDay _time = TimeOfDay(
    hour: (DateTime.now().hour - 2).clamp(0, 23),
    minute: 0,
  );
  int _minutes = 60;
  String? _notFinished;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  DateTime get _start =>
      DateTime(_day.year, _day.month, _day.day, _time.hour, _time.minute);

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() {
        _time = picked;
        _notFinished = null;
      });
    }
  }

  Future<void> _save() async {
    final l10n = context.localizations;
    final end = _start.add(Duration(minutes: _minutes));
    if (end.isAfter(DateTime.now())) {
      setState(() => _notFinished = l10n.trainingPastActivityNotFinished);
      return;
    }
    setState(() => _notFinished = null);
    final bloc = context.read<PastActivityBloc>();
    final effort = await showEffortDialog(
      context,
      confirmLabel: l10n.trainingPastActivitySave,
      subtitle: _title.text.trim().isEmpty ? null : _title.text.trim(),
    );
    if (effort == null) return;
    bloc.add(
      PastActivityEvent.submitted(
        start: _start,
        minutes: _minutes,
        effort: effort,
        title: _title.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final today = DateUtils.dateOnly(DateTime.now());
    final suggestions = [
      l10n.trainingPastActivityFootball,
      l10n.trainingPastActivityRunning,
      l10n.trainingPastActivityGym,
      l10n.trainingPastActivityCycling,
      l10n.trainingPastActivitySwimming,
      l10n.trainingPastActivityPadel,
    ];
    return BlocConsumer<PastActivityBloc, PastActivityState>(
      listenWhen: (a, b) =>
          (a.savedXp == null && b.savedXp != null) ||
          (b.error != null && a.error != b.error),
      listener: (context, state) {
        final xp = state.savedXp;
        if (xp != null) {
          if (state.updatedAccount case final account?) {
            context.read<SessionBloc>().add(
              SessionEvent.accountUpdated(account),
            );
          }
          context.showSnack(
            xp > 0
                ? l10n.trainingPastActivitySavedXp(xp)
                : l10n.trainingPastActivitySaved,
          );
          context.pop(true);
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppPageBar.reading(title: Text(l10n.trainingPastActivityTitle)),
        body: AppContentWidth.reading(
          child: ListView(
            padding: const EdgeInsets.all(TokensSpacing.m),
            children: [
              Text(
                l10n.trainingPastActivityIntro,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: TokensSpacing.l),
              AppSectionHeader(title: l10n.trainingPastActivityWhat),
              Wrap(
                spacing: TokensSpacing.s,
                runSpacing: TokensSpacing.s,
                children: [
                  for (final name in suggestions)
                    ChoiceChip(
                      label: Text(name),
                      selected: _title.text == name,
                      onSelected: (_) => setState(() => _title.text = name),
                    ),
                ],
              ),
              const SizedBox(height: TokensSpacing.m),
              AppTextField(
                controller: _title,
                label: l10n.trainingPastActivityName,
                icon: Icons.sports_soccer_outlined,
                textInputAction: TextInputAction.done,
                maxLength: 200,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: TokensSpacing.m),
              AppSectionHeader(title: l10n.trainingPastActivityWhen),
              Wrap(
                spacing: TokensSpacing.s,
                runSpacing: TokensSpacing.s,
                children: [
                  for (var i = 0; i < _days; i++)
                    Builder(
                      builder: (context) {
                        final day = today.subtract(Duration(days: i));
                        final label = switch (i) {
                          0 => l10n.trainingPastActivityToday,
                          1 => l10n.trainingPastActivityYesterday,
                          _ => toBeginningOfSentenceCase(
                            DateFormat.MEd(l10n.localeName).format(day),
                          ),
                        };
                        return ChoiceChip(
                          label: Text(label),
                          selected: DateUtils.isSameDay(day, _day),
                          onSelected: (_) => setState(() {
                            _day = day;
                            _notFinished = null;
                          }),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: TokensSpacing.m),
              AppCard(
                padding: EdgeInsets.zero,
                child: AppFocusOutline(
                  child: ListTile(
                    leading: const Icon(Icons.schedule_rounded),
                    title: Text(l10n.trainingPastActivityStart),
                    trailing: Text(
                      _time.format(context),
                      style: context.textStyles.titleMedium,
                    ),
                    onTap: _pickTime,
                  ),
                ),
              ),
              const SizedBox(height: TokensSpacing.m),
              AppStepperField(
                label: l10n.trainingPastActivityDuration,
                value: _minutes,
                min: 30,
                max: 300,
                step: 15,
                display: l10n.trainingPastActivityMinutes,
                // El aviso de «aún no has terminado» deja de valer al cambiar.
                onChanged: (v) => setState(() {
                  _minutes = v;
                  _notFinished = null;
                }),
              ),
              const SizedBox(height: TokensSpacing.l),
              if (_notFinished case final message?) ...[
                AppInlineMessage(message: message),
                const SizedBox(height: TokensSpacing.m),
              ],
              if (state.error case final error?) ...[
                AppInlineMessage(message: errorMessage(context, error)),
                const SizedBox(height: TokensSpacing.m),
              ],
              AppPrimaryButton(
                label: l10n.trainingPastActivitySave,
                icon: Icons.check_rounded,
                loading: state.submitting,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
