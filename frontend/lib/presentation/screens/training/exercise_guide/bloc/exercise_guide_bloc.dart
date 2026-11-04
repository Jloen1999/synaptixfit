import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/result/result.dart';
import '../../../../../domain/models/training/exercise_guide.dart';
import '../../../../../domain/use_cases/training/get_exercise_note_use_case.dart';
import '../../../../../domain/use_cases/training/get_exercise_tips_use_case.dart';
import '../../../../../domain/use_cases/training/save_exercise_note_use_case.dart';

part 'exercise_guide_bloc.freezed.dart';
part 'exercise_guide_event.dart';
part 'exercise_guide_state.dart';

/// Guía de un ejercicio (ADR 0031): «Las claves», «Errores comunes» y la nota
/// propia. La usan la ficha del ejercicio y la hoja «Cómo se hace» de la
/// sesión. Si los consejos no llegan, simplemente no se enseñan.
class ExerciseGuideBloc extends Bloc<ExerciseGuideEvent, ExerciseGuideState> {
  ExerciseGuideBloc({
    required this._getTips,
    required this._getNote,
    required this._saveNote,
  }) : super(const ExerciseGuideState()) {
    on<ExerciseGuideStarted>(_onStarted);
    on<ExerciseGuideNoteSaved>(_onNoteSaved);
  }

  final GetExerciseTipsUseCaseContract _getTips;
  final GetExerciseNoteUseCaseContract _getNote;
  final SaveExerciseNoteUseCaseContract _saveNote;

  Future<void> _onStarted(
    ExerciseGuideStarted event,
    Emitter<ExerciseGuideState> emit,
  ) async {
    emit(ExerciseGuideState(exerciseId: event.exerciseId));
    final (tips, note) = await (
      _getTips(event.exerciseId),
      _getNote(event.exerciseId),
    ).wait;
    emit(
      state.copyWith(
        loading: false,
        tips: tips.valueOrNull ?? const ExerciseTips(),
        note: note.valueOrNull,
        // Sin poder leer la nota no se deja editarla: se perdería la guardada.
        noteError: note.errorOrNull,
      ),
    );
  }

  Future<void> _onNoteSaved(
    ExerciseGuideNoteSaved event,
    Emitter<ExerciseGuideState> emit,
  ) async {
    final id = state.exerciseId;
    if (id == null || state.saving) return;
    emit(state.copyWith(saving: true));
    final result = await _saveNote(id, event.text);
    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            saving: false,
            note: value,
            noticeId: state.noticeId + 1,
            notice: value == null
                ? ExerciseGuideNotice.deleted
                : ExerciseGuideNotice.saved,
            saveError: null,
          ),
        );
      case Failure(:final error):
        emit(
          state.copyWith(
            saving: false,
            noticeId: state.noticeId + 1,
            notice: ExerciseGuideNotice.failed,
            saveError: error,
          ),
        );
    }
  }
}
