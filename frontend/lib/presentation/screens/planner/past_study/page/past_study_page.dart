import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../bloc/past_study_bloc.dart';

/// «Apuntar estudio hecho» (`/planner/past-study`): un rato de estudio que se
/// hizo sin la app («ayer estudié Cálculo de 17:00 a 18:30»). Se elige
/// asignatura, día (hoy o los 6 anteriores), hora y duración; queda como bloque
/// hecho y cuenta como cualquier otro en la semana, la XP y la carga cognitiva.
class PastStudyPage extends StatelessWidget {
  const PastStudyPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<PastStudyBloc>()..add(const PastStudyEvent.started()),
    child: const PastStudyView(),
  );
}

/// Formulario de [PastStudyPage] (separado para probarlo con un bloc falso).
class PastStudyView extends StatefulWidget {
  const PastStudyView({super.key, this.now});

  /// Reloj para los tests; por defecto, la hora actual.
  final DateTime Function()? now;

  @override
  State<PastStudyView> createState() => _PastStudyViewState();
}

class _PastStudyViewState extends State<PastStudyView> with ErrorsMessageMixin {
  /// Días que se pueden elegir: hoy y los 6 anteriores (el servidor admite 7).
  static const _days = 7;

  final _title = TextEditingController();
  late final DateTime Function() _now = widget.now ?? DateTime.now;
  // Por defecto, hace dos horas; de madrugada, ayer a las 22:00 (si no, la
  // hora quedaría a las 0:00 y una hora de estudio aún no habría terminado).
  late final bool _earlyMorning = _now().hour < 2;
  late DateTime _day = DateUtils.dateOnly(
    _earlyMorning ? _now().subtract(const Duration(days: 1)) : _now(),
  );
  late TimeOfDay _time = TimeOfDay(
    hour: _earlyMorning ? 22 : _now().hour - 2,
    minute: 0,
  );
  int _minutes = 60;
  String? _subjectId;
  String? _notFinished;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  DateTime get _start =>
      DateTime(_day.year, _day.month, _day.day, _time.hour, _time.minute);

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() {
        _time = picked;
        _notFinished = null;
      });
    }
  }

  /// Aviso inmediato si aún no ha terminado (el servidor lo comprueba igual).
  void _save() {
    final l10n = context.localizations;
    if (_start.add(Duration(minutes: _minutes)).isAfter(_now())) {
      setState(() => _notFinished = l10n.plannerPastStudyNotFinished);
      return;
    }
    setState(() => _notFinished = null);
    context.read<PastStudyBloc>().add(
      PastStudyEvent.submitted(
        start: _start,
        minutes: _minutes,
        subjectId: _subjectId,
        title: _title.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final today = DateUtils.dateOnly(_now());
    return BlocConsumer<PastStudyBloc, PastStudyState>(
      listenWhen: (a, b) => a.savedXp == null && b.savedXp != null,
      listener: (context, state) {
        if (state.updatedAccount case final account?) {
          context.read<SessionBloc>().add(SessionEvent.accountUpdated(account));
        }
        context.showSnack(l10n.plannerPastStudySaved);
        if (context.canPop()) context.pop(true);
      },
      builder: (context, state) => Scaffold(
        appBar: AppPageBar.reading(title: Text(l10n.plannerPastStudyTitle)),
        body: AppContentWidth.reading(
          child: ListView(
            padding: const EdgeInsets.all(TokensSpacing.m),
            children: [
              Text(
                l10n.plannerPastStudyIntro,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: TokensSpacing.l),
              if (state.subjectsFailed) ...[
                AppInlineMessage(
                  message: l10n.plannerPastStudySubjectsFailed,
                  tone: AppMessageTone.warning,
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => context.read<PastStudyBloc>().add(
                      const PastStudyEvent.started(),
                    ),
                    child: Text(l10n.plannerPastStudyRetry),
                  ),
                ),
                const SizedBox(height: TokensSpacing.s),
              ],
              if (state.loadingSubjects)
                // Mismo alto que el campo: no salta lo de abajo al cargar.
                Semantics(
                  label: l10n.commonLoading,
                  child: const AppSkeleton(height: TokensSize.controlHeight),
                )
              else
                DropdownButtonFormField<String?>(
                  initialValue: _subjectId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.plannerPastStudySubject,
                    prefixIcon: const Icon(Icons.school_outlined),
                  ),
                  items: [
                    DropdownMenuItem(
                      child: Text(l10n.plannerPastStudyNoSubject),
                    ),
                    for (final subject in state.subjects)
                      DropdownMenuItem(
                        value: subject.id,
                        child: Text(
                          subject.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (id) => setState(() => _subjectId = id),
                ),
              const SizedBox(height: TokensSpacing.m),
              AppTextField(
                controller: _title,
                label: l10n.plannerPastStudyWhat,
                icon: Icons.menu_book_rounded,
                textInputAction: TextInputAction.done,
                maxLength: 200,
              ),
              const SizedBox(height: TokensSpacing.m),
              AppSectionHeader(title: l10n.plannerPastStudyWhen),
              Wrap(
                spacing: TokensSpacing.s,
                runSpacing: TokensSpacing.s,
                children: [
                  for (var i = 0; i < _days; i++)
                    Builder(
                      builder: (context) {
                        final day = today.subtract(Duration(days: i));
                        final label = switch (i) {
                          0 => l10n.plannerPastStudyToday,
                          1 => l10n.plannerPastStudyYesterday,
                          _ => toBeginningOfSentenceCase(
                            DateFormat.MEd(l10n.localeName).format(day),
                          ),
                        };
                        return ChoiceChip(
                          label: Text(label),
                          selected: DateUtils.isSameDay(day, _day),
                          onSelected: (_) => setState(() {
                            _day = day;
                            _notFinished = null;
                          }),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: TokensSpacing.m),
              AppCard(
                padding: EdgeInsets.zero,
                child: AppFocusOutline(
                  child: ListTile(
                    leading: const Icon(Icons.schedule_rounded),
                    title: Text(l10n.plannerPastStudyStart),
                    trailing: Text(
                      _time.format(context),
                      style: context.textStyles.titleMedium,
                    ),
                    onTap: _pickTime,
                  ),
                ),
              ),
              const SizedBox(height: TokensSpacing.m),
              AppStepperField(
                label: l10n.plannerPastStudyDuration,
                value: _minutes,
                min: 30,
                max: 300,
                step: 15,
                display: l10n.plannerPastStudyMinutes,
                onChanged: (v) => setState(() {
                  _minutes = v;
                  _notFinished = null;
                }),
              ),
              const SizedBox(height: TokensSpacing.l),
              if (_notFinished case final message?) ...[
                AppInlineMessage(message: message),
                const SizedBox(height: TokensSpacing.m),
              ],
              if (state.error case final error?) ...[
                AppInlineMessage(message: errorMessage(context, error)),
                const SizedBox(height: TokensSpacing.m),
              ],
              AppPrimaryButton(
                label: l10n.plannerPastStudySave,
                icon: Icons.check_rounded,
                loading: state.submitting,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
