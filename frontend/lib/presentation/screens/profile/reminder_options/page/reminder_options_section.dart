import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/profile_layout.dart';
import '../bloc/reminder_options_bloc.dart';

/// «Más avisos» de los ajustes de notificaciones: racha en riesgo, registro
/// diario y clase en 15 minutos, cada uno con su interruptor y cuándo llega.
/// Qué se avisa lo decide el servidor con estas opciones (ADR 0013).
class ReminderOptionsSection extends StatelessWidget {
  const ReminderOptionsSection({super.key, required this.deviceRemindersOn});

  /// Con los recordatorios del móvil apagados, estos avisos no llegan: se dice
  /// y se explica qué activar primero.
  final bool deviceRemindersOn;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<ReminderOptionsBloc>()..add(const ReminderOptionsEvent.started()),
    child: _ReminderOptionsView(deviceRemindersOn: deviceRemindersOn),
  );
}

class _ReminderOptionsView extends StatelessWidget with ErrorsMessageMixin {
  const _ReminderOptionsView({required this.deviceRemindersOn});

  final bool deviceRemindersOn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<ReminderOptionsBloc, ReminderOptionsState>(
      listenWhen: (a, b) => b.saveError != null && a.saveError != b.saveError,
      listener: (context, state) =>
          context.showSnack(errorMessage(context, state.saveError!)),
      builder: (context, state) {
        final options = state.options;
        void change(bool streak, bool checkIn, bool classes) =>
            context.read<ReminderOptionsBloc>().add(
              ReminderOptionsEvent.changed(
                options.copyWith(
                  streak: streak,
                  checkIn: checkIn,
                  classes: classes,
                ),
              ),
            );
        final Widget child;
        if (state.loading) {
          // Mientras carga, un hueco del alto de la fila: los interruptores no
          // enseñan valores que quizá no son los reales.
          child = const AppSkeletonGroup(
            child: AppSkeleton(height: TokensSize.heroStat),
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
          child = Column(
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
                  children: [
                    _Switch(
                      icon: Icons.local_fire_department_outlined,
                      title: l10n.profileReminderStreak,
                      hint: l10n.profileReminderStreakHint,
                      value: options.streak,
                      onChanged: (v) =>
                          change(v, options.checkIn, options.classes),
                    ),
                    const Divider(height: 1),
                    _Switch(
                      icon: Icons.mood_rounded,
                      title: l10n.profileReminderCheckIn,
                      hint: l10n.profileReminderCheckInHint,
                      value: options.checkIn,
                      onChanged: (v) =>
                          change(options.streak, v, options.classes),
                    ),
                    const Divider(height: 1),
                    _Switch(
                      icon: Icons.school_outlined,
                      title: l10n.profileReminderClasses,
                      hint: l10n.profileReminderClassesHint,
                      value: options.classes,
                      onChanged: (v) =>
                          change(options.streak, options.checkIn, v),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        return ProfileFormSection(
          title: l10n.profileReminderOptionsTitle,
          trailing: AppPill(
            label: l10n.remindersAppliesNow,
            icon: Icons.bolt_rounded,
          ),
          child: child,
        );
      },
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
