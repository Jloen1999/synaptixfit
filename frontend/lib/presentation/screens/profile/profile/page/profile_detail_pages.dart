import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/profile/academic_profile.dart';
import '../../../../../domain/models/profile/catalog.dart';
import '../../../../../domain/models/profile/wellness_profile.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../profile_routes.dart';
import '../../widgets/profile_labels.dart';
import '../../widgets/profile_layout.dart';
import '../bloc/profile_bloc.dart';

/// Ficha «Físico» del perfil (`/profile/physical`, ADR 0061): peso, altura,
/// IMC, objetivo y disponibilidad, con «Editar» y la evolución. Se abre desde
/// su tarjetita del Perfil.
class ProfilePhysicalPage extends StatelessWidget {
  const ProfilePhysicalPage({super.key});

  @override
  Widget build(BuildContext context) => _ProfileSectionScaffold(
    title: context.localizations.profileWellnessSection,
    builder: (state) => [
      ProfileWellnessSummary(profile: state.summary!.wellness),
    ],
  );
}

/// Ficha «Académico» del perfil (`/profile/studies`, ADR 0061): universidad,
/// grado y curso, con «Editar», los grados, las asignaturas y la matrícula.
class ProfileStudiesPage extends StatelessWidget {
  const ProfileStudiesPage({super.key});

  @override
  Widget build(BuildContext context) => _ProfileSectionScaffold(
    title: context.localizations.profileAcademicSection,
    builder: (state) => [
      ProfileAcademicSummary(
        profile: state.summary!.academic,
        degrees: state.summary!.degrees,
      ),
    ],
  );
}

/// Esqueleto común de las dos fichas: lee el perfil con su propio
/// [ProfileBloc] (también abiertas en frío desde un enlace) y pinta carga,
/// error o la ficha.
class _ProfileSectionScaffold extends StatelessWidget with ErrorsMessageMixin {
  const _ProfileSectionScaffold({required this.title, required this.builder});

  final String title;
  final List<Widget> Function(ProfileState state) builder;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>()..add(const ProfileEvent.started()),
      child: Scaffold(
        appBar: AppPageBar.reading(
          leading: const AppBackButton(fallback: ProfilePaths.root),
          title: Text(title),
        ),
        body: BlocConsumer<ProfileBloc, ProfileState>(
          listenWhen: (a, b) => a.error != b.error,
          listener: (context, state) {
            if (state.status == ProfileStatus.ready && state.error != null) {
              context.showSnack(errorMessage(context, state.error!));
            }
          },
          builder: (context, state) {
            final bloc = context.read<ProfileBloc>();
            return switch (state.status) {
              ProfileStatus.loading => const AppSkeletonGroup(
                child: ProfileScrollBody(
                  physics: NeverScrollableScrollPhysics(),
                  children: [AppSkeleton(height: TokensSize.skeletonPanel)],
                ),
              ),
              ProfileStatus.failure => AppErrorView(
                error: state.error!,
                onRetry: () => bloc.add(const ProfileEvent.started()),
              ),
              ProfileStatus.ready => RefreshIndicator(
                onRefresh: () async {
                  bloc.add(const ProfileEvent.refreshed());
                  await bloc.stream.firstWhere((s) => !s.refreshing);
                },
                child: ProfileScrollBody(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: builder(state),
                ),
              ),
            };
          },
        ),
      ),
    );
  }
}

/// Abre una pantalla del perfil y vuelve a leerlo al volver (pudo cambiar).
Future<void> openProfileScreen(BuildContext context, String path) async {
  final bloc = context.read<ProfileBloc>();
  await context.push<Object?>(path);
  if (!bloc.isClosed) bloc.add(const ProfileEvent.refreshed());
}

/// Datos físicos: cifras, objetivo y disponibilidad; sin datos, la tarjeta
/// para completarlos. «Editar» y «Ver la evolución» son botones con borde.
class ProfileWellnessSummary extends StatelessWidget {
  const ProfileWellnessSummary({super.key, required this.profile});

  final WellnessProfile? profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final p = profile;
    if (p == null) {
      return ProfileMissingCard(
        icon: AppIcons.routine,
        color: context.colors.secondary,
        message: l10n.profileWellnessMissing,
        actionLabel: l10n.profileCompleteAction,
        onAction: () => openProfileScreen(context, ProfilePaths.editWellness),
      );
    }
    final number = NumberFormat('0.#');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      icon: AppIcons.bmi,
                      color: context.palette.sessions,
                      value: p.bmi == null ? '—' : number.format(p.bmi),
                      label: l10n.profileBmiLabel,
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      icon: AppIcons.bodyWeight,
                      color: context.colors.secondary,
                      value: p.weightKg == null
                          ? '—'
                          : l10n.profileKgValue(number.format(p.weightKg)),
                      label: l10n.profileFieldWeightShort,
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      icon: AppIcons.bodyHeight,
                      color: context.palette.calories,
                      value: p.heightCm == null
                          ? '—'
                          : l10n.profileCmValue(number.format(p.heightCm)),
                      label: l10n.profileFieldHeightShort,
                    ),
                  ),
                ],
              ),
              const Divider(height: TokensSpacing.l),
              ProfileInfoRow(
                icon: p.primaryGoal?.icon ?? AppIcons.goal,
                label: l10n.profileFieldGoal,
                value: p.primaryGoal?.label(l10n) ?? p.primaryGoalLabel ?? '—',
              ),
              ProfileInfoRow(
                icon: AppIcons.activityLevel,
                label: l10n.profileFieldActivityLevel,
                value: p.activityLevel?.label(l10n) ?? '—',
              ),
              ProfileInfoRow(
                icon: AppIcons.calendar,
                label: l10n.profileFieldAvailableDays,
                value: p.availableDays.isEmpty
                    ? '—'
                    : p.availableDays
                          .map((d) => ProfileWeekdays.short(l10n, d))
                          .join(' · '),
              ),
              if (p.minutesPerSession != null)
                ProfileInfoRow(
                  icon: AppIcons.duration,
                  label: l10n.profileSessionLength,
                  value: l10n.profileMinutesShort(p.minutesPerSession!),
                ),
            ],
          ),
        ),
        const SizedBox(height: TokensSpacing.m),
        AppSecondaryButton(
          label: l10n.commonEdit,
          icon: const Icon(AppIcons.edit),
          onPressed: () =>
              openProfileScreen(context, ProfilePaths.editWellness),
        ),
        const SizedBox(height: TokensSpacing.s),
        AppSecondaryButton(
          label: l10n.profileWellnessHistoryAction,
          icon: const Icon(AppIcons.weightHistory),
          onPressed: () =>
              openProfileScreen(context, ProfilePaths.wellnessHistory),
        ),
      ],
    );
  }
}

/// Datos académicos, con «Editar», y las filas de grados, asignaturas y
/// matrícula (estas, aunque falten los datos: se pueden poner antes).
class ProfileAcademicSummary extends StatelessWidget {
  const ProfileAcademicSummary({
    super.key,
    required this.profile,
    required this.degrees,
  });

  final AcademicProfile? profile;
  final List<UserDegree> degrees;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final p = profile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (p == null)
          ProfileMissingCard(
            icon: AppIcons.subject,
            color: context.palette.study,
            message: l10n.profileAcademicMissing,
            actionLabel: l10n.profileCompleteAction,
            onAction: () =>
                openProfileScreen(context, ProfilePaths.editAcademic),
          )
        else ...[
          AppCard(
            child: Column(
              children: [
                ProfileInfoRow(
                  icon: AppIcons.university,
                  label: l10n.profileFieldUniversity,
                  value: p.university ?? '—',
                ),
                ProfileInfoRow(
                  icon: AppIcons.subject,
                  label: l10n.profileFieldDegree,
                  value: p.degree ?? '—',
                ),
                ProfileInfoRow(
                  icon: AppIcons.semester,
                  label: l10n.profileFieldSemester,
                  value: p.semester == null
                      ? '—'
                      : l10n.profileSemesterValue(p.semester!),
                ),
                if (p.modality != null)
                  ProfileInfoRow(
                    icon: AppIcons.modality,
                    label: l10n.profileFieldModality,
                    value: p.modality!.label(l10n),
                  ),
              ],
            ),
          ),
          const SizedBox(height: TokensSpacing.m),
          AppSecondaryButton(
            label: l10n.commonEdit,
            icon: const Icon(AppIcons.edit),
            onPressed: () =>
                openProfileScreen(context, ProfilePaths.editAcademic),
          ),
        ],
        const SizedBox(height: TokensSpacing.l),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppFocusOutline(
                child: ListTile(
                  leading: Icon(AppIcons.degrees, color: context.palette.study),
                  title: Text(l10n.profileDegreesTitle),
                  subtitle: Text(
                    degrees.isEmpty
                        ? l10n.profileDegreesNone
                        : degrees.map((d) => d.degree.name).join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(AppIcons.next),
                  onTap: () => openProfileScreen(context, ProfilePaths.degrees),
                ),
              ),
              const Divider(height: 1),
              AppFocusOutline(
                child: ListTile(
                  leading: Icon(
                    AppIcons.pickSubjects,
                    color: context.palette.study,
                  ),
                  title: Text(l10n.profileSubjectsTitle),
                  trailing: const Icon(AppIcons.next),
                  onTap: () =>
                      openProfileScreen(context, ProfilePaths.subjects),
                ),
              ),
              const Divider(height: 1),
              AppFocusOutline(
                child: ListTile(
                  leading: Icon(
                    AppIcons.enrollment,
                    color: context.palette.study,
                  ),
                  title: Text(l10n.profileEnrollmentEntry),
                  trailing: const Icon(AppIcons.next),
                  onTap: () =>
                      openProfileScreen(context, ProfilePaths.enrollmentImport),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Lo que falta por rellenar: título opcional, una frase y debajo el botón
/// para hacerlo (tonal: parece un botón, no un texto de color).
class ProfileMissingCard extends StatelessWidget {
  const ProfileMissingCard({
    super.key,
    required this.icon,
    required this.color,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.title,
  });

  final IconData icon;
  final Color color;

  /// Encabezado de la tarjeta («Completa tu perfil»).
  final String? title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: TokensSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title case final title?)
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: context.textStyles.titleMedium,
                        ),
                      ),
                    Text(message, style: context.textStyles.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
          FilledButton.tonal(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: TokensSpacing.xs),
        Text(value, style: context.textStyles.titleMedium),
        Text(
          label,
          style: context.textStyles.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
