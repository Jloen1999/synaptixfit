import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/models/academic/note.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import '../academic_routes.dart';
import 'academic_visuals.dart';

/// Autor de un apunte compartido: avatar y nombre que llevan a su perfil
/// público (`/social/users/:id`), y detrás, fuera del botón, un texto
/// secundario (la fecha). Lo usan la tarjeta y el detalle.
class SharedNoteAuthor extends StatelessWidget {
  const SharedNoteAuthor({
    super.key,
    required this.authorId,
    required this.authorName,
    this.authorAvatarUrl,
    this.trailing,
  });

  final String authorId;
  final String authorName;
  final String? authorAvatarUrl;

  /// Texto secundario tras el autor (p. ej., la fecha); se lee aparte.
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final label = l10n.academicSharedOpenAuthor(authorName);
    // Mismo patrón que la racha de Inicio: la etiqueta envuelve el InkWell y
    // solo se excluye el contenido, para conservar la acción y el foco en web.
    final author = Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        container: true,
        button: true,
        label: label,
        child: AppFocusOutline(
          borderRadius: BorderRadius.circular(TokensRadius.pill),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () =>
                context.push(AcademicExternalPaths.userProfile(authorId)),
            child: ExcludeSemantics(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: TokensLayout.minTouchTarget,
                ),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    end: TokensSpacing.s,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppAvatar(
                        name: authorName,
                        imageUrl: authorAvatarUrl,
                        radius: TokensSize.thumbnailXs / 2,
                      ),
                      const SizedBox(width: TokensSpacing.s),
                      Flexible(
                        child: Text(
                          authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textStyles.labelLarge?.copyWith(
                            color: context.colors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final extra = trailing;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: TokensSpacing.xs,
      children: [
        author,
        if (extra != null)
          Text(
            extra,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// Tarjeta de un apunte compartido: arriba el autor (botón propio que lleva
/// a su perfil) con la fecha; debajo, la zona que abre el detalle, con la
/// asignatura en el violeta de «mente» (de qué va, lo primero que se busca),
/// el título, un extracto y la visibilidad. Sin toques anidados.
class SharedNoteCard extends StatelessWidget {
  const SharedNoteCard({super.key, required this.note, required this.onOpen});

  final SharedNoteSummary note;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final subject = note.catalogSubjectName;
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            // Autor y cuerpo empiezan en la misma columna (16 dp).
            padding: const EdgeInsets.fromLTRB(
              TokensSpacing.m,
              TokensSpacing.xs,
              TokensSpacing.m,
              0,
            ),
            child: SharedNoteAuthor(
              authorId: note.authorId,
              authorName: note.authorName,
              authorAvatarUrl: note.authorAvatarUrl,
              trailing: note.updatedAt == null
                  ? null
                  : shortDate(note.updatedAt!),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              TokensSpacing.xs,
              0,
              TokensSpacing.xs,
              TokensSpacing.xs,
            ),
            child: AppCardTapArea(
              onTap: onOpen,
              padding: const EdgeInsets.all(TokensSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Los apuntes son «mente»: el color del módulo académico.
                  if (subject != null && subject.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: TokensSize.iconXs,
                          color: context.colors.tertiary,
                        ),
                        const SizedBox(width: TokensSpacing.xs),
                        Expanded(
                          child: Text(
                            subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textStyles.labelLarge?.copyWith(
                              color: context.colors.tertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TokensSpacing.xxs),
                  ],
                  Text(
                    note.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.titleMedium,
                  ),
                  if (note.excerpt.isNotEmpty) ...[
                    const SizedBox(height: TokensSpacing.xs),
                    Text(
                      note.excerpt,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: TokensSpacing.s),
                  AppPill(
                    label: context.visibilityLabel(note.visibility),
                    icon: context.visibilityIcon(note.visibility),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
