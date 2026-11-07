import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/reminder_task_timing.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/profile/notification_preferences.dart';
import '../../../../../domain/models/reminders/reminder_options.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/profile_layout.dart';
import '../bloc/reminder_options_bloc.dart';

/// «Más avisos» de los ajustes de notificaciones: interruptores (racha,
/// registro diario, clases y resumen de la mañana) y «Cuándo te avisamos»
/// (antelación de eventos y clases, días antes de entregas y exámenes y
/// momento de las tareas de reto). Solo opciones cerradas; qué se avisa lo
/// decide el servidor con ellas (ADR 0013 y 0035).
class ReminderOptionsSection extends StatelessWidget {
  const ReminderOptionsSection({super.key, required this.deviceRemindersOn});

  /// Con los recordatorios del móvil apagados, estos avisos no llegan: se dice
  /// y se explica qué activar primero.
  final bool deviceRemindersOn;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<ReminderOptionsBloc>()..add(const ReminderOptionsEvent.started()),
    child: ReminderOptionsView(deviceRemindersOn: deviceRemindersOn),
  );
}

/// Vista de [ReminderOptionsSection] sobre un [ReminderOptionsBloc] ya creado
/// (pública para probarla con un bloc de prueba).
class ReminderOptionsView extends StatelessWidget with ErrorsMessageMixin {
  const ReminderOptionsView({super.key, required this.deviceRemindersOn});

  final bool deviceRemindersOn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<ReminderOptionsBloc, ReminderOptionsState>(
      listenWhen: (a, b) => b.saveError != null && a.saveError != b.saveError,
      listener: (context, state) {
        final error = state.saveError!;
        final unsaved = state.unsaved;
        // Una opción fuera de la lista tiene su texto en el catálogo; el resto
        // dice que se deshizo el cambio y deja reintentarlo.
        final message = error is BusinessError
            ? errorMessage(context, error)
            : l10n.profileReminderSaveError;
        if (unsaved == null || error is BusinessError) {
          context.showSnack(message);
          return;
        }
        final bloc = context.read<ReminderOptionsBloc>();
        context.showActionSnack(
          message,
          actionLabel: l10n.commonRetry,
          onAction: () => bloc.add(ReminderOptionsEvent.changed(unsaved)),
        );
      },
      builder: (context, state) {
        final Widget child;
        if (state.loading) {
          // Mientras carga, huecos del alto de las tarjetas: las opciones no
          // enseñan valores que quizá no son los reales.
          child = const AppSkeletonGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSkeleton(height: TokensSize.heroStat),
                SizedBox(height: TokensSpacing.m),
                AppSkeleton(height: TokensSize.heroStat),
              ],
            ),
          );
        } else if (state.error case final error?) {
          child = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppInlineMessage(message: errorMessage(context, error)),
              const SizedBox(height: TokensSpacing.s),
              AppSecondaryButton(
                label: l10n.commonRetry,
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => context.read<ReminderOptionsBloc>().add(
                  const ReminderOptionsEvent.started(),
                ),
              ),
            ],
          );
        } else {
          child = _Options(
            options: state.options,
            deviceRemindersOn: deviceRemindersOn,
          );
        }
        return ProfileFormSection(
          title: l10n.profileReminderOptionsTitle,
          // Mientras carga o si no cargó, aún no se aplica nada.
          trailing: state.loading || state.error != null
              ? null
              : _SaveStatus(state: state),
          child: child,
        );
      },
    );
  }
}

/// Pastilla de estado: «Se aplica al momento», «Guardando…» o «Guardado».
/// Se anuncia al cambiar (región viva) para quien usa lector de pantalla.
class _SaveStatus extends StatelessWidget {
  const _SaveStatus({required this.state});

  final ReminderOptionsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final (label, icon) = state.saving
        ? (l10n.profileReminderSaving, Icons.sync_rounded)
        : state.saved
        ? (l10n.profileReminderSaved, Icons.check_rounded)
        : (l10n.remindersAppliesNow, Icons.bolt_rounded);
    return Semantics(
      liveRegion: true,
      child: AppPill(label: label, icon: icon),
    );
  }
}

class _Options extends StatelessWidget {
  const _Options({required this.options, required this.deviceRemindersOn});

  final ReminderOptions options;
  final bool deviceRemindersOn;

  void _change(BuildContext context, ReminderOptions next) => context
      .read<ReminderOptionsBloc>()
      .add(ReminderOptionsEvent.changed(next));

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!deviceRemindersOn) ...[
          AppInlineMessage(
            tone: AppMessageTone.warning,
            message: l10n.profileReminderNeedsDevice,
          ),
          const SizedBox(height: TokensSpacing.s),
        ],
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Switch(
                icon: Icons.wb_twilight_rounded,
                title: l10n.profileReminderMorningSummary,
                hint: l10n.profileReminderMorningSummaryHint,
                value: options.morningSummary,
                onChanged: (v) =>
                    _change(context, options.copyWith(morningSummary: v)),
              ),
              if (options.morningSummary)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TokensSpacing.m,
                    0,
                    TokensSpacing.m,
                    TokensSpacing.m,
                  ),
                  child: _SummaryTimeField(
                    value: options.morningSummaryAt,
                    onChanged: (t) =>
                        _change(context, options.copyWith(morningSummaryAt: t)),
                  ),
                ),
              const Divider(height: 1),
              _Switch(
                icon: Icons.local_fire_department_outlined,
                title: l10n.profileReminderStreak,
                hint: l10n.profileReminderStreakHint,
                value: options.streak,
                onChanged: (v) => _change(context, options.copyWith(streak: v)),
              ),
              const Divider(height: 1),
              _Switch(
                icon: Icons.mood_rounded,
                title: l10n.profileReminderCheckIn,
                hint: l10n.profileReminderCheckInHint,
                value: options.checkIn,
                onChanged: (v) =>
                    _change(context, options.copyWith(checkIn: v)),
              ),
              const Divider(height: 1),
              _Switch(
                icon: Icons.school_outlined,
                title: l10n.profileReminderClasses,
                hint: l10n.profileReminderClassesHint,
                value: options.classes,
                onChanged: (v) =>
                    _change(context, options.copyWith(classes: v)),
              ),
            ],
          ),
        ),
        const SizedBox(height: TokensSpacing.l),
        Semantics(
          header: true,
          child: Text(
            l10n.profileReminderTimingTitle,
            style: context.textStyles.titleSmall,
          ),
        ),
        const SizedBox(height: TokensSpacing.s),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ChoiceGroup(
                title: l10n.profileReminderEventLead,
                hint: l10n.profileReminderEventLeadHint,
                chips: [
                  for (final minutes in ReminderOptions.leadMinuteChoices)
                    ChoiceChip(
                      label: Text(
                        minutes % 60 == 0
                            ? l10n.profileReminderLeadHours(minutes ~/ 60)
                            : l10n.profileReminderLeadMinutes(minutes),
                      ),
                      selected: options.eventLeadMinutes == minutes,
                      onSelected: (on) {
                        if (on) {
                          _change(
                            context,
                            options.copyWith(eventLeadMinutes: minutes),
                          );
                        }
                      },
                    ),
                ],
              ),
              const Divider(height: TokensSpacing.xl),
              _DeadlineDays(
                selected: options.deadlineDaysBefore,
                onChanged: (days) => _change(
                  context,
                  options.copyWith(deadlineDaysBefore: days),
                ),
              ),
              const Divider(height: TokensSpacing.xl),
              // Mismo formato que los otros dos grupos; la explicación es la
              // de la opción elegida.
              _ChoiceGroup(
                title: l10n.profileReminderTaskTiming,
                hint: switch (options.taskTiming) {
                  ReminderTaskTiming.eveningBefore =>
                    l10n.profileReminderTaskEveningHint,
                  ReminderTaskTiming.morningOf =>
                    l10n.profileReminderTaskMorningHint,
                },
                chips: [
                  for (final timing in ReminderTaskTiming.values)
                    ChoiceChip(
                      avatar: Icon(switch (timing) {
                        ReminderTaskTiming.eveningBefore =>
                          Icons.nights_stay_outlined,
                        ReminderTaskTiming.morningOf => Icons.wb_sunny_outlined,
                      }, size: TokensSize.iconXs),
                      label: Text(switch (timing) {
                        ReminderTaskTiming.eveningBefore =>
                          l10n.profileReminderTaskEvening,
                        ReminderTaskTiming.morningOf =>
                          l10n.profileReminderTaskMorning,
                      }),
                      selected: options.taskTiming == timing,
                      onSelected: (on) {
                        if (on) {
                          _change(
                            context,
                            options.copyWith(taskTiming: timing),
                          );
                        }
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Título, explicación de una línea y las opciones en chips (se reparten en
/// varias filas con texto grande).
class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({
    required this.title,
    required this.hint,
    required this.chips,
    this.footer,
  });

  final String title;
  final String hint;
  final List<Widget> chips;
  final Widget? footer;

  /// El grupo se anuncia con su título («Eventos y clases») para que cada
  /// opción («15 min antes, seleccionado») no se oiga suelta.
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: context.textStyles.titleSmall),
        ),
        const SizedBox(height: TokensSpacing.xxs),
        Text(
          hint,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: TokensSpacing.s),
        Wrap(
          spacing: TokensSpacing.s,
          runSpacing: TokensSpacing.s,
          children: chips,
        ),
        ?footer,
      ],
    ),
  );
}

/// «Entregas y exámenes»: 1, 3 y 7 días antes, uno o varios. El último no se
/// puede quitar (sin ninguno no se avisaría de nada): se dice por qué.
class _DeadlineDays extends StatelessWidget {
  const _DeadlineDays({required this.selected, required this.onChanged});

  final List<int> selected;
  final ValueChanged<List<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final onlyOne = selected.length == 1;
    return _ChoiceGroup(
      title: l10n.profileReminderDeadlineDays,
      hint: l10n.profileReminderDeadlineDaysHint,
      chips: [
        for (final days in ReminderOptions.deadlineDayChoices)
          FilterChip(
            label: Text(l10n.profileReminderDaysBefore(days)),
            selected: selected.contains(days),
            onSelected: (on) {
              if (!on && onlyOne) {
                context.showSnack(l10n.profileReminderDeadlineKeepOne);
                return;
              }
              onChanged(
                on
                    ? ([...selected, days]..sort())
                    : [
                        for (final d in selected)
                          if (d != days) d,
                      ],
              );
            },
          ),
      ],
      footer: onlyOne
          ? Padding(
              padding: const EdgeInsets.only(top: TokensSpacing.s),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: TokensSize.iconXs,
                    color: context.colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: TokensSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.profileReminderDeadlineKeepOne,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

/// Hora del resumen de la mañana: solo las que acepta el servidor (de 05:00 a
/// 12:00, en punto o y media), en el formato de hora del móvil.
class _SummaryTimeField extends StatelessWidget {
  const _SummaryTimeField({required this.value, required this.onChanged});

  final ClockTime value;
  final ValueChanged<ClockTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final material = MaterialLocalizations.of(context);
    final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
    String label(ClockTime t) => material.formatTimeOfDay(
      TimeOfDay(hour: t.hour, minute: t.minute),
      alwaysUse24HourFormat: use24h,
    );
    // Una hora guardada fuera de la lista (p. ej. de otra versión) se enseña
    // igual para que el campo no aparezca vacío.
    final choices = {...ReminderOptions.summaryTimeChoices, value}.toList()
      ..sort((a, b) => (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute));
    // Controlado (sin clave que lo reconstruya): elegir una hora no pierde el
    // foco del teclado ni del lector de pantalla.
    return InputDecorator(
      decoration: InputDecoration(
        labelText: context.localizations.profileReminderMorningSummaryAt,
        prefixIcon: const Icon(Icons.schedule_rounded),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ClockTime>(
          value: value,
          isExpanded: true,
          isDense: true,
          items: [
            for (final t in choices)
              DropdownMenuItem(value: t, child: Text(label(t))),
          ],
          onChanged: (t) {
            if (t != null && t != value) onChanged(t);
          },
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  const _Switch({
    required this.icon,
    required this.title,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String hint;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => AppFocusOutline(
    child: SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(hint),
      value: value,
      onChanged: onChanged,
    ),
  );
}
