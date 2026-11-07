import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../app/validators/validators.dart';
import '../../../../../domain/enums/profile/onboarding_step.dart';
import '../../../../../domain/enums/usage_focus.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../extensions/validation_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../edit_academic/bloc/academic_form_bloc.dart';
import '../../edit_academic/page/edit_academic_page.dart';
import '../../edit_wellness/bloc/wellness_form_bloc.dart';
import '../../edit_wellness/page/edit_wellness_page.dart';
import '../../subject_selector/bloc/subject_selector_bloc.dart';
import '../../subject_selector/page/subject_selector_page.dart';
import '../../widgets/onboarding_step_indicator.dart';
import '../../widgets/profile_layout.dart';
import '../../widgets/birth_date_field.dart';
import '../../widgets/usage_focus_selector.dart';
import '../bloc/onboarding_bloc.dart';

/// Flujo de alta a pantalla completa (`/onboarding`).
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key, required this.homePath});

  /// Destino al terminar.
  final String homePath;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<OnboardingBloc>()..add(const OnboardingEvent.started()),
      child: _OnboardingView(homePath: homePath),
    );
  }
}

class _OnboardingView extends StatelessWidget with ErrorsMessageMixin {
  const _OnboardingView({required this.homePath});

  final String homePath;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state.status == OnboardingStatusView.finished) {
          context.go(homePath);
        }
      },
      listenWhen: (a, b) => a.status != b.status,
      builder: (context, state) {
        final bloc = context.read<OnboardingBloc>();
        return BlocListener<OnboardingBloc, OnboardingState>(
          listenWhen: (a, b) =>
              a.actionError != b.actionError || a.account != b.account,
          listener: (context, state) {
            if (state.actionError case final error?) {
              context.showSnack(errorMessage(context, error));
            }
            if (state.account case final account?) {
              context.read<SessionBloc>().add(
                SessionEvent.accountUpdated(account),
              );
            }
          },
          child: Scaffold(
            appBar: AppPageBar.reading(
              automaticallyImplyLeading: false,
              leading: state.index > 0 && !state.busy
                  ? IconButton(
                      tooltip: context.localizations.commonBack,
                      icon: const Icon(AppIcons.back),
                      onPressed: () =>
                          bloc.add(const OnboardingEvent.previousRequested()),
                    )
                  : null,
              title: Text(context.localizations.profileOnboardingTitle),
            ),
            body: switch (state.status) {
              OnboardingStatusView.loading ||
              OnboardingStatusView.finished => const AppLoadingView(),
              OnboardingStatusView.failure => AppErrorView(
                error: state.error!,
                onRetry: () => bloc.add(const OnboardingEvent.started()),
              ),
              OnboardingStatusView.ready => _StepBody(
                key: ValueKey(state.currentStep),
                state: state,
              ),
            },
          ),
        );
      },
    );
  }
}

class _StepBody extends StatelessWidget {
  const _StepBody({super.key, required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final step = state.currentStep!;
    final header = Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OnboardingStepIndicator(
            current: state.index,
            total: state.steps.length,
            title: _title(context, step),
          ),
          const SizedBox(height: TokensSpacing.xs),
          Text(
            _subtitle(context, step),
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
    final skip = state.canSkip
        ? TextButton(
            onPressed: state.busy
                ? null
                : () => context.read<OnboardingBloc>().add(
                    const OnboardingEvent.stepSkipped(),
                  ),
            child: Text(
              state.isLastStep
                  ? l10n.profileOnboardingSkipAndFinish
                  : l10n.profileOnboardingSkip,
            ),
          )
        : null;
    return switch (step) {
      OnboardingStep.account => _AccountStep(
        header: header,
        skip: skip!,
        busy: state.busy,
      ),
      OnboardingStep.focus => _FocusStep(
        header: header,
        busy: state.busy,
        submitLabel: _continueLabel(context),
      ),
      OnboardingStep.academicProfile => _AcademicStep(
        header: header,
        skip: skip!,
        submitLabel: _continueLabel(context),
      ),
      OnboardingStep.wellnessProfile => _WellnessStep(
        header: header,
        submitLabel: _continueLabel(context),
      ),
      OnboardingStep.subjects => _SubjectsStep(header: header, skip: skip!),
    };
  }

  String _continueLabel(BuildContext context) => state.isLastStep
      ? context.localizations.profileOnboardingFinish
      : context.localizations.profileOnboardingSaveAndContinue;

  String _title(BuildContext context, OnboardingStep step) {
    final l10n = context.localizations;
    return switch (step) {
      OnboardingStep.account => l10n.profileOnboardingAccountTitle,
      OnboardingStep.focus => l10n.profileOnboardingFocusTitle,
      OnboardingStep.academicProfile => l10n.profileOnboardingAcademicTitle,
      OnboardingStep.wellnessProfile => l10n.profileOnboardingWellnessTitle,
      OnboardingStep.subjects => l10n.profileOnboardingSubjectsTitle,
    };
  }

  String _subtitle(BuildContext context, OnboardingStep step) {
    final l10n = context.localizations;
    return switch (step) {
      OnboardingStep.account => l10n.profileOnboardingAccountSubtitle,
      OnboardingStep.focus => l10n.profileOnboardingFocusSubtitle,
      OnboardingStep.academicProfile => l10n.profileOnboardingAcademicSubtitle,
      OnboardingStep.wellnessProfile => l10n.profileOnboardingWellnessSubtitle,
      OnboardingStep.subjects => l10n.profileOnboardingSubjectsSubtitle,
    };
  }
}

/// Paso de cuenta: crear contraseña para las cuentas de Google (opcional).
class _AccountStep extends StatefulWidget {
  const _AccountStep({
    required this.header,
    required this.skip,
    required this.busy,
  });

  final Widget header;
  final Widget skip;
  final bool busy;

  @override
  State<_AccountStep> createState() => _AccountStepState();
}

class _AccountStepState extends State<_AccountStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: context.read<SessionBloc>().account?.fullName ?? '',
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<OnboardingBloc>().add(
      OnboardingEvent.accountSubmitted(
        fullName: _name.text,
        password: _password.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return ProfileScrollBody(
      children: [
        widget.header,
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: l10n.fieldFullName,
                  controller: _name,
                  icon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: (v) => Validators.minLength(v, 2)?.text(context),
                ),
                const SizedBox(height: TokensSpacing.m),
                AppTextField(
                  label: l10n.profilePasswordNew,
                  helper: l10n.fieldPasswordHint,
                  controller: _password,
                  icon: Icons.lock_outline_rounded,
                  obscure: true,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) => Validators.password(v)?.text(context),
                ),
                const SizedBox(height: TokensSpacing.m),
                AppTextField(
                  label: l10n.profilePasswordConfirm,
                  controller: _confirm,
                  icon: Icons.lock_outline_rounded,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                      v != _password.text ? l10n.profilePasswordMismatch : null,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: TokensSpacing.l),
                AppPrimaryButton(
                  label: l10n.profileOnboardingSaveAndContinue,
                  loading: widget.busy,
                  onPressed: _submit,
                ),
                const SizedBox(height: TokensSpacing.s),
                widget.skip,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AcademicStep extends StatelessWidget with ErrorsMessageMixin {
  const _AcademicStep({
    required this.header,
    required this.skip,
    required this.submitLabel,
  });

  final Widget header;
  final Widget skip;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<AcademicFormBloc>()
            ..add(const AcademicFormEvent.started(loadExisting: false)),
      child: BlocConsumer<AcademicFormBloc, AcademicFormState>(
        listenWhen: (a, b) =>
            a.saved != b.saved || a.actionError != b.actionError,
        listener: (context, state) {
          if (state.actionError case final error?) {
            context.showSnack(errorMessage(context, error));
          } else if (state.saved != null) {
            context.read<OnboardingBloc>().add(
              const OnboardingEvent.stepCompleted(),
            );
          }
        },
        builder: (context, state) => AcademicFormBody(
          state: state,
          submitLabel: submitLabel,
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              Align(alignment: Alignment.centerRight, child: skip),
            ],
          ),
        ),
      ),
    );
  }
}

class _WellnessStep extends StatelessWidget with ErrorsMessageMixin {
  const _WellnessStep({required this.header, required this.submitLabel});

  final Widget header;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<WellnessFormBloc>()
            ..add(const WellnessFormEvent.started(loadExisting: false)),
      child: BlocConsumer<WellnessFormBloc, WellnessFormState>(
        listenWhen: (a, b) =>
            a.saved != b.saved || a.actionError != b.actionError,
        listener: (context, state) {
          if (state.actionError case final error?) {
            context.showSnack(errorMessage(context, error));
          } else if (state.saved != null) {
            context.read<OnboardingBloc>().add(
              const OnboardingEvent.stepCompleted(),
            );
          }
        },
        builder: (context, state) => WellnessFormBody(
          state: state,
          submitLabel: submitLabel,
          header: header,
          compact: true,
        ),
      ),
    );
  }
}

class _SubjectsStep extends StatelessWidget {
  const _SubjectsStep({required this.header, required this.skip});

  final Widget header;
  final Widget skip;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<SubjectSelectorBloc>()
            ..add(const SubjectSelectorEvent.started()),
      child: SubjectSelectorView(
        header: header,
        secondaryAction: skip,
        onAdded: (count) {
          context.showSnack(context.localizations.profileSubjectsAdded(count));
          context.read<OnboardingBloc>().add(
            const OnboardingEvent.stepCompleted(),
          );
        },
      ),
    );
  }
}

/// Paso de enfoque: estudios, deporte o ambos. Decide los pasos siguientes y
/// qué se ve en la app.
class _FocusStep extends StatefulWidget {
  const _FocusStep({
    required this.header,
    required this.busy,
    required this.submitLabel,
  });

  final Widget header;
  final bool busy;
  final String submitLabel;

  @override
  State<_FocusStep> createState() => _FocusStepState();
}

class _FocusStepState extends State<_FocusStep> {
  UsageFocus _focus = UsageFocus.both;
  DateTime? _birthDate;

  @override
  Widget build(BuildContext context) {
    final focus = _focus;
    return ProfileScrollBody(
      children: [
        widget.header,
        UsageFocusSelector(
          value: focus,
          onChanged: (value) => setState(() => _focus = value),
        ),
        const SizedBox(height: TokensSpacing.m),
        // Opcional: sirve para felicitarle y para calcular su edad (kcal,
        // propuestas). Se puede seguir sin darla.
        BirthDateField(
          value: _birthDate,
          onChanged: (value) => setState(() => _birthDate = value),
        ),
        const SizedBox(height: TokensSpacing.m),
        AppPrimaryButton(
          label: widget.submitLabel,
          loading: widget.busy,
          onPressed: () => context.read<OnboardingBloc>().add(
            OnboardingEvent.focusSubmitted(focus, birthDate: _birthDate),
          ),
        ),
      ],
    );
  }
}
