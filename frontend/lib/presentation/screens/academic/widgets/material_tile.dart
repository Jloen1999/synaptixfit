import 'package:flutter/material.dart' hide Visibility;

import '../../../../domain/enums/ai_document_type.dart';
import '../../../../domain/enums/visibility.dart';
import '../../../../domain/models/academic/study_document.dart';
import '../../../../domain/models/academic/subject_material.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'academic_visuals.dart';

/// Qué es un material, en texto (ADR 0064): «Apunte», «Nota rápida», «PDF»,
/// «Imagen» o «Archivo DOCX». Junto al icono, nunca solo el icono.
String materialKindLabel(BuildContext context, SubjectMaterial material) {
  final l10n = context.localizations;
  switch (material) {
    case NoteMaterial(:final note):
      return note.quickNote
          ? l10n.academicMaterialKindQuickNote
          : l10n.academicMaterialKindNote;
    case FileMaterial(:final file):
      if (file.isPdf) return l10n.academicMaterialKindPdf;
      if (file.isImage) return l10n.academicMaterialKindImage;
      final dot = file.fileName.lastIndexOf('.');
      final extension = dot < 0 || dot == file.fileName.length - 1
          ? null
          : file.fileName.substring(dot + 1).toUpperCase();
      return extension == null || extension.length > 5
          ? l10n.academicMaterialKindFile
          : l10n.academicMaterialKindFileNamed(extension);
  }
}

IconData materialIcon(SubjectMaterial material) => switch (material) {
  NoteMaterial(:final note) =>
    note.quickNote ? AppIcons.quickNote : AppIcons.noteDocument,
  FileMaterial(:final file) => fileIcon(file),
};

/// Una fila de la lista «Material» (ADR 0064): icono y tipo en texto, nombre,
/// fecha (y tamaño o con quién se comparte) y el botón «Acciones», que abre la
/// hoja con todo lo demás. Toda la fila abre el material. Debajo, si los hay,
/// los documentos de IA guardados como botones con su nombre.
class MaterialTile extends StatelessWidget {
  const MaterialTile({
    super.key,
    required this.material,
    required this.availability,
    required this.onOpen,
    required this.onActions,
    required this.onOpenDocument,
  });

  final SubjectMaterial material;
  final DocumentAvailability availability;
  final VoidCallback onOpen;
  final VoidCallback onActions;
  final ValueChanged<AiDocumentType> onOpenDocument;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final kind = materialKindLabel(context, material);
    final date = material.date;
    final details = [
      kind,
      if (material case FileMaterial(:final file)) fileSize(file.sizeBytes),
      if (material case NoteMaterial(:final note)
          when note.visibility != Visibility.private)
        context.visibilityLabel(note.visibility),
      if (date != null) shortDate(date),
    ].join(' · ');
    final docs = [
      for (final type in const [
        AiDocumentType.summary,
        AiDocumentType.mindMap,
        AiDocumentType.practice,
      ])
        if (availability.has(type)) type,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TokensSpacing.xxs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              // «Acciones» con su texto si deja sitio al nombre (al menos la
              // mitad de la fila); si no, solo el icono con su nombre.
              final actionsLabel = l10n.academicMaterialActionsShort;
              final withText =
                  constraints.maxWidth -
                      context.buttonWidth(
                        actionsLabel,
                        Theme.of(context).outlinedButtonTheme.style,
                        icon: true,
                      ) >=
                  constraints.maxWidth / 2;
              return Row(
                children: [
                  Expanded(child: _openArea(context, details)),
                  if (withText)
                    Padding(
                      padding: const EdgeInsets.only(right: TokensSpacing.s),
                      child: Semantics(
                        label: l10n.academicMaterialActions(material.title),
                        button: true,
                        excludeSemantics: true,
                        onTap: onActions,
                        child: AppSecondaryButton(
                          label: actionsLabel,
                          icon: const Icon(AppIcons.moreActions),
                          onPressed: onActions,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      tooltip: l10n.academicMaterialActions(material.title),
                      icon: const Icon(AppIcons.moreActions),
                      onPressed: onActions,
                    ),
                ],
              );
            },
          ),
          if (docs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TokensSpacing.m + TokensSize.iconM + TokensSpacing.m,
                0,
                TokensSpacing.m,
                TokensSpacing.xs,
              ),
              child: Wrap(
                spacing: TokensSpacing.xs,
                runSpacing: TokensSpacing.xs,
                children: [
                  for (final type in docs)
                    Semantics(
                      label: l10n.academicMaterialOpenDoc(
                        context.aiDocumentLabel(type),
                        material.title,
                      ),
                      button: true,
                      excludeSemantics: true,
                      // El lector pulsa el nodo que excluye al chip: necesita
                      // su propia acción.
                      onTap: () => onOpenDocument(type),
                      child: ActionChip(
                        avatar: Icon(
                          aiDocumentIcon(type),
                          color: context.colors.tertiary,
                        ),
                        label: Text(context.aiDocumentLabel(type)),
                        onPressed: () => onOpenDocument(type),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Toda la zona del nombre abre el material y se anuncia como un botón.
  Widget _openArea(BuildContext context, String details) => AppFocusOutline(
    child: Semantics(
      button: true,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(TokensRadius.m),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: TokensLayout.minTouchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TokensSpacing.m,
              vertical: TokensSpacing.s,
            ),
            child: Row(
              children: [
                Icon(materialIcon(material), color: context.colors.tertiary),
                const SizedBox(width: TokensSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.titleSmall,
                      ),
                      Text(
                        details,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Lo que se puede hacer con un material desde su hoja de acciones.
enum MaterialAction { open, review, practice, assistant, share, download, delete }

/// Hoja «Acciones» de un material (ADR 0064): abrir, repasar, practicar y la
/// ayuda de la IA (si la IA lo puede leer), compartir, descargar y, aparte y
/// en rojo, eliminar. Devuelve la elegida.
Future<MaterialAction?> showMaterialActionsSheet(
  BuildContext context,
  SubjectMaterial material,
) => showModalBottomSheet<MaterialAction>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheetContext) {
    final l10n = sheetContext.localizations;
    Widget item(MaterialAction action, IconData icon, String label) =>
        ListTile(
          leading: Icon(icon),
          title: Text(label),
          onTap: () => Navigator.of(sheetContext).pop(action),
        );
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TokensSpacing.m,
                0,
                TokensSpacing.m,
                TokensSpacing.s,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      material.title,
                      style: sheetContext.textStyles.titleLarge,
                    ),
                  ),
                  Text(
                    materialKindLabel(sheetContext, material),
                    style: sheetContext.textStyles.bodyMedium?.copyWith(
                      color: sheetContext.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            item(MaterialAction.open, AppIcons.read, l10n.academicMaterialOpen),
            if (material.aiReadable) ...[
              item(
                MaterialAction.review,
                AppIcons.review,
                l10n.academicActionReview,
              ),
              item(
                MaterialAction.practice,
                AppIcons.practice,
                l10n.academicActionPractice,
              ),
              item(
                MaterialAction.assistant,
                AppIcons.proposal,
                l10n.academicAiAssistantTitle,
              ),
            ],
            item(
              MaterialAction.share,
              AppIcons.share,
              l10n.academicMaterialShare,
            ),
            item(
              MaterialAction.download,
              AppIcons.export,
              l10n.academicMaterialDownload,
            ),
            const Divider(),
            ListTile(
              iconColor: sheetContext.colors.error,
              textColor: sheetContext.colors.error,
              leading: const Icon(AppIcons.delete),
              title: Text(l10n.academicDeleteNamed(material.title)),
              onTap: () => Navigator.of(sheetContext).pop(MaterialAction.delete),
            ),
          ],
        ),
      ),
    );
  },
);
