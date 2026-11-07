import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/profile/enrollment_proposal.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../academic/widgets/file_pick.dart';
import '../../profile_routes.dart';
import '../../widgets/profile_layout.dart';
import '../bloc/enrollment_import_bloc.dart';

/// Importar la matrícula desde la carta de pago o el resguardo (PDF). Antes de
/// subir nada se explica qué se lee y qué no, y se pide permiso expreso.
class EnrollmentImportPage extends StatelessWidget {
  const EnrollmentImportPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<EnrollmentImportBloc>(),
    child: const _View(),
  );
}

class _View extends StatelessWidget with ErrorsMessageMixin {
  const _View();

  Future<void> _pick(BuildContext context) async {
    final bloc = context.read<EnrollmentImportBloc>();
    final picked = await pickPdfFile();
    if (!context.mounted || picked == null) return;
    switch (picked) {
      case PickedPayload(:final payload):
        bloc.add(EnrollmentImportEvent.fileChosen(payload));
      case PickedTooLarge():
        context.showSnack(context.localizations.profileEnrollmentTooLarge);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocBuilder<EnrollmentImportBloc, EnrollmentImportState>(
      builder: (context, state) => Scaffold(
        appBar: AppPageBar(title: Text(l10n.profileEnrollmentTitle)),
        body: ProfileConstrained(
          child: switch (state.step) {
            EnrollmentStep.reading => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    semanticsLabel: l10n.profileEnrollmentReading,
                  ),
                  const SizedBox(height: TokensSpacing.m),
                  Text(l10n.profileEnrollmentReading),
                ],
              ),
            ),
            EnrollmentStep.done => _Done(state: state),
            EnrollmentStep.review ||
            EnrollmentStep.applying => _Review(state: state),
            EnrollmentStep.intro => _Intro(
              state: state,
              onPick: () => _pick(context),
              errorText: state.error == null
                  ? null
                  : errorMessage(context, state.error!),
            ),
          },
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.state, required this.onPick, this.errorText});

  final EnrollmentImportState state;
  final VoidCallback onPick;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<EnrollmentImportBloc>();
    final privacy = [
      (Icons.check_circle_outline_rounded, l10n.profileEnrollmentPrivacyRead),
      (AppIcons.hidden, l10n.profileEnrollmentPrivacyHidden),
      (Icons.cloud_outlined, l10n.profileEnrollmentPrivacyAi),
      (AppIcons.delete, l10n.profileEnrollmentPrivacyNotStored),
    ];
    return ListView(
      padding: const EdgeInsets.all(TokensSpacing.m),
      children: [
        Text(l10n.profileEnrollmentIntro, style: context.textStyles.bodyLarge),
        const SizedBox(height: TokensSpacing.m),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.profileEnrollmentPrivacyTitle,
                  style: context.textStyles.titleSmall,
                ),
              ),
              const SizedBox(height: TokensSpacing.s),
              for (final (icon, text) in privacy)
                Padding(
                  padding: const EdgeInsets.only(bottom: TokensSpacing.s),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, size: TokensSize.iconS),
                      const SizedBox(width: TokensSpacing.s),
                      Expanded(
                        child: Text(text, style: context.textStyles.bodyMedium),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: TokensSpacing.s),
        AppFocusOutline(
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: state.consent,
            onChanged: (v) =>
                bloc.add(EnrollmentImportEvent.consentChanged(v ?? false)),
            title: Text(l10n.profileEnrollmentConsent),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: TokensSpacing.s),
          Semantics(liveRegion: true, child: ProfileFieldError(errorText!)),
        ],
        const SizedBox(height: TokensSpacing.m),
        AppPrimaryButton(
          label: l10n.profileEnrollmentChoose,
          icon: Icons.upload_file_rounded,
          onPressed: state.consent ? onPick : null,
        ),
        if (!state.consent)
          Padding(
            padding: const EdgeInsets.only(top: TokensSpacing.xs),
            child: Text(
              l10n.profileEnrollmentConsentNeeded,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

class _Review extends StatelessWidget with ErrorsMessageMixin {
  const _Review({required this.state});

  final EnrollmentImportState state;

  String _details(BuildContext context, EnrollmentSubject s) {
    final l10n = context.localizations;
    return [
      if (s.course != null) l10n.profileEnrollmentCourse(s.course!),
      // Con decimales si los tiene (4,5 créditos), con el formato del idioma.
      if (s.credits != null) l10n.profileEnrollmentCredits(s.credits!),
      if (s.period != null && s.period!.isNotEmpty) s.period!,
      if ((s.timesEnrolled ?? 1) > 1)
        l10n.profileEnrollmentTimes(s.timesEnrolled!),
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<EnrollmentImportBloc>();
    final p = state.proposal!;
    final applying = state.step == EnrollmentStep.applying;
    final selectable = EnrollmentImportBloc.selectableOf(p);
    final allSelected = state.selected.containsAll(selectable);
    return ListView(
      padding: const EdgeInsets.all(TokensSpacing.m),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                p.degreeName ?? l10n.profileEnrollmentDegreeUnknown,
                style: context.textStyles.titleMedium,
              ),
              if (p.universityName != null || p.centerName != null)
                Text(
                  [?p.centerName, ?p.universityName].join(' · '),
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: TokensSpacing.s),
              Wrap(
                spacing: TokensSpacing.xs,
                runSpacing: TokensSpacing.xs,
                children: [
                  if (p.academicYear != null)
                    AppPill(icon: AppIcons.calendar, label: p.academicYear!),
                  AppPill(
                    icon: p.degreeId != null
                        ? Icons.verified_outlined
                        : AppIcons.help,
                    label: p.degreeId != null
                        ? l10n.profileEnrollmentDegreeFound
                        : l10n.profileEnrollmentDegreeNotFound,
                    color: p.degreeId != null
                        ? context.palette.success
                        : context.palette.warning,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: TokensSpacing.m),
        AppSectionHeader(
          title: l10n.profileEnrollmentSubjects(p.subjects.length),
          actionLabel: selectable.isEmpty
              ? null
              : allSelected
              ? l10n.profileEnrollmentSelectNone
              : l10n.profileEnrollmentSelectAll,
          onAction: applying
              ? null
              : () => bloc.add(const EnrollmentImportEvent.allToggled()),
        ),
        if (p.subjects.isEmpty)
          AppEmptyState.compact(
            icon: Icons.search_off_rounded,
            title: l10n.profileErrorEnrollmentNothing,
            action: AppSecondaryButton(
              label: l10n.profileEnrollmentOther,
              onPressed: () =>
                  bloc.add(const EnrollmentImportEvent.restarted()),
            ),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: TokensSpacing.xs),
            child: Column(
              children: [
                for (final (i, s) in p.subjects.indexed)
                  AppFocusOutline(
                    child: CheckboxListTile(
                      value: s.alreadyAdded || state.selected.contains(i),
                      onChanged: s.alreadyAdded || applying
                          ? null
                          : (_) => bloc.add(
                              EnrollmentImportEvent.subjectToggled(i),
                            ),
                      title: Text(s.name),
                      subtitle: Text(
                        [
                          _details(context, s),
                          if (s.alreadyAdded) l10n.profileEnrollmentAlready,
                          if (!s.alreadyAdded && !s.inCatalog)
                            l10n.profileEnrollmentOwnSubject,
                        ].where((t) => t.isNotEmpty).join(' · '),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (state.error != null) ...[
          const SizedBox(height: TokensSpacing.s),
          Semantics(
            liveRegion: true,
            child: ProfileFieldError(errorMessage(context, state.error!)),
          ),
        ],
        const SizedBox(height: TokensSpacing.m),
        AppPrimaryButton(
          label: l10n.profileEnrollmentAdd(state.selected.length),
          icon: Icons.playlist_add_check_rounded,
          loading: applying,
          onPressed: state.selected.isEmpty || applying
              ? null
              : () => bloc.add(const EnrollmentImportEvent.applyRequested()),
        ),
        const SizedBox(height: TokensSpacing.s),
        AppSecondaryButton(
          label: l10n.profileEnrollmentOther,
          onPressed: applying
              ? null
              : () => bloc.add(const EnrollmentImportEvent.restarted()),
        ),
      ],
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({required this.state});

  final EnrollmentImportState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final result = state.result!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TokensSpacing.l),
        child: AppEmptyState(
          icon: AppIcons.done,
          title: l10n.profileEnrollmentDone(result.subjectsAdded),
          message: result.degreeLinked
              ? l10n.profileEnrollmentDegreeLinked
              : null,
          action: AppPrimaryButton(
            label: l10n.profileEnrollmentSeeSubjects,
            onPressed: () => context.pushReplacement(ProfilePaths.subjects),
          ),
        ),
      ),
    );
  }
}
