import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/app_result.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/models/training/exercise_guide.dart';
import 'package:synaptixfit/domain/use_cases/training/get_exercise_note_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/get_exercise_tips_use_case.dart';
import 'package:synaptixfit/domain/use_cases/training/save_exercise_note_use_case.dart';
import 'package:synaptixfit/presentation/screens/training/exercise_guide/bloc/exercise_guide_bloc.dart';

class _Tips implements GetExerciseTipsUseCaseContract {
  _Tips(this.result);

  final AppResult<ExerciseTips> result;

  @override
  Future<AppResult<ExerciseTips>> call(String exerciseId) async => result;
}

class _Notes
    implements GetExerciseNoteUseCaseContract, SaveExerciseNoteUseCaseContract {
  ExerciseNote? stored;
  bool failSave = false;

  @override
  Future<AppResult<ExerciseNote?>> call(String exerciseId, [String? text]) async {
    if (text == null) return Success(stored);
    if (failSave) return const Failure(AppError.network());
    stored = text.isEmpty
        ? null
        : ExerciseNote(text: text, updatedAt: DateTime(2026, 11, 4));
    return Success(stored);
  }
}

/// «Las claves», «Errores comunes» y «Tu nota» (ADR 0031).
void main() {
  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 5));

  ExerciseGuideBloc build(AppResult<ExerciseTips> tips, _Notes notes) =>
      ExerciseGuideBloc(getTips: _Tips(tips), getNote: notes, saveNote: notes);

  test('carga las claves y la nota guardada', () async {
    final notes = _Notes()
      ..stored = ExerciseNote(text: 'Asiento 4', updatedAt: DateTime(2026));
    final bloc = build(
      const Success(
        ExerciseTips(keyPoints: ['Espalda recta'], commonMistakes: ['Rebotar']),
      ),
      notes,
    )..add(const ExerciseGuideEvent.started('e1'));
    await settle();
    expect(bloc.state.loading, isFalse);
    expect(bloc.state.tips.keyPoints, ['Espalda recta']);
    expect(bloc.state.note?.text, 'Asiento 4');
    await bloc.close();
  });

  test('sin consejos (o si fallan) no se enseña nada, la nota sí', () async {
    final bloc = build(const Failure(AppError.network()), _Notes())
      ..add(const ExerciseGuideEvent.started('e1'));
    await settle();
    expect(bloc.state.tips.isEmpty, isTrue);
    expect(bloc.state.noteError, isNull);
    await bloc.close();
  });

  test('guardar, borrar y fallar al guardar avisan de lo que pasó', () async {
    final notes = _Notes();
    final bloc = build(const Success(ExerciseTips()), notes)
      ..add(const ExerciseGuideEvent.started('e1'));
    await settle();

    bloc.add(const ExerciseGuideEvent.noteSaved('Agarre ancho'));
    await settle();
    expect(bloc.state.note?.text, 'Agarre ancho');
    expect(bloc.state.notice, ExerciseGuideNotice.saved);

    bloc.add(const ExerciseGuideEvent.noteSaved(''));
    await settle();
    expect(bloc.state.note, isNull);
    expect(bloc.state.notice, ExerciseGuideNotice.deleted);

    notes.failSave = true;
    bloc.add(const ExerciseGuideEvent.noteSaved('Otra'));
    await settle();
    expect(bloc.state.notice, ExerciseGuideNotice.failed);
    expect(bloc.state.saveError, const AppError.network());
    await bloc.close();
  });
}
