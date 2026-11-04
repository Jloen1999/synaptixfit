import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../bloc/reminder_options_bloc.dart';

/// «Más avisos» de los ajustes de notificaciones: racha en riesgo, registro
/// diario y clase en 15 minutos, cada uno con su interruptor y cuándo llega.
/// Qué se avisa lo decide el servidor con estas opciones (ADR 0013).
class ReminderOptionsSection extends StatelessWidget {
  const ReminderOptionsSection({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<ReminderOptionsBloc>()..add(const ReminderOptionsEvent.started()),
    child: const _ReminderOptionsView(),
  );
}

class _ReminderOptionsView extends StatelessWidget {
  const _ReminderOptionsView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocBuilder<ReminderOptionsBloc, ReminderOptionsState>(
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
        final enabled = !state.loading && state.error == null;
        return Padding(
          padding: const EdgeInsets.only(top: TokensSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSectionHeader(title: l10n.profileReminderOptionsTitle),
              if (state.error case final error?)
                AppErrorView(
                  error: error,
                  onRetry: () => context.read<ReminderOptionsBloc>().add(
                    const ReminderOptionsEvent.started(),
                  ),
                ),
              _Switch(
                icon: Icons.local_fire_department_outlined,
                title: l10n.profileReminderStreak,
                hint: l10n.profileReminderStreakHint,
                value: options.streak,
                onChanged: enabled
                    ? (v) => change(v, options.checkIn, options.classes)
                    : null,
              ),
              _Switch(
                icon: Icons.mood_rounded,
                title: l10n.profileReminderCheckIn,
                hint: l10n.profileReminderCheckInHint,
                value: options.checkIn,
                onChanged: enabled
                    ? (v) => change(options.streak, v, options.classes)
                    : null,
              ),
              _Switch(
                icon: Icons.school_outlined,
                title: l10n.profileReminderClasses,
                hint: l10n.profileReminderClassesHint,
                value: options.classes,
                onChanged: enabled
                    ? (v) => change(options.streak, options.checkIn, v)
                    : null,
              ),
              if (state.saveError != null)
                AppInlineMessage(message: l10n.profileReminderSaveError),
            ],
          ),
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
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(hint),
      value: value,
      onChanged: onChanged,
    ),
  );
}
