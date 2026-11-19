import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../domain/models/academic/teaching_guide.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_widgets.dart';
import '../bloc/subject_detail_bloc.dart';
import '../bloc/subject_progress_bloc.dart';

/// Abre «Importar guía docente» para esta asignatura y, al volver, recarga
/// la asignatura (curso, temas) y sus pestañas.
Future<void> openGuideImport(BuildContext context, String subjectId) async {
  final progress = context.read<SubjectProgressBloc>();
  final detail = context.read<SubjectDetailBloc>();
  await context.push<Object?>(AcademicPaths.importGuide(subjectId: subjectId));
  progress.add(const SubjectProgressEvent.refreshed());
  detail.add(const SubjectDetailEvent.refreshed());
}

/// Volver a importar conserva el progreso, pero se avisa si lo hay.
Future<void> reimportGuide(
  BuildContext context,
  String subjectId,
  TeachingGuide guide,
) async {
  final hasProgress =
      guide.topics.any((t) => t.completed) ||
      guide.assessments.any((a) => a.grade != null);
  if (hasProgress) {
    final l10n = context.localizations;
    final ok = await confirmDestructive(
      context,
      title: l10n.academicGuideReimportTitle,
      message: l10n.academicGuideReimportMessage,
      confirmLabel: l10n.academicGuideReimportConfirm,
    );
    if (!ok || !context.mounted) return;
  }
  await openGuideImport(context, subjectId);
}

/// Vacío útil de las pestañas que salen de la guía docente (Temario,
/// Evaluación, Guía): qué se gana y el botón para importarla.
class GuideMissingView extends StatelessWidget {
  const GuideMissingView({
    super.key,
    required this.subjectId,
    required this.icon,
    required this.title,
    this.message,
    this.guide,
  });

  final String subjectId;
  final IconData icon;
  final String title;
  final String? message;

  /// Ya hay guía, pero no trae esta parte: se ofrece volver a importarla.
  final TeachingGuide? guide;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final existing = guide;
    return AppEmptyState(
      icon: icon,
      title: title,
      message: message,
      action: existing == null
          ? AppPrimaryButton(
              label: l10n.academicImportEntry,
              icon: AppIcons.importGuide,
              onPressed: () => openGuideImport(context, subjectId),
            )
          : AppSecondaryButton(
              label: l10n.academicGuideRegenerate,
              icon: const Icon(AppIcons.refresh),
              onPressed: () => reimportGuide(context, subjectId, existing),
            ),
    );
  }
}
