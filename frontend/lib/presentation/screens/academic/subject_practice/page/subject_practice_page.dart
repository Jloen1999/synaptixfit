import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/question_type.dart';
import '../../../../../domain/models/academic/subject_questions.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../create_questions/page/create_questions_sheet.dart';
import '../../widgets/academic_visuals.dart';
import '../../widgets/academic_widgets.dart';
import '../../widgets/question_view.dart';
import '../bloc/subject_practice_bloc.dart';

/// «Practicar» de una asignatura (ADR 0063): arriba cuántas preguntas hay y la
/// forma de practicar que toca (una sola acción principal: repaso de hoy o
/// práctica libre) con las demás; debajo, todas sus preguntas con buscador y
/// filtros. Cada pregunta se abre en una hoja para contestarla.
class SubjectPracticePage extends StatelessWidget {
  const SubjectPracticePage({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<SubjectPracticeBloc>()
          ..add(SubjectPracticeEvent.started(subjectId)),
    child: _SubjectPracticeView(subjectId: subjectId),
  );
}

class _SubjectPracticeView extends StatefulWidget {
  const _SubjectPracticeView({required this.subjectId});

  final String subjectId;

  @override
  State<_SubjectPracticeView> createState() => _SubjectPracticeViewState();
}

class _SubjectPracticeViewState extends State<_SubjectPracticeView> {
  /// El buscador se vacía también con «Quitar filtros».
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Abre una pantalla y, al volver, lee otra vez cómo van las preguntas.
  Future<void> _open(String location) async {
    final bloc = context.read<SubjectPracticeBloc>();
    await context.push<Object?>(location);
    bloc.add(const SubjectPracticeEvent.refreshed());
  }

  Future<void> _createQuestions() async {
    final bloc = context.read<SubjectPracticeBloc>();
    final bank = await showCreateQuestionsSheet(
      context,
      subjectId: widget.subjectId,
    );
    if (bank == null || !mounted) return;
    showQuestionsSavedSnack(context, bank);
    bloc.add(const SubjectPracticeEvent.refreshed());
  }

  /// Práctica libre de un apunte: si hay varios con preguntas, se elige antes.
  Future<void> _freePractice(SubjectPracticeState state) async {
    final materials = state.materials;
    if (materials.isEmpty) return;
    final id = materials.length == 1
        ? materials.single.id
        : await _chooseMaterial(context, materials);
    if (id == null || !mounted) return;
    await _open(AcademicPaths.freePractice(id));
  }

  void _clearFilters() {
    _search.clear();
    context.read<SubjectPracticeBloc>().add(
      const SubjectPracticeEvent.filtersCleared(),
    );
  }

  /// Espera a que termine de leer: el indicador no se va antes de tiempo.
  Future<void> _refresh() async {
    final bloc = context.read<SubjectPracticeBloc>()
      ..add(const SubjectPracticeEvent.refreshed());
    await bloc.stream.first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocBuilder<SubjectPracticeBloc, SubjectPracticeState>(
      builder: (context, state) {
        final name = state.questions?.subjectName ?? '';
        return Scaffold(
          appBar: AppPageBar(
            leading: AppBackButton(
              fallback: AcademicPaths.subject(widget.subjectId),
            ),
            title: Text(
              name.isEmpty
                  ? l10n.academicPracticeAction
                  : '${l10n.academicPracticeAction} · $name',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: switch (state) {
            SubjectPracticeState(loading: true) => const AppSkeletonList(
              height: 88,
            ),
            SubjectPracticeState(:final error?) => AppErrorView(
              error: error,
              onRetry: () => context.read<SubjectPracticeBloc>().add(
                SubjectPracticeEvent.started(widget.subjectId),
              ),
            ),
            // Sin preguntas ni repasos: solo el estado vacío con su acción.
            SubjectPracticeState(all: []) when state.due.isEmpty =>
              AppEmptyState(
                icon: AppIcons.practice,
                title: l10n.academicPracticeEmptyTitle,
                message: l10n.academicPracticeEmptyMessage,
                action: AppPrimaryButton(
                  label: l10n.academicCreateQuestions,
                  icon: AppIcons.proposal,
                  onPressed: _createQuestions,
                ),
              ),
            _ => RefreshIndicator(
              onRefresh: _refresh,
              child: AcademicBody(child: _content(context, state)),
            ),
          },
        );
      },
    );
  }

  Widget _content(BuildContext context, SubjectPracticeState state) {
    final l10n = context.localizations;
    final visible = state.visible;
    const gutter = EdgeInsets.symmetric(horizontal: TokensSpacing.m);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(TokensSpacing.m),
          sliver: SliverToBoxAdapter(
            child: _WaysCard(
              state: state,
              onReview: () => _open(
                AcademicPaths.review(
                  state.due.first.id,
                  queue: [for (final m in state.due.skip(1)) m.id],
                ),
              ),
              onFreePractice: () => _freePractice(state),
              onMockExam: () =>
                  _open(AcademicPaths.subjectMockExam(widget.subjectId)),
              onCreate: _createQuestions,
            ),
          ),
        ),
        if (state.all.isEmpty)
          SliverPadding(
            padding: gutter,
            sliver: SliverToBoxAdapter(
              child: AppEmptyState.compact(
                icon: AppIcons.practice,
                title: l10n.academicPracticeEmptyTitle,
              ),
            ),
          )
        else ...[
          SliverPadding(
            padding: gutter,
            sliver: SliverToBoxAdapter(
              child: _ListHeader(
                state: state,
                search: _search,
                onClear: _clearFilters,
              ),
            ),
          ),
          SliverPadding(
            padding: gutter,
            sliver: SliverList.separated(
              itemCount: visible.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => _QuestionRow(
                item: visible[i],
                query: state.query,
                onTap: () => _openQuestion(context, visible, i),
              ),
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: TokensSpacing.xl)),
      ],
    );
  }
}

/// Arriba: cuántas preguntas hay y cuántas tocan repasar, la forma de
/// practicar que toca con el único botón relleno de la pantalla y, debajo,
/// las demás como filas que se abren.
class _WaysCard extends StatelessWidget {
  const _WaysCard({
    required this.state,
    required this.onReview,
    required this.onFreePractice,
    required this.onMockExam,
    required this.onCreate,
  });

  final SubjectPracticeState state;
  final VoidCallback onReview;
  final VoidCallback onFreePractice;
  final VoidCallback onMockExam;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final total = state.all.length;
    final toReview = state.questions?.toReview ?? 0;
    final hasDue = state.due.isNotEmpty;
    final hasQuestions = total > 0;
    // Lo que toca: el repaso de hoy; si no hay, practicar.
    final (
      String title,
      String hint,
      String label,
      IconData icon,
      VoidCallback onPrimary,
    ) = hasDue
        ? (
            l10n.academicPracticeReviewTitle,
            l10n.academicPracticeReviewHint(state.due.length),
            l10n.academicReviewNow,
            AppIcons.review,
            onReview,
          )
        : (
            l10n.academicFreePracticeTitle,
            l10n.academicPracticeFreeHint,
            l10n.academicPracticeStart,
            AppIcons.start,
            onFreePractice,
          );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasQuestions) ...[
            Semantics(
              header: true,
              child: Text(
                '${l10n.academicQuestionsCount(total)} · '
                '${l10n.academicToReviewCount(toReview)}',
                style: context.textStyles.titleMedium,
              ),
            ),
            const SizedBox(height: TokensSpacing.m),
          ],
          Text(title, style: context.textStyles.titleSmall),
          Text(hint, style: context.textStyles.bodyMedium),
          const SizedBox(height: TokensSpacing.s),
          AppPrimaryButton(label: label, icon: icon, onPressed: onPrimary),
          const SizedBox(height: TokensSpacing.m),
          const Divider(height: 1),
          if (!hasDue)
            _WayRow(
              icon: AppIcons.review,
              title: l10n.academicPracticeReviewTitle,
              subtitle: l10n.academicPracticeNoReviewToday,
            ),
          if (hasDue && hasQuestions)
            _WayRow(
              icon: AppIcons.practice,
              title: l10n.academicFreePracticeTitle,
              subtitle: l10n.academicPracticeFreeHint,
              onTap: onFreePractice,
            ),
          if (hasQuestions)
            _WayRow(
              icon: AppIcons.exam,
              title: l10n.academicExamTitle,
              subtitle: l10n.academicPracticeExamHint,
              onTap: onMockExam,
            ),
          const SizedBox(height: TokensSpacing.s),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppSecondaryButton(
              label: l10n.academicCreateQuestions,
              icon: const Icon(AppIcons.proposal),
              onPressed: onCreate,
            ),
          ),
        ],
      ),
    );
  }
}

/// Otra forma de practicar: fila que se abre (con flecha) o, sin [onTap], una
/// nota de por qué no toca (sin flecha, para que no parezca un botón).
class _WayRow extends StatelessWidget {
  const _WayRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppFocusOutline(
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AppTintedIcon(icon: icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onTap == null ? null : const Icon(AppIcons.next),
      onTap: onTap,
    ),
  );
}

/// «Tus preguntas»: buscador, filtros y cuántas quedan (las filas van en una
/// lista perezosa debajo).
class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.state,
    required this.search,
    required this.onClear,
  });

  /// Lo que tarda en filtrar al escribir: el recuento no se anuncia en cada
  /// tecla.
  static const _searchDelay = Duration(milliseconds: 400);

  final SubjectPracticeState state;
  final TextEditingController search;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<SubjectPracticeBloc>();
    final visible = state.visible;
    final searching = state.query.trim().isNotEmpty;
    // Otros filtros además del texto: «Quitar filtros» también los quita.
    final otherFilters =
        state.standing != PracticeListFilter.all ||
        state.type != null ||
        state.materialId != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: l10n.academicPracticeYourQuestions),
        AppSearchField(
          label: l10n.academicPracticeSearch,
          controller: search,
          debounce: _searchDelay,
          onChanged: (q) => bloc.add(SubjectPracticeEvent.queryChanged(q)),
        ),
        const SizedBox(height: TokensSpacing.m),
        AppSegmentedChoice<PracticeListFilter>(
          label: l10n.academicPracticeFilterStanding,
          values: PracticeListFilter.values,
          selected: state.standing,
          labelOf: (f) => _filterLabel(context, f),
          onChanged: (f) => bloc.add(
            SubjectPracticeEvent.standingChanged(f ?? PracticeListFilter.all),
          ),
        ),
        _Dropdowns(state: state),
        const SizedBox(height: TokensSpacing.s),
        if (visible.isEmpty && searching)
          // Ya lo anuncia `AppSearchEmpty`: sin recuento encima.
          AppSearchEmpty(
            query: state.query,
            actionLabel: otherFilters
                ? l10n.academicPracticeClearFilters
                : null,
            actionIcon: AppIcons.clearFilters,
            onAction: otherFilters ? onClear : null,
          )
        else if (visible.isEmpty)
          _NoMatches(onClear: onClear)
        else
          // Cuántas quedan al filtrar: se lee al cambiar (región viva).
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.academicQuestionsCount(visible.length),
              style: context.textStyles.labelLarge?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(height: TokensSpacing.xs),
      ],
    );
  }

  static String _filterLabel(BuildContext context, PracticeListFilter f) {
    final l10n = context.localizations;
    return switch (f) {
      PracticeListFilter.all => l10n.academicPracticeFilterAll,
      PracticeListFilter.toReview => l10n.academicPracticeFilterToReview,
      PracticeListFilter.fresh => l10n.academicPracticeFilterNew,
      PracticeListFilter.correct => l10n.academicPracticeFilterCorrect,
    };
  }
}

/// Tipo y apunte: solo si hay más de uno. Uno al lado del otro si en cada
/// mitad cabe entero su texto más largo (ancho real, con el tamaño de letra
/// de la persona); si no, uno debajo del otro (texto grande, 320 px).
class _Dropdowns extends StatelessWidget {
  const _Dropdowns({required this.state});

  /// Lo que ocupa el campo además del texto: márgenes y la flecha.
  static const _chrome =
      TokensSpacing.m * 2 + TokensSize.iconM + TokensSpacing.s;

  final SubjectPracticeState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final bloc = context.read<SubjectPracticeBloc>();
    final types = state.types;
    final materials = state.materials;
    final typeLabels = <QuestionType?, String>{
      null: l10n.academicPracticeFilterAllTypes,
      for (final t in types) t: context.questionTypeLabel(t),
    };
    final materialLabels = <String?, String>{
      null: l10n.academicPracticeFilterAllTopics,
      for (final m in materials) m.id: m.title,
    };
    final fields = <(Widget, Iterable<String>)>[
      if (types.length > 1)
        (
          _field<QuestionType?>(
            context,
            // La clave reinicia el campo cuando el filtro cambia por fuera
            // («Quitar filtros»).
            key: ValueKey(('type', state.type)),
            label: l10n.academicPracticeFilterType,
            value: state.type,
            labels: typeLabels,
            onChanged: (t) => bloc.add(SubjectPracticeEvent.typeChanged(t)),
          ),
          typeLabels.values,
        ),
      if (materials.length > 1)
        (
          _field<String?>(
            context,
            key: ValueKey(('material', state.materialId)),
            label: l10n.academicPracticeFilterTopic,
            value: state.materialId,
            labels: materialLabels,
            onChanged: (id) =>
                bloc.add(SubjectPracticeEvent.materialChanged(id)),
          ),
          materialLabels.values,
        ),
    ];
    if (fields.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: TokensSpacing.m),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final half = (constraints.maxWidth - TokensSpacing.s) / 2;
          final style = context.textStyles.bodyLarge;
          final side =
              fields.length == 2 &&
              fields.every(
                (f) => f.$2.every(
                  (text) => context.textWidth(text, style) + _chrome <= half,
                ),
              );
          if (side) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: fields[0].$1),
                const SizedBox(width: TokensSpacing.s),
                Expanded(child: fields[1].$1),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, f) in fields.indexed) ...[
                if (i > 0) const SizedBox(height: TokensSpacing.m),
                f.$1,
              ],
            ],
          );
        },
      ),
    );
  }

  /// Desplegable: en el campo cerrado el texto se recorta a una línea; en el
  /// menú cada opción se lee entera (varias líneas si hace falta).
  static Widget _field<T>(
    BuildContext context, {
    required Key key,
    required String label,
    required T value,
    required Map<T, String> labels,
    required ValueChanged<T?> onChanged,
  }) => DropdownButtonFormField<T>(
    key: key,
    initialValue: value,
    isExpanded: true,
    itemHeight: null,
    decoration: InputDecoration(labelText: label),
    selectedItemBuilder: (context) => [
      for (final text in labels.values)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
    ],
    items: [
      for (final entry in labels.entries)
        DropdownMenuItem<T>(value: entry.key, child: Text(entry.value)),
    ],
    onChanged: onChanged,
  );
}

class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return AppEmptyState.compact(
      icon: AppIcons.clearFilters,
      title: l10n.academicPracticeNoMatches,
      action: AppSecondaryButton(
        label: l10n.academicPracticeClearFilters,
        icon: const Icon(AppIcons.clearFilters),
        onPressed: onClear,
      ),
    );
  }
}

/// Fila de una pregunta: enunciado, tipo y apunte, y cómo va (icono y texto,
/// nunca solo color). Se abre para contestarla.
class _QuestionRow extends StatelessWidget {
  const _QuestionRow({
    required this.item,
    required this.query,
    required this.onTap,
  });

  final SubjectQuestion item;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final question = item.question;
    return AppFocusOutline(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: AppHighlightedText(text: question.statement, query: query),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: TokensSpacing.xxs),
            Text(
              [
                context.questionTypeLabel(
                  question.type,
                  statement: question.statement,
                ),
                if (item.materialTitle.isNotEmpty) item.materialTitle,
              ].join(' · '),
            ),
            const SizedBox(height: TokensSpacing.xs),
            StandingPill(standing: item.standing),
          ],
        ),
        trailing: const Icon(AppIcons.next),
        onTap: onTap,
      ),
    );
  }
}

/// «¿De qué apunte?»: los apuntes y archivos con preguntas (el más urgente
/// primero). Devuelve el id elegido.
Future<String?> _chooseMaterial(
  BuildContext context,
  List<PracticeMaterial> materials,
) => showModalBottomSheet<String>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (sheetContext) {
    final l10n = sheetContext.localizations;
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
          TokensSpacing.m,
          0,
          TokensSpacing.m,
          TokensSpacing.l,
        ),
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.academicPracticeChooseTopic,
              style: sheetContext.textStyles.titleLarge,
            ),
          ),
          const SizedBox(height: TokensSpacing.s),
          for (final m in materials)
            AppFocusOutline(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(m.title),
                subtitle: Text(
                  m.toReview > 0
                      ? '${l10n.academicQuestionsCount(m.count)} · '
                            '${l10n.academicToReviewCount(m.toReview)}'
                      : l10n.academicQuestionsCount(m.count),
                ),
                trailing: const Icon(AppIcons.next),
                onTap: () => Navigator.of(sheetContext).pop(m.id),
              ),
            ),
        ],
      ),
    );
  },
);

/// Abre la pregunta [index] de [list] en una hoja para contestarla; al
/// cerrarla se lee otra vez cómo van.
Future<void> _openQuestion(
  BuildContext context,
  List<SubjectQuestion> list,
  int index,
) async {
  final bloc = context.read<SubjectPracticeBloc>();
  await showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: bloc,
      // Se guarda la lista al abrir: «Siguiente» no salta aunque cambie.
      child: QuestionSheet(questions: List.of(list), initialIndex: index),
    ),
  );
  if (bloc.state.results.isNotEmpty) {
    bloc.add(const SubjectPracticeEvent.refreshed());
  }
}

/// Hoja de una pregunta de la lista: la contesta con [QuestionView]
/// («Comprobar» o «No lo sé»); ya corregida, «Siguiente» pasa a la siguiente
/// (vuelve arriba y la anuncia) y, en la última, «Volver a la lista».
class QuestionSheet extends StatefulWidget {
  const QuestionSheet({
    super.key,
    required this.questions,
    required this.initialIndex,
  });

  final List<SubjectQuestion> questions;
  final int initialIndex;

  @override
  State<QuestionSheet> createState() => _QuestionSheetState();
}

class _QuestionSheetState extends State<QuestionSheet> with ErrorsMessageMixin {
  late int _index = widget.initialIndex;
  String _draft = '';
  ScrollController? _scroll;

  void _next() {
    setState(() {
      _index++;
      _draft = '';
    });
    _scroll?.jumpTo(0);
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        context.localizations.academicQuestionOf(
          _index + 1,
          widget.questions.length,
        ),
        Directionality.of(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final item = widget.questions[_index];
    final question = item.question;
    final hasNext = _index < widget.questions.length - 1;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, controller) {
        _scroll = controller;
        return SafeArea(
          child: BlocBuilder<SubjectPracticeBloc, SubjectPracticeState>(
            builder: (context, state) {
              final result = state.results[question.id];
              final bloc = context.read<SubjectPracticeBloc>();
              return ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(
                  TokensSpacing.m,
                  0,
                  TokensSpacing.m,
                  TokensSpacing.l,
                ),
                children: [
                  if (item.materialTitle.isNotEmpty)
                    Text(
                      l10n.academicPracticeFrom(item.materialTitle),
                      style: context.textStyles.labelLarge?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  QuestionView(
                    key: ValueKey(question.id),
                    header: l10n.academicQuestionOf(
                      _index + 1,
                      widget.questions.length,
                    ),
                    statement: question.statement,
                    type: question.type,
                    options: question.options,
                    answer: result == null
                        ? _draft
                        : state.answers[question.id],
                    onAnswerChanged: (v) => setState(() => _draft = v),
                    feedback: result == null
                        ? null
                        : QuestionFeedback(
                            correct: result.correct,
                            dontKnow: result.dontKnow,
                            correctAnswer:
                                result.correctAnswer ?? question.correctAnswer,
                            correctAnswers: result.correctAnswers.isNotEmpty
                                ? result.correctAnswers
                                : question.correctAnswers,
                            explanation:
                                result.explanation ?? question.explanation,
                          ),
                  ),
                  if (state.actionError case final error? when result == null)
                    Padding(
                      padding: const EdgeInsets.only(top: TokensSpacing.m),
                      child: AppInlineMessage(
                        message: errorMessage(context, error),
                      ),
                    ),
                  const SizedBox(height: TokensSpacing.l),
                  // Un solo hueco: al corregir, «Siguiente» (o «Volver a la
                  // lista», con borde) ocupa el sitio de «Comprobar» y se
                  // queda con el foco.
                  QuestionAnswerBar(
                    questionId: question.id,
                    answered: result != null,
                    outlined: result != null && !hasNext,
                    primaryLabel: result == null
                        ? l10n.academicCheck
                        : hasNext
                        ? l10n.academicNext
                        : l10n.academicPracticeBackToList,
                    primaryIcon: result != null && hasNext
                        ? AppIcons.next
                        : null,
                    busy: state.checkingId == question.id,
                    onPrimary: result != null
                        ? (hasNext ? _next : () => Navigator.of(context).pop())
                        : _draft.trim().isEmpty
                        ? null
                        : () => bloc.add(
                            SubjectPracticeEvent.answered(
                              questionId: question.id,
                              answer: _draft,
                            ),
                          ),
                    onDontKnow: () =>
                        bloc.add(SubjectPracticeEvent.dontKnow(question.id)),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
