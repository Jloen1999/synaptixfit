import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/enums/ai_document_type.dart';
import '../../../../domain/enums/study_source_type.dart';
import '../../../../domain/models/academic/study_document.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import '../academic_routes.dart';
import 'academic_visuals.dart';

/// Hoja del asistente de IA sobre un apunte o archivo: resumen, mapa mental o
/// práctica. Marca con «Guardado» lo que ya existe (se abre sin regenerar).
Future<void> showAiAssistantSheet(
  BuildContext context, {
  required StudySourceType sourceType,
  required String sourceId,
  required String title,
  DocumentAvailability availability = DocumentAvailability.none,
}) => showModalBottomSheet<void>(
  context: context,
  showDragHandle: true,
  builder: (sheetContext) {
    final l10n = sheetContext.localizations;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          TokensSpacing.m,
          0,
          TokensSpacing.m,
          TokensSpacing.m,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(AppIcons.proposal, color: sheetContext.colors.tertiary),
                const SizedBox(width: TokensSpacing.s),
                Expanded(
                  child: Text(
                    l10n.academicAiAssistantTitle,
                    style: sheetContext.textStyles.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: TokensSpacing.xs),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: sheetContext.textStyles.bodyMedium?.copyWith(
                color: sheetContext.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: TokensSpacing.m),
            for (final type in const [
              AiDocumentType.summary,
              AiDocumentType.mindMap,
              AiDocumentType.practice,
            ])
              _AssistantOption(
                type: type,
                saved: availability.has(type),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push(
                    AcademicPaths.aiDocument(sourceType, sourceId, type, title),
                  );
                },
              ),
          ],
        ),
      ),
    );
  },
);

class _AssistantOption extends StatelessWidget {
  const _AssistantOption({
    required this.type,
    required this.saved,
    required this.onTap,
  });

  final AiDocumentType type;
  final bool saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final description = switch (type) {
      AiDocumentType.summary => l10n.academicAiSummaryHint,
      AiDocumentType.mindMap => l10n.academicAiMindMapHint,
      _ => l10n.academicAiPracticeHint,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.s),
      child: Card(
        child: AppFocusOutline(
          child: ListTile(
            minVerticalPadding: TokensSpacing.s,
            leading: CircleAvatar(
              backgroundColor: context.colors.tertiaryContainer,
              child: Icon(
                aiDocumentIcon(type),
                color: context.colors.onTertiaryContainer,
              ),
            ),
            title: Text(context.aiDocumentLabel(type)),
            subtitle: Text(description),
            trailing: saved
                ? AppPill(
                    label: l10n.academicAiSaved,
                    color: context.palette.success,
                    icon: Icons.check_rounded,
                  )
                : const Icon(AppIcons.next),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
