import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/study_source_type.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_widgets.dart';
import '../bloc/mock_exam_setup_bloc.dart';

/// Preparar un simulacro de asignatura: elegir qué temas entran y cuántas
/// preguntas, y empezar. Mezcla preguntas de varios apuntes y archivos.
class MockExamSetupPage extends StatelessWidget {
  const MockExamSetupPage({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<MockExamSetupBloc>()..add(MockExamSetupEvent.started(subjectId)),
    child: const _MockExamSetupView(),
  );
}

class _MockExamSetupView extends StatelessWidget {
  const _MockExamSetupView();

  void _start(BuildContext context, MockExamSetupState state) {
    final ids = state.orderedSelection;
    context.pushReplacement(
      AcademicPaths.exam(
        ids.first,
        withMaterials: ids.skip(1).toList(),
        count: state.count,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocBuilder<MockExamSetupBloc, MockExamSetupState>(
      builder: (context, state) {
        final bloc = context.read<MockExamSetupBloc>();
        final ready = state.options != null && state.sources.isNotEmpty;
        return Scaffold(
          appBar: AppPageBar(title: Text(l10n.academicMockSetupTitle)),
          bottomNavigationBar: ready
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(TokensSpacing.m),
                    // En escritorio el botón no se estira más que el texto.
                    child: Center(
                      heightFactor: 1,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: TokensLayout.readingMaxWidth,
                        ),
                        child: AppPrimaryButton(
                          label: state.canStart
                              ? l10n.academicMockSetupStart(state.count)
                              : l10n.academicMockSetupPickOne,
                          icon: Icons.play_arrow_rounded,
                          onPressed: state.canStart
                              ? () => _start(context, state)
                              : null,
                        ),
                      ),
                    ),
                  ),
                )
              : null,
          body: switch (state) {
            MockExamSetupState(loading: true) => const AppSkeletonList(
              count: 4,
            ),
            MockExamSetupState(:final error?) => AppErrorView(
              error: error,
              onRetry: () =>
                  bloc.add(MockExamSetupEvent.started(state.subjectId)),
            ),
            _ when !ready => AppEmptyState(
              icon: Icons.quiz_outlined,
              title: l10n.academicMockSetupEmptyTitle,
              message: l10n.academicMockSetupEmptyMessage,
              action: AppSecondaryButton(
                label: l10n.academicMockSetupEmptyAction,
                icon: const Icon(AppIcons.back),
                onPressed: () => context.pop(),
              ),
            ),
            _ => _Form(state: state),
          },
        );
      },
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.state});

  final MockExamSetupState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<MockExamSetupBloc>();
    final options = state.options!;
    return AcademicBody(
      child: ListView(
        padding: const EdgeInsets.all(TokensSpacing.m),
        children: [
          Text(
            l10n.academicMockSetupIntro,
            style: context.textStyles.bodyLarge,
          ),
          const SizedBox(height: TokensSpacing.l),
          AppSectionHeader(
            title: l10n.academicMockSetupWhat,
            actionLabel: state.allSelected
                ? l10n.academicMockSetupNone
                : options.sources.length > options.maxMaterials
                ? l10n.academicMockSetupAllFirst(options.maxMaterials)
                : l10n.academicMockSetupAll,
            onAction: () => bloc.add(const MockExamSetupEvent.allToggled()),
          ),
          if (options.sources.length > options.maxMaterials)
            Padding(
              padding: const EdgeInsets.only(bottom: TokensSpacing.s),
              child: Text(
                l10n.academicMockSetupLimit(options.maxMaterials),
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final source in state.sources)
                  AppFocusOutline(
                    child: CheckboxListTile(
                      value: state.selected.contains(source.materialId),
                      onChanged:
                          state.selected.contains(source.materialId) ||
                              !state.atMaterialLimit
                          ? (_) => bloc.add(
                              MockExamSetupEvent.sourceToggled(
                                source.materialId,
                              ),
                            )
                          : null,
                      secondary: Icon(
                        source.originType == StudySourceType.file
                            ? Icons.description_outlined
                            : Icons.sticky_note_2_outlined,
                      ),
                      title: Text(
                        source.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        state.selected.contains(source.materialId) ||
                                !state.atMaterialLimit
                            ? l10n.academicMockSetupQuestions(
                                source.questionCount,
                              )
                            : l10n.academicMockSetupMaxReached(
                                l10n.academicMockSetupQuestions(
                                  source.questionCount,
                                ),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: TokensSpacing.l),
          AppSectionHeader(title: l10n.academicMockSetupHowMany),
          if (state.countChoices.isEmpty)
            Text(l10n.academicMockSetupPickOne)
          else ...[
            Wrap(
              spacing: TokensSpacing.s,
              runSpacing: TokensSpacing.s,
              children: [
                for (final c in state.countChoices)
                  ChoiceChip(
                    label: Text(l10n.academicMockSetupQuestions(c)),
                    selected: state.count == c,
                    onSelected: (_) =>
                        bloc.add(MockExamSetupEvent.countChanged(c)),
                  ),
              ],
            ),
            const SizedBox(height: TokensSpacing.s),
            Text(
              l10n.academicMockSetupAvailable(state.available),
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: TokensSpacing.xxl),
        ],
      ),
    );
  }
}
