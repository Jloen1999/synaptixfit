import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/enums/syllabus_topic_kind.dart';
import '../../../../../domain/models/academic/teaching_guide.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/academic_widgets.dart';
import '../bloc/subject_progress_bloc.dart';
import 'guide_import_entry.dart';
import 'subject_tab_body.dart';

/// Pestaña Temario (ADR 0057): «4 de 10 temas hechos», la barra y cada tema de
/// la guía docente con su casilla para marcarlo como estudiado.
class TopicsTab extends StatelessWidget {
  const TopicsTab({super.key});

  @override
  Widget build(BuildContext context) => SubjectTabBody(
    children: (context, state) {
      final guide = state.guide;
      final l10n = context.localizations;
      if (guide == null) {
        return [
          GuideMissingView(
            subjectId: state.subjectId,
            icon: Icons.checklist_rounded,
            title: l10n.academicTopicsEmptyTitle,
            message: l10n.academicTopicsEmptyMessage,
          ),
        ];
      }
      if (guide.topics.isEmpty) {
        return [
          GuideMissingView(
            subjectId: state.subjectId,
            icon: Icons.checklist_rounded,
            title: l10n.academicGuideNoTopics,
            guide: guide,
          ),
        ];
      }
      return [_TopicsHeader(guide: guide), _TopicsList(guide: guide)];
    },
  );
}

class _TopicsHeader extends StatelessWidget {
  const _TopicsHeader({required this.guide});

  final TeachingGuide guide;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final done = guide.topicsDone;
    final total = guide.topics.length;
    final percent = (done * 100 / total).round();
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.academicTopicsDoneHeader(done, total),
                    style: context.textStyles.titleMedium,
                  ),
                ),
              ),
              Text(
                l10n.academicPercent(percent),
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.s),
          ExcludeSemantics(
            child: AcademicProgressBar(
              value: done / total,
              color: context.palette.study,
            ),
          ),
          const SizedBox(height: TokensSpacing.s),
          Text(
            l10n.academicTopicsHint,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicsList extends StatelessWidget {
  const _TopicsList({required this.guide});

  final TeachingGuide guide;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: TokensSpacing.xs),
      child: Column(
        children: [
          for (final (i, topic) in guide.topics.indexed) ...[
            if (i > 0) const Divider(height: 1),
            AppFocusOutline(
              child: CheckboxListTile(
                controlAffinity: ListTileControlAffinity.leading,
                value: topic.completed,
                onChanged: (v) => context.read<SubjectProgressBloc>().add(
                  SubjectProgressEvent.topicToggled(
                    index: topic.index,
                    completed: v ?? false,
                  ),
                ),
                title: Text(
                  topic.title,
                  style: topic.completed
                      ? context.textStyles.bodyLarge?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        )
                      : null,
                ),
                subtitle: Text(
                  [
                    topic.kind == SyllabusTopicKind.practice
                        ? l10n.academicTopicPractice
                        : l10n.academicTopicTheory,
                    if (topic.hours != null)
                      l10n.academicImportHours(topic.hours!.round()),
                    if (topic.subtopics.isNotEmpty)
                      l10n.academicImportSubtopics(topic.subtopics.length),
                  ].join(' · '),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
