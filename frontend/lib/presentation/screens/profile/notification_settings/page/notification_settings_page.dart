import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/enums/weekly_email_status.dart';
import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/profile/notification_category.dart';
import '../../../../../domain/enums/profile/notification_mode.dart';
import '../../../../../domain/models/profile/notification_preferences.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../l10n/gen_l10n/app_localizations.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/profile_labels.dart';
import '../../widgets/profile_layout.dart';
import '../bloc/weekly_email_bloc.dart';
import '../bloc/device_reminders_bloc.dart';
import '../bloc/notification_settings_bloc.dart';
import '../../reminder_options/page/reminder_options_section.dart';

/// Preferencias de notificaciones (`/profile/settings/notifications`).
class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<NotificationSettingsBloc>()
                ..add(const NotificationSettingsEvent.started()),
        ),
        BlocProvider(
          create: (_) =>
              getIt<DeviceRemindersBloc>()
                ..add(const DeviceRemindersEvent.started()),
        ),
        BlocProvider(
          create: (_) =>
              getIt<WeeklyEmailBloc>()..add(const WeeklyEmailEvent.started()),
        ),
      ],
      child: const _NotificationSettingsView(),
    );
  }
}

class _NotificationSettingsView extends StatelessWidget
    with ErrorsMessageMixin {
  const _NotificationSettingsView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Scaffold(
      appBar: AppPageBar.reading(title: Text(l10n.profileNotificationsTitle)),
      body: BlocConsumer<NotificationSettingsBloc, NotificationSettingsState>(
        listenWhen: (a, b) =>
            a.saved != b.saved || a.actionError != b.actionError,
        listener: (context, state) {
          if (state.actionError case final error?) {
            context.showSnack(errorMessage(context, error));
          } else if (state.saved) {
            context.showSnack(l10n.commonSaved);
          }
        },
        builder: (context, state) {
          final bloc = context.read<NotificationSettingsBloc>();
          switch (state.status) {
            case NotificationSettingsStatus.loading:
              return const AppSkeletonGroup(
                child: ProfileScrollBody(
                  children: [
                    AppSkeleton(height: 220),
                    SizedBox(height: TokensSpacing.m),
                    AppSkeleton(height: 120),
                  ],
                ),
              );
            case NotificationSettingsStatus.failure:
              return AppErrorView(
                error: state.error!,
                onRetry: () =>
                    bloc.add(const NotificationSettingsEvent.started()),
              );
            case NotificationSettingsStatus.ready:
              return _Content(
                preferences: state.preferences!,
                dirty: state.dirty,
                saving: state.saving,
              );
          }
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.preferences,
    required this.dirty,
    required this.saving,
  });

  final NotificationPreferences preferences;
  final bool dirty;
  final bool saving;

  /// 0 no es «ninguna»: el servidor entrega siempre las importantes (críticas).
  static String _dailyLimitLabel(AppLocalizations l10n, int limit) => limit == 0
      ? l10n.profileDailyLimitOnlyImportant
      : l10n.profileDailyLimitValue(limit);

  Future<void> _editQuietHours(BuildContext context) async {
    final bloc = context.read<NotificationSettingsBloc>();
    final l10n = context.localizations;
    final startInitial =
        preferences.quietHoursStart ?? const ClockTime(hour: 23, minute: 0);
    final endInitial =
        preferences.quietHoursEnd ?? const ClockTime(hour: 7, minute: 0);
    final start = await showTimePicker(
      context: context,
      helpText: l10n.profileQuietHoursStart,
      initialTime: TimeOfDay(
        hour: startInitial.hour,
        minute: startInitial.minute,
      ),
    );
    if (start == null || !context.mounted) return;
    final end = await showTimePicker(
      context: context,
      helpText: l10n.profileQuietHoursEnd,
      initialTime: TimeOfDay(hour: endInitial.hour, minute: endInitial.minute),
    );
    if (end == null || !context.mounted) return;
    if (start == end) {
      context.showSnack(l10n.profileErrorQuietHours);
      return;
    }
    bloc.add(
      NotificationSettingsEvent.quietHoursChanged(
        start: ClockTime(hour: start.hour, minute: start.minute),
        end: ClockTime(hour: end.hour, minute: end.minute),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<NotificationSettingsBloc>();
    final start = preferences.quietHoursStart;
    final end = preferences.quietHoursEnd;
    String format(ClockTime t) =>
        TimeOfDay(hour: t.hour, minute: t.minute).format(context);
    return Column(
      children: [
        Expanded(
          child: ProfileScrollBody(
            children: [
              ProfileFormSection(
                title: l10n.profileNotificationsModeTitle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<NotificationMode>(
                      showSelectedIcon: false,
                      segments: [
                        for (final m in NotificationMode.values)
                          ButtonSegment(value: m, label: Text(m.label(l10n))),
                      ],
                      selected: {preferences.mode},
                      onSelectionChanged: (s) => bloc.add(
                        NotificationSettingsEvent.modeChanged(s.first),
                      ),
                    ),
                    const SizedBox(height: TokensSpacing.xs),
                    Text(
                      preferences.mode.hint(l10n),
                      style: context.textStyles.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ProfileFormSection(
                title: l10n.profileNotificationsCategoriesTitle,
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final category in NotificationCategory.values)
                        AppFocusOutline(
                          child: SwitchListTile(
                            secondary: Icon(category.icon),
                            title: Text(category.label(l10n)),
                            value: preferences.activeCategories.contains(
                              category,
                            ),
                            onChanged: (_) => bloc.add(
                              NotificationSettingsEvent.categoryToggled(
                                category,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              ProfileFormSection(
                title: l10n.profileQuietHoursTitle,
                subtitle: l10n.profileQuietHoursHint,
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      AppFocusOutline(
                        child: SwitchListTile(
                          secondary: const Icon(Icons.bedtime_outlined),
                          title: Text(l10n.profileQuietHoursEnabled),
                          subtitle: start != null && end != null
                              ? Text(
                                  l10n.profileQuietHoursRange(
                                    format(start),
                                    format(end),
                                  ),
                                )
                              : null,
                          value: start != null && end != null,
                          onChanged: (on) => on
                              ? _editQuietHours(context)
                              : bloc.add(
                                  const NotificationSettingsEvent.quietHoursCleared(),
                                ),
                        ),
                      ),
                      if (start != null && end != null)
                        AppFocusOutline(
                          child: ListTile(
                            leading: const Icon(Icons.schedule_rounded),
                            title: Text(l10n.profileQuietHoursEdit),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _editQuietHours(context),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              ProfileFormSection(
                title: l10n.profileDailyLimitTitle,
                subtitle: l10n.profileDailyLimitHint,
                trailing: Text(
                  _dailyLimitLabel(l10n, preferences.dailyLimit),
                  style: context.textStyles.labelLarge,
                ),
                child: Slider(
                  value: preferences.dailyLimit.toDouble(),
                  min: 0,
                  max: 50,
                  divisions: 50,
                  label: _dailyLimitLabel(l10n, preferences.dailyLimit),
                  semanticFormatterCallback: (v) =>
                      _dailyLimitLabel(l10n, v.round()),
                  onChanged: (v) => bloc.add(
                    NotificationSettingsEvent.dailyLimitChanged(v.round()),
                  ),
                ),
              ),
              // Va al final y aparte: se guarda al momento en el teléfono,
              // sin el botón «Guardar» de las preferencias de la cuenta.
              const _DeviceRemindersSection(),
              // Avisos opcionales que se apagan uno a uno (se guardan al momento).
              const ReminderOptionsSection(),
              const _WeeklyEmailSection(),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: ProfileConstrained(
            child: Padding(
              padding: const EdgeInsets.all(TokensSpacing.m),
              child: SizedBox(
                width: double.infinity,
                child: AppPrimaryButton(
                  label: l10n.commonSave,
                  loading: saving,
                  onPressed: dirty
                      ? () => bloc.add(
                          const NotificationSettingsEvent.saveRequested(),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Interruptor local «Recordatorios · En este móvil». Solo aparece donde hay
/// avisos locales (móvil) y se guarda al momento, sin el botón Guardar. Si el
/// sistema no da permiso, muestra una fila fija que lo explica y deja volver a
/// pedirlo; al volver a la app se comprueba de nuevo.
class _DeviceRemindersSection extends StatefulWidget {
  const _DeviceRemindersSection();

  @override
  State<_DeviceRemindersSection> createState() =>
      _DeviceRemindersSectionState();
}

class _DeviceRemindersSectionState extends State<_DeviceRemindersSection>
    with ErrorsMessageMixin {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Al volver de los ajustes del teléfono el permiso puede haber cambiado.
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<DeviceRemindersBloc>().add(
        const DeviceRemindersEvent.started(),
      ),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<DeviceRemindersBloc, DeviceRemindersState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) =>
          context.showSnack(errorMessage(context, state.error!)),
      builder: (context, state) {
        if (!state.supported) return const SizedBox.shrink();
        final bloc = context.read<DeviceRemindersBloc>();
        return ProfileFormSection(
          title: l10n.remindersDeviceSectionTitle,
          trailing: AppPill(
            label: l10n.remindersAppliesNow,
            icon: Icons.bolt_rounded,
          ),
          child: AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                AppFocusOutline(
                  child: SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_outlined),
                    title: Text(l10n.remindersDeviceToggle),
                    subtitle: Text(l10n.remindersDeviceHint),
                    value: state.enabled,
                    onChanged: state.busy
                        ? null
                        : (on) => bloc.add(DeviceRemindersEvent.toggled(on)),
                  ),
                ),
                if (state.permissionDenied) ...[
                  const Divider(height: 1),
                  _PermissionDeniedRow(
                    onRetry: state.busy
                        ? null
                        : () => bloc.add(
                            const DeviceRemindersEvent.toggled(true),
                          ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Resumen semanal por correo: se aplica al momento, como los avisos del
/// móvil. Explica en cada estado qué va a pasar (confirmar desde el correo,
/// llega el domingo).
class _WeeklyEmailSection extends StatelessWidget with ErrorsMessageMixin {
  const _WeeklyEmailSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<WeeklyEmailBloc, WeeklyEmailState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) =>
          context.showSnack(errorMessage(context, state.error!)),
      builder: (context, state) {
        final status = state.status;
        if (status == null) {
          final loadError = state.loadError;
          return ProfileFormSection(
            title: l10n.profileWeeklyEmailSectionTitle,
            // Mientras carga, un hueco del alto de la fila (la página no salta);
            // si falla, el error y cómo reintentarlo, solo en esta sección.
            child: loadError == null
                ? const AppSkeleton(height: TokensSize.heroStat)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppInlineMessage(
                        message: errorMessage(context, loadError),
                      ),
                      const SizedBox(height: TokensSpacing.s),
                      AppSecondaryButton(
                        label: l10n.commonRetry,
                        icon: const Icon(Icons.refresh_rounded),
                        onPressed: () => context.read<WeeklyEmailBloc>().add(
                          const WeeklyEmailEvent.started(),
                        ),
                      ),
                    ],
                  ),
          );
        }
        final hint = switch (status) {
          WeeklyEmailStatus.off => l10n.profileWeeklyEmailHintOff,
          WeeklyEmailStatus.pending => l10n.profileWeeklyEmailHintPending,
          WeeklyEmailStatus.active => l10n.profileWeeklyEmailHintActive,
        };
        return ProfileFormSection(
          title: l10n.profileWeeklyEmailSectionTitle,
          // Pendiente, «se aplica al momento» confundiría: aún falta confirmar.
          trailing: status == WeeklyEmailStatus.pending
              ? AppPill(
                  label: l10n.profileWeeklyEmailPendingPill,
                  icon: Icons.mark_email_unread_outlined,
                  color: context.palette.warning,
                )
              : AppPill(
                  label: l10n.remindersAppliesNow,
                  icon: Icons.bolt_rounded,
                ),
          child: AppCard(
            padding: EdgeInsets.zero,
            child: AppFocusOutline(
              child: SwitchListTile(
                secondary: const Icon(Icons.mark_email_unread_outlined),
                title: Text(l10n.profileWeeklyEmailToggle),
                // Región viva: el texto cambia al activarlo (p. ej. «revisa tu
                // correo para confirmarlo») y se anuncia.
                subtitle: Semantics(liveRegion: true, child: Text(hint)),
                value: status != WeeklyEmailStatus.off,
                onChanged: state.busy
                    ? null
                    : (on) => context.read<WeeklyEmailBloc>().add(
                        WeeklyEmailEvent.toggled(on),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Fila fija «Permiso desactivado en el sistema». «Volver a pedir» lanza otra
/// vez la petición del sistema; si el sistema ya no muestra el diálogo, el
/// texto explica dónde activarlo.
class _PermissionDeniedRow extends StatelessWidget {
  const _PermissionDeniedRow({required this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(
          TokensSpacing.m,
          TokensSpacing.s,
          TokensSpacing.s,
          TokensSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.notifications_off_outlined,
                  color: context.palette.warning,
                ),
                const SizedBox(width: TokensSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.remindersPermissionDeniedTitle,
                        style: context.textStyles.titleSmall,
                      ),
                      const SizedBox(height: TokensSpacing.xxs),
                      Text(
                        l10n.remindersPermissionDeniedBody,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: onRetry,
                child: Text(l10n.remindersPermissionRetry),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
