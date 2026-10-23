import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../widgets/widgets.dart';
import '../../catalog_picker/page/catalog_picker_sheet.dart';
import '../../widgets/academic_profile_form.dart';
import '../../widgets/profile_layout.dart';
import '../bloc/academic_form_bloc.dart';

/// Edición del perfil académico. Devuelve `true` al cerrar si se ha guardado.
class EditAcademicPage extends StatelessWidget {
  const EditAcademicPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<AcademicFormBloc>()..add(const AcademicFormEvent.started()),
      child: const _EditAcademicView(),
    );
  }
}

class _EditAcademicView extends StatelessWidget with ErrorsMessageMixin {
  const _EditAcademicView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Scaffold(
      appBar: AppPageBar.reading(title: Text(l10n.profileEditAcademicTitle)),
      body: BlocConsumer<AcademicFormBloc, AcademicFormState>(
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
            a.selectedDegree != b.selectedDegree,
        builder: (context, state) => AcademicFormBody(state: state),
      ),
    );
  }
}

/// Cuerpo del formulario académico ligado a [AcademicFormBloc] (también lo usa el onboarding).
class AcademicFormBody extends StatelessWidget {
  const AcademicFormBody({
    super.key,
    required this.state,
    this.submitLabel,
    this.header,
  });

  final AcademicFormState state;
  final String? submitLabel;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<AcademicFormBloc>();
    return switch (state.status) {
      AcademicFormStatus.loading => const AppLoadingView(),
      AcademicFormStatus.failure => AppErrorView(
        error: state.loadError!,
        onRetry: () => bloc.add(const AcademicFormEvent.started()),
      ),
      AcademicFormStatus.ready => ProfileScrollBody(
        children: [
          ?header,
          AcademicProfileForm(
            initial: state.initial,
            selectedDegree: state.selectedDegree,
            submitLabel: submitLabel ?? l10n.commonSave,
            saving: state.saving,
            onPickDegree: () async {
              final degree = await showCatalogDegreePicker(context);
              if (degree != null) {
                bloc.add(AcademicFormEvent.degreeSelected(degree));
              }
            },
            onClearDegree: () =>
                bloc.add(const AcademicFormEvent.degreeCleared()),
            onSubmit: (draft) => bloc.add(AcademicFormEvent.submitted(draft)),
          ),
        ],
      ),
    };
  }
}
