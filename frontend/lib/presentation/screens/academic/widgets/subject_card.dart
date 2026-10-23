import 'package:flutter/material.dart';

import '../../../../domain/models/academic/subject.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'academic_visuals.dart';

/// Tarjeta de asignatura: franja de color, siglas destacadas y recuento de
/// apuntes y archivos.
class SubjectCard extends StatelessWidget {
  const SubjectCard({super.key, required this.subject, required this.onTap});

  final Subject subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = subjectColor(context, subject.id);
    final l10n = context.localizations;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: AppFocusOutline(
        borderRadius: BorderRadius.circular(TokensRadius.l),
        child: InkWell(
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(TokensSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              subjectAcronym(subject),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textStyles.headlineSmall?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (subject.archived)
                            Icon(
                              Icons.archive_outlined,
                              size: 18,
                              color: context.colors.onSurfaceVariant,
                              semanticLabel: l10n.academicSubjectArchivedBadge,
                            ),
                        ],
                      ),
                      const SizedBox(height: TokensSpacing.xs),
                      Text(
                        subject.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.titleSmall,
                      ),
                      const Spacer(),
                      Text(
                        l10n.academicSubjectCounts(
                          subject.noteCount,
                          subject.fileCount,
                        ),
                        style: context.textStyles.labelMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
