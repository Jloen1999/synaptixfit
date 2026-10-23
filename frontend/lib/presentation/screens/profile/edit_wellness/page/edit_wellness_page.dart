import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/profile_layout.dart';
import '../../widgets/wellness_profile_form.dart';
import '../bloc/wellness_form_bloc.dart';

/// Edición del perfil físico. Devuelve `true` al cerrar si se ha guardado.
class EditWellnessPage extends StatelessWidget {
  const EditWellnessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<WellnessFormBloc>()..add(const WellnessFormEvent.started()),
      child: const _EditWellnessView(),
    );
  }
}

class _EditWellnessView extends StatelessWidget with ErrorsMessageMixin {
  const _EditWellnessView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Scaffold(
      appBar: AppPageBar.reading(title: Text(l10n.profileEditWellnessTitle)),
      body: BlocConsumer<WellnessFormBloc, WellnessFormState>(
        listenWhen: (a, b) =>
            a.saved != b.saved || a.actionError != b.actionError,
        listener: (context, state) {
          if (state.actionError case final error?) {
            context.showSnack(errorMessage(context, error));
          } else if (state.saved != null) {
            context.showSnack(l10n.commonSaved);
            context.pop(true);
          }
        },
        buildWhen: (a, b) =>
            a.status != b.status ||
            a.saving != b.saving ||
            a.suggesting != b.suggesting ||
            a.suggestions != b.suggestions,
        builder: (context, state) => WellnessFormBody(state: state),
      ),
    );
  }
}

/// Cuerpo del formulario físico ligado a [WellnessFormBloc] (también lo usa el onboarding).
class WellnessFormBody extends StatelessWidget {
  const WellnessFormBody({
    super.key,
    required this.state,
    this.submitLabel,
    this.header,
    this.compact = false,
  });

  final WellnessFormState state;
  final String? submitLabel;
  final Widget? header;

  /// Formulario corto del onboarding.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<WellnessFormBloc>();
    return switch (state.status) {
      WellnessFormStatus.loading => const AppLoadingView(),
      WellnessFormStatus.failure => AppErrorView(
        error: state.loadError!,
        onRetry: () => bloc.add(const WellnessFormEvent.started()),
      ),
      WellnessFormStatus.ready => ProfileScrollBody(
        children: [
          ?header,
          WellnessProfileForm(
            compact: compact,
            initial: state.initial,
            submitLabel: submitLabel ?? l10n.commonSave,
            saving: state.saving,
            suggesting: state.suggesting,
            suggestions: state.suggestions,
            onSubmit: (draft) => bloc.add(WellnessFormEvent.submitted(draft)),
            onSuggest: (age, sex, activity) => bloc.add(
              WellnessFormEvent.suggestionsRequested(
                age: age,
                sex: sex,
                activityLevel: activity,
              ),
            ),
          ),
        ],
      ),
    };
  }
}
