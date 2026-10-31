import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/data_topic.dart';
import '../../../../domain/enums/reminder_kind.dart';
import '../../../../domain/enums/usage_focus.dart';
import '../../../../domain/models/reminders/reminder_texts.dart';
import '../../../../domain/use_cases/reminders/mark_reminders_offered_use_case.dart';
import '../../../../domain/use_cases/reminders/set_device_reminders_enabled_use_case.dart';
import '../../../../domain/use_cases/reminders/should_offer_reminders_use_case.dart';
import '../../../../domain/use_cases/reminders/clear_reminders_use_case.dart';
import '../../../../domain/use_cases/reminders/sync_reminders_use_case.dart';
import '../../../../domain/use_cases/reminders/watch_device_reminders_enabled_use_case.dart';
import '../../../../domain/use_cases/reminders/watch_opened_reminders_use_case.dart';
import '../../../../domain/use_cases/sync/watch_data_changes_use_case.dart';

part 'reminders_bloc.freezed.dart';
part 'reminders_event.dart';
part 'reminders_state.dart';

/// Mantiene al día los recordatorios locales del móvil mientras hay sesión:
/// sincroniza al entrar en el armazón, cuando cambian planificador, estudio,
/// entrenamiento o las preferencias, y al activar el interruptor del
/// dispositivo. Lo monta [RemindersHost]; en web todo es una operación vacía.
class RemindersBloc extends Bloc<RemindersEvent, RemindersState> {
  RemindersBloc({
    required this._sync,
    required this._clear,
    required this._watchChanges,
    required this._watchEnabled,
    required this._watchOpened,
    required this._shouldOffer,
    required this._markOffered,
    required this._setEnabled,
    this.debounce = const Duration(seconds: 2),
  }) : super(const RemindersState()) {
    on<RemindersStarted>(_onStarted);
    on<RemindersFocusChanged>(_onFocusChanged);
    on<RemindersSyncRequested>((_, emit) => _enqueueSync(emit));
    on<RemindersSignedOut>(_onSignedOut);
    on<RemindersOpened>((e, emit) => emit(state.copyWith(openRequest: e.kind)));
    on<RemindersOpenHandled>(
      (_, emit) => emit(state.copyWith(openRequest: null)),
    );
    on<RemindersOfferCheckRequested>(_onOfferCheck);
    on<RemindersOfferAnswered>(_onOfferAnswered);
  }

  /// Temas cuyo guardado es buen momento para ofrecer los avisos: acaba de
  /// planificar o de estudiar algo que conviene recordar.
  static const offerTopics = {DataTopic.planner, DataTopic.academic};

  /// Las preferencias de notificación se guardan en `/notifications`, que el
  /// interceptor marca como [DataTopic.social]; por eso se escucha también.
  static const topics = {
    DataTopic.planner,
    DataTopic.academic,
    DataTopic.training,
    DataTopic.social,
  };

  final SyncRemindersUseCaseContract _sync;
  final ClearRemindersUseCaseContract _clear;
  final WatchDataChangesUseCaseContract _watchChanges;
  final WatchDeviceRemindersEnabledUseCaseContract _watchEnabled;
  final WatchOpenedRemindersUseCaseContract _watchOpened;
  final ShouldOfferRemindersUseCaseContract _shouldOffer;
  final MarkRemindersOfferedUseCaseContract _markOffered;
  final SetDeviceRemindersEnabledUseCaseContract _setEnabled;

  /// Solo se comprueba una vez por sesión de la app.
  bool _offerChecked = false;

  /// Agrupa ráfagas de cambios (guardar un plan toca varios temas) en una
  /// sola reprogramación.
  final Duration debounce;

  final _subscriptions = <StreamSubscription<Object>>[];
  Timer? _debounceTimer;
  UsageFocus? _focus;
  ReminderTexts? _texts;
  bool _signedOut = false;

  /// Las sincronizaciones van en fila: dos `replaceAll` a la vez podrían
  /// mezclar avisos viejos y nuevos.
  Future<void> _queue = Future.value();

  Future<void> _onStarted(
    RemindersStarted event,
    Emitter<RemindersState> emit,
  ) async {
    _focus = event.focus;
    _texts = event.texts;
    if (_subscriptions.isEmpty) {
      _subscriptions.addAll([
        _watchChanges(topics: topics).listen((changed) {
          _scheduleSync();
          if (!_offerChecked &&
              changed.any(offerTopics.contains) &&
              !isClosed) {
            add(const RemindersEvent.offerCheckRequested());
          }
        }),
        _watchEnabled().listen((_) => _requestSync()),
        _watchOpened().listen((kind) {
          if (!isClosed) add(RemindersEvent.opened(kind));
        }),
      ]);
    }
    await _enqueueSync(emit);
  }

  Future<void> _onFocusChanged(
    RemindersFocusChanged event,
    Emitter<RemindersState> emit,
  ) async {
    if (event.focus == _focus) return;
    _focus = event.focus;
    await _enqueueSync(emit);
  }

  Future<void> _onSignedOut(
    RemindersSignedOut event,
    Emitter<RemindersState> emit,
  ) async {
    _signedOut = true;
    _debounceTimer?.cancel();
    await (_queue = _queue.then((_) => _clear()));
  }

  Future<void> _onOfferCheck(
    RemindersOfferCheckRequested event,
    Emitter<RemindersState> emit,
  ) async {
    if (_offerChecked || _signedOut) return;
    _offerChecked = true;
    if ((await _shouldOffer()).valueOrNull ?? false) {
      emit(state.copyWith(offerReminders: true));
    }
  }

  /// Se marca como ofrecido acepte o no; si acepta, se pide el permiso (y al
  /// activarse se reprograma solo, por `watchEnabled`).
  Future<void> _onOfferAnswered(
    RemindersOfferAnswered event,
    Emitter<RemindersState> emit,
  ) async {
    emit(state.copyWith(offerReminders: false));
    await _markOffered();
    if (!event.accepted) return;
    final granted = (await _setEnabled(true)).valueOrNull ?? false;
    if (!granted && !emit.isDone) {
      emit(
        state.copyWith(permissionDeniedCount: state.permissionDeniedCount + 1),
      );
    }
  }

  void _scheduleSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, _requestSync);
  }

  void _requestSync() {
    if (!isClosed) add(const RemindersEvent.syncRequested());
  }

  Future<void> _enqueueSync(Emitter<RemindersState> emit) async {
    final texts = _texts;
    if (_focus == null || texts == null || _signedOut) return;
    final run = _queue.then((_) => _sync(texts: texts));
    _queue = run.then((_) {});
    // Un fallo (sin red, permiso retirado…) se ignora: los avisos ya
    // programados siguen valiendo y se reintenta con el próximo cambio.
    final scheduled = (await run).valueOrNull;
    if (scheduled != null && !emit.isDone) {
      emit(state.copyWith(scheduled: scheduled));
    }
  }

  @override
  Future<void> close() async {
    _debounceTimer?.cancel();
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
