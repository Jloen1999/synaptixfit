import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/training/routine.dart';
import '../../../../../domain/models/training/sport_activity.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../l10n/gen_l10n/app_localizations.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../../auth/session/bloc/session_bloc.dart';
import '../../activity_history/page/activity_history_view.dart';
import '../../training_routes.dart';
import '../../widgets/sport_labels.dart';
import '../../widgets/training_labels.dart';
import '../../widgets/training_section_bar.dart';
import '../bloc/past_activity_bloc.dart';

/// «Apuntar actividad» (`/training/past-activity`): deporte hecho sin la app
/// («ayer jugué al fútbol una hora») o un día de tu rutina que entrenaste sin
/// ella. Se elige el tipo (y la distancia si se mide así), cuándo, a qué hora
/// y cuánto; al guardar se pide el esfuerzo, como al marcar un bloque de
/// deporte. [from] es el apartado desde el que se abrió (nulo: el historial):
/// el aviso final dice dónde queda según a dónde se vuelve.
///
/// Con [sport] (elegido en «Deportes», ADR 0068) es el formulario de ese
/// deporte, sin elegir tipo: partido o entreno con resultado opcional en los
/// de partido, metros en natación, kilómetros en correr, andar o bici y el
/// nombre ([sportName]) en «otro deporte».
class PastActivityPage extends StatelessWidget {
  const PastActivityPage({super.key, this.from, this.sport, this.sportName});

  final TrainingSection? from;
  final Sport? sport;
  final String? sportName;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<PastActivityBloc>(),
    child: _PastActivityView(from: from, sport: sport, sportName: sportName),
  );
}

class _PastActivityView extends StatefulWidget {
  const _PastActivityView({
    required this.from,
    required this.sport,
    required this.sportName,
  });

  final TrainingSection? from;
  final Sport? sport;
  final String? sportName;

  @override
  State<_PastActivityView> createState() => _PastActivityViewState();
}

class _PastActivityViewState extends State<_PastActivityView>
    with ErrorsMessageMixin {
  /// Días que se pueden elegir: hoy y los 6 anteriores (el servidor admite 7).
  static const _days = 7;

  final _title = TextEditingController();
  final _distance = TextEditingController();

  /// Deporte del formulario (nulo: el formulario general, con «Tipo»). En
  /// correr, andar o bici se puede cambiar entre los tres.
  late Sport? _sport = widget.sport;

  /// Nombre de «otro deporte» y datos de un partido.
  late final _name = TextEditingController(text: widget.sportName);
  final _score = TextEditingController();
  String? _nameError;
  SportMode _mode = SportMode.match;
  MatchResult? _result;

  bool get _isMatch =>
      _sport?.category == SportCategory.match && _mode == SportMode.match;

  /// Tipo elegido: decide si se pide la distancia y en qué unidad.
  late ActivityKind? _kind = widget.sport?.kind;

  /// Nadando la distancia va en metros (largos de piscina); lo demás, en km.
  bool get _inMeters => _kind == ActivityKind.swim;
  String? _distanceError;
  late DateTime _day = DateUtils.dateOnly(DateTime.now());
  TimeOfDay _time = TimeOfDay(
    hour: (DateTime.now().hour - 2).clamp(0, 23),
    minute: 0,
  );
  int _minutes = 60;
  String? _notFinished;

  /// Apuntar un día de la rutina en curso en lugar de otro deporte.
  bool _routineMode = false;
  String? _routineDayId;

  @override
  void dispose() {
    _title.dispose();
    _distance.dispose();
    _name.dispose();
    _score.dispose();
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

  void _setRoutineMode(bool value) {
    setState(() {
      _routineMode = value;
      // Un día de rutina dura al menos 30 min (lo que admite el servidor).
      if (value && _minutes < 30) _minutes = 30;
    });
    if (value) {
      context.read<PastActivityBloc>().add(
        const PastActivityEvent.routineRequested(),
      );
    }
  }

  /// Días de la rutina que se pueden apuntar, en orden (con ejercicios).
  static List<(RoutineWeek, RoutineDay)> _routineDays(Routine routine) => [
    for (final week in routine.weeks)
      for (final day in week.days)
        if (day.exercises.isNotEmpty) (week, day),
  ];

  Future<void> _saveRoutineDay(PastActivityState state) async {
    final l10n = context.localizations;
    final routine = state.routine;
    final dayId = _routineDayId ?? state.pendingDayId;
    if (routine == null || dayId == null) return;
    final bloc = context.read<PastActivityBloc>();
    final effort = await showEffortDialog(
      context,
      confirmLabel: l10n.trainingPastActivitySave,
      subtitle: routine.name,
    );
    if (effort == null) return;
    bloc.add(
      PastActivityEvent.routineSessionSubmitted(
        routineId: routine.id,
        dayId: dayId,
        date: _day,
        minutes: _minutes,
        rpe: effort,
      ),
    );
  }

  /// Metros escritos en km («5» o «5,5») o, nadando, en metros («1500»);
  /// nulo si no se pide o está vacío y -1 si no es un número.
  int? _distanceMeters() {
    if (!(_kind?.measuresDistance ?? false)) return null;
    final text = _distance.text.trim();
    if (text.isEmpty) return null;
    if (_inMeters) {
      return int.tryParse(text.replaceAll(RegExp(r'[\s.,]'), '')) ?? -1;
    }
    final km = double.tryParse(text.replaceAll(',', '.'));
    return km == null ? -1 : (km * 1000).round();
  }

  Future<void> _save() async {
    final l10n = context.localizations;
    final meters = _distanceMeters();
    if (meters != null && (meters < 100 || meters > 300000)) {
      setState(
        () => _distanceError = _inMeters
            ? l10n.trainingPastActivityMetersInvalid
            : l10n.trainingPastActivityDistanceInvalid,
      );
      return;
    }
    setState(() => _distanceError = null);
    final sport = _sport;
    final name = _name.text.trim();
    if (sport == Sport.other && name.isEmpty) {
      setState(() => _nameError = l10n.sportOtherNameRequired);
      return;
    }
    // El evento del calendario se llama como el deporte.
    final title = switch (sport) {
      null => _title.text,
      Sport.other => name,
      _ => SportLabels.name(l10n, sport),
    };
    final end = _start.add(Duration(minutes: _minutes));
    if (end.isAfter(DateTime.now())) {
      setState(() => _notFinished = l10n.trainingPastActivityNotFinished);
      return;
    }
    setState(() => _notFinished = null);
    final bloc = context.read<PastActivityBloc>();
    final effort = await showEffortDialog(
      context,
      confirmLabel: l10n.trainingPastActivitySave,
      subtitle: title.trim().isEmpty ? null : title.trim(),
    );
    if (effort == null) return;
    bloc.add(
      PastActivityEvent.submitted(
        start: _start,
        minutes: _minutes,
        effort: effort,
        title: title,
        kind: _kind,
        distanceMeters: meters,
        // Qué vale en cada deporte lo decide el servidor: aquí va lo elegido.
        sport: sport == null
            ? null
            : SportEntry(
                sport: sport,
                name: sport == Sport.other ? name : null,
                mode: sport.category == SportCategory.match ? _mode : null,
                result: _isMatch ? _result : null,
                scoreText: _isMatch && _score.text.trim().isNotEmpty
                    ? _score.text.trim()
                    : null,
              ),
      ),
    );
  }

  /// Aviso al guardar: dice dónde queda según a dónde se vuelve. Si al
  /// volver no se ve, lleva «Ver» (con el router: la página ya se ha cerrado).
  void _announceSaved(BuildContext context, int xp) {
    final l10n = context.localizations;
    final router = GoRouter.of(context);
    void withView(String text, String location) => context.showActionSnack(
      text,
      actionLabel: l10n.commonView,
      onAction: () => router.push(location),
    );
    if (_routineMode) {
      final text = l10n.trainingPastActivityRoutineSaved;
      // Desde el historial ya se está al lado, en su pestaña «Entrenos».
      widget.from == null
          ? context.showSnack(text)
          : withView(text, TrainingPaths.history);
      return;
    }
    switch (widget.from) {
      // Se vuelve a Correr, que enseña «Tus actividades».
      case TrainingSection.run:
        context.showSnack(l10n.trainingPastActivitySavedRun);
      // Se vuelve al historial, a «Actividades y partidos».
      case null:
        context.showSnack(l10n.trainingPastActivitySaved);
      // Desde WOD no se apunta una actividad a mano: la crea su marca.
      case TrainingSection.gym || TrainingSection.wod:
        withView(l10n.trainingPastActivitySaved, TrainingPaths.activities);
    }
  }

  /// Elegir el día de la rutina en curso (por defecto, el que toca).
  List<Widget> _routineSection(BuildContext context, PastActivityState state) {
    final l10n = context.localizations;
    if (state.routineError case final error?) {
      return [
        AppErrorView(
          error: error,
          onRetry: () => context.read<PastActivityBloc>().add(
            const PastActivityEvent.routineRequested(),
          ),
        ),
      ];
    }
    if (state.loadingRoutine || !state.routineLoaded) {
      return const [AppLoadingView()];
    }
    final routine = state.routine;
    if (routine == null) {
      return [
        AppCard(
          child: AppEmptyState.compact(
            icon: Icons.fitness_center_rounded,
            title: l10n.trainingPastActivityModeRoutine,
            message: l10n.trainingPastActivityNoRoutine,
          ),
        ),
      ];
    }
    final selected = _routineDayId ?? state.pendingDayId;
    return [
      AppSectionHeader(title: l10n.trainingPastActivityRoutineDay),
      Wrap(
        spacing: TokensSpacing.s,
        runSpacing: TokensSpacing.s,
        children: [
          for (final (week, day) in _routineDays(routine))
            ChoiceChip(
              avatar: day.status.isClosed
                  ? Icon(
                      day.status.icon,
                      size: TokensSize.iconXs,
                      semanticLabel: day.status.label(l10n),
                    )
                  : null,
              label: Text(
                '${weekTitle(l10n, week.number, week.name)} · '
                '${dayTitle(l10n, day.dayNumber, day.name)}',
              ),
              selected: selected == day.id,
              onSelected: (_) => setState(() => _routineDayId = day.id),
            ),
        ],
      ),
    ];
  }

  /// Campo de la distancia: metros nadando, kilómetros en lo demás.
  Widget _distanceField(AppLocalizations l10n) => AppTextField(
    controller: _distance,
    label: _inMeters
        ? l10n.trainingPastActivityMeters
        : l10n.trainingPastActivityDistance,
    icon: Icons.straighten_rounded,
    keyboardType: TextInputType.numberWithOptions(decimal: !_inMeters),
    textInputAction: TextInputAction.done,
    suffixText: _inMeters
        ? l10n.trainingPastActivityMetersSuffix
        : l10n.trainingPastActivityKmSuffix,
    helper: _inMeters
        ? l10n.trainingPastActivityMetersHint
        : l10n.trainingPastActivityDistanceHint,
    // El error va en el propio campo (el lector lo lee con él) y sustituye
    // a la ayuda mientras se ve.
    errorText: _distanceError,
    onChanged: (_) => setState(() => _distanceError = null),
  );

  /// Lo propio del deporte elegido en «Deportes»: cuál de los tres (correr,
  /// andar o bici) y la distancia, partido o entreno, o el nombre.
  List<Widget> _sportSection(AppLocalizations l10n, Sport sport) => [
    if (sport.recordsWithGps) ...[
      AppSegmentedChoice<Sport>(
        label: l10n.trainingPastActivityKind,
        values: const [Sport.run, Sport.walk, Sport.bike],
        selected: sport,
        labelOf: (s) => SportLabels.name(l10n, s),
        onChanged: (s) => setState(() {
          _sport = s;
          _kind = s?.kind ?? _kind;
        }),
      ),
      const SizedBox(height: TokensSpacing.m),
    ],
    if (sport.category == SportCategory.match)
      AppSegmentedChoice<SportMode>(
        label: l10n.sportModeLabel,
        values: SportMode.values,
        selected: _mode,
        labelOf: (m) => SportLabels.mode(l10n, m),
        onChanged: (m) => setState(() => _mode = m ?? _mode),
      ),
    if (sport == Sport.other)
      AppTextField(
        controller: _name,
        label: l10n.sportOtherNameLabel,
        icon: Icons.sports_rounded,
        textInputAction: TextInputAction.done,
        maxLength: SportEntry.nameMax,
        errorText: _nameError,
        onChanged: (_) => setState(() => _nameError = null),
      ),
    if (sport.kind.measuresDistance) _distanceField(l10n),
  ];

  /// Resultado de un partido: opcional, y el marcador como se quiera escribir.
  Widget _resultCard(AppLocalizations l10n) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(title: l10n.sportResultTitle),
        AppSegmentedChoice<MatchResult>(
          label: l10n.sportResultLabel,
          values: MatchResult.values,
          selected: _result,
          allowEmpty: true,
          labelOf: (r) => SportLabels.result(l10n, r),
          onChanged: (r) => setState(() => _result = r),
        ),
        const SizedBox(height: TokensSpacing.m),
        AppTextField(
          controller: _score,
          label: l10n.sportScoreLabel,
          icon: Icons.scoreboard_outlined,
          textInputAction: TextInputAction.done,
          maxLength: SportEntry.scoreMax,
          helper: l10n.sportScoreHint,
        ),
      ],
    ),
  );

  /// Desde Correr vuelve a Correr; si no, al historial («Actividades y
  /// partidos»), donde queda lo apuntado.
  String get _back => widget.from == TrainingSection.run
      ? TrainingPaths.section(TrainingSection.run)
      : TrainingPaths.activities;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final today = DateUtils.dateOnly(DateTime.now());
    final sport = _sport;
    // Nombres rápidos para lo que no tiene tipo propio (partido u otro
    // deporte); correr, andar, bici y nadar ya se eligen en «Tipo».
    final suggestions = [
      (l10n.trainingPastActivityFootball, ActivityKind.match),
      (l10n.trainingPastActivityPadel, ActivityKind.match),
      (l10n.trainingPastActivityGym, ActivityKind.other),
    ];
    return BlocConsumer<PastActivityBloc, PastActivityState>(
      listenWhen: (a, b) =>
          (a.savedXp == null && b.savedXp != null) ||
          (b.error != null && a.error != b.error),
      listener: (context, state) {
        final xp = state.savedXp;
        if (xp != null) {
          if (state.updatedAccount case final account?) {
            context.read<SessionBloc>().add(
              SessionEvent.accountUpdated(account),
            );
          }
          _announceSaved(context, xp);
          context.popOrGo(_back, true);
        }
      },
      builder: (context, state) => Scaffold(
        appBar: AppPageBar.reading(
          leading: AppBackButton(fallback: _back),
          title: Text(
            sport == null
                ? l10n.trainingPastActivityTitle
                : sport.recordsWithGps
                ? l10n.sportEnduranceTitle
                : SportLabels.name(l10n, sport),
          ),
        ),
        body: AppContentWidth.reading(
          child: ListView(
            padding: const EdgeInsets.all(TokensSpacing.m),
            children: [
              // Desde Correr solo se apunta deporte: el día de la rutina se
              // apunta desde Gimnasio o el historial, donde se busca.
              if (sport != null) ...[
                SportPhotoHeader(sport: sport),
                const SizedBox(height: TokensSpacing.m),
              ],
              if (widget.from != TrainingSection.run && sport == null) ...[
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text(l10n.trainingPastActivityModeOther),
                      icon: const Icon(Icons.sports_soccer_outlined),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text(l10n.trainingPastActivityModeRoutine),
                      icon: const Icon(Icons.fitness_center_rounded),
                    ),
                  ],
                  selected: {_routineMode},
                  onSelectionChanged: (s) => _setRoutineMode(s.first),
                ),
                const SizedBox(height: TokensSpacing.m),
              ],
              Text(
                _routineMode
                    ? l10n.trainingPastActivityRoutineIntro
                    : l10n.trainingPastActivityIntro,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: TokensSpacing.m),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_routineMode)
                      ..._routineSection(context, state)
                    else if (sport != null)
                      ..._sportSection(l10n, sport)
                    else ...[
                      AppSectionHeader(title: l10n.trainingPastActivityWhat),
                      AppSegmentedChoice<ActivityKind>(
                        label: l10n.trainingPastActivityKind,
                        values: ActivityKind.values,
                        selected: _kind,
                        labelOf: (k) => activityKindLabel(l10n, k),
                        onChanged: (k) => setState(() {
                          // La distancia escrita era de otra unidad o no aplica.
                          if (k != _kind) _distance.clear();
                          _kind = k;
                          _distanceError = null;
                        }),
                      ),
                      const SizedBox(height: TokensSpacing.m),
                      if (_kind == ActivityKind.match ||
                          _kind == ActivityKind.other) ...[
                        Wrap(
                          spacing: TokensSpacing.s,
                          runSpacing: TokensSpacing.s,
                          children: [
                            for (final (name, kind) in suggestions)
                              if (kind == _kind)
                                ChoiceChip(
                                  label: Text(name),
                                  selected: _title.text == name,
                                  onSelected: (_) =>
                                      setState(() => _title.text = name),
                                ),
                          ],
                        ),
                        const SizedBox(height: TokensSpacing.s),
                      ],
                      AppTextField(
                        controller: _title,
                        label: l10n.trainingPastActivityName,
                        icon: Icons.sports_soccer_outlined,
                        textInputAction: TextInputAction.done,
                        maxLength: 200,
                        onChanged: (_) => setState(() {}),
                      ),
                      if (_kind?.measuresDistance ?? false) ...[
                        const SizedBox(height: TokensSpacing.m),
                        _distanceField(l10n),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: TokensSpacing.m),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSectionHeader(title: l10n.trainingPastActivityWhen),
                    Wrap(
                      spacing: TokensSpacing.s,
                      runSpacing: TokensSpacing.s,
                      children: [
                        for (var i = 0; i < _days; i++)
                          Builder(
                            builder: (context) {
                              final day = today.subtract(Duration(days: i));
                              final label = switch (i) {
                                0 => l10n.trainingPastActivityToday,
                                1 => l10n.trainingPastActivityYesterday,
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
                    const SizedBox(height: TokensSpacing.s),
                    // Para un día de la rutina basta con el día: no hay hora de inicio.
                    if (!_routineMode)
                      AppFocusOutline(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.schedule_rounded),
                          title: Text(l10n.trainingPastActivityStart),
                          trailing: Text(
                            _time.format(context),
                            style: context.textStyles.titleMedium,
                          ),
                          onTap: _pickTime,
                        ),
                      ),
                    const SizedBox(height: TokensSpacing.s),
                    AppStepperField(
                      label: l10n.trainingPastActivityDuration,
                      value: _minutes,
                      // Deporte desde 10 min (una carrera corta cuenta); un día de
                      // rutina, desde 30 y como mucho 4 h (lo que admite el servidor).
                      min: _routineMode ? 30 : SportActivity.minMinutes,
                      max: _routineMode ? 240 : 300,
                      step: 5,
                      display: l10n.trainingPastActivityMinutes,
                      // El aviso de «aún no has terminado» deja de valer al cambiar.
                      onChanged: (v) => setState(() {
                        _minutes = v;
                        _notFinished = null;
                      }),
                    ),
                  ],
                ),
              ),
              if (_isMatch) ...[
                const SizedBox(height: TokensSpacing.m),
                _resultCard(l10n),
              ],
            ],
          ),
        ),
        // «Guardar» siempre a la vista, sin bajar hasta el final; los avisos
        // de por qué no se guardó salen justo encima.
        bottomNavigationBar: SafeArea(
          child: AppContentWidth.reading(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                TokensSpacing.m,
                TokensSpacing.s,
                TokensSpacing.m,
                TokensSpacing.m,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_notFinished case final message?) ...[
                    AppInlineMessage(message: message),
                    const SizedBox(height: TokensSpacing.s),
                  ],
                  if (state.error case final error?) ...[
                    AppInlineMessage(message: errorMessage(context, error)),
                    const SizedBox(height: TokensSpacing.s),
                  ],
                  AppPrimaryButton(
                    label: sport?.category != SportCategory.match
                        ? l10n.trainingPastActivitySave
                        : _mode == SportMode.match
                        ? l10n.sportSaveMatch
                        : l10n.sportSaveTraining,
                    icon: Icons.check_rounded,
                    loading: state.submitting,
                    onPressed: !_routineMode
                        ? _save
                        : state.routine == null
                        ? null
                        : () => _saveRoutineDay(state),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
