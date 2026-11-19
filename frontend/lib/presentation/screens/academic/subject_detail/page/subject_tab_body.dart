import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/academic_widgets.dart';
import '../bloc/subject_progress_bloc.dart';

/// Cuerpo común de las pestañas Resumen, Temario, Evaluación y Guía: carga,
/// error con «Reintentar» y «tirar para recargar» (el aviso de error de las
/// acciones lo da la página, una vez). [children] pinta el contenido cargado.
class SubjectTabBody extends StatelessWidget {
  const SubjectTabBody({super.key, required this.children});

  final List<Widget> Function(BuildContext context, SubjectProgressState state)
  children;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubjectProgressBloc, SubjectProgressState>(
      builder: (context, state) {
        if (state.loading) {
          return const AppSkeletonList(height: 96);
        }
        if (state.error != null) {
          return AppErrorView(
            error: state.error!,
            onRetry: () => context.read<SubjectProgressBloc>().add(
              SubjectProgressEvent.started(state.subjectId),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => context.read<SubjectProgressBloc>().add(
            const SubjectProgressEvent.refreshed(),
          ),
          child: AcademicBody(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                TokensSpacing.m,
                TokensSpacing.m,
                TokensSpacing.m,
                TokensSpacing.xxl,
              ),
              children: children(context, state),
            ),
          ),
        );
      },
    );
  }
}
