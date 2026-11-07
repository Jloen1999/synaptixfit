import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/domain/enums/training_enums.dart';
import 'package:synaptixfit/domain/models/training/routine.dart';
import 'package:synaptixfit/presentation/screens/training/widgets/set_fields.dart';

/// Valores por serie (ADR 0027) y campos de la tabla según cómo se mide cada
/// ejercicio.
void main() {
  group('ExerciseParameters por serie', () {
    const base = ExerciseParameters(sets: 3, reps: 10, weightKg: 40);

    test('cada serie usa su valor o el común', () {
      const p = ExerciseParameters(
        sets: 3,
        reps: 10,
        repsPerSet: [12, 10],
        weightKg: 40,
        weightsKg: [30, 40],
      );
      expect([p.repsForSet(1), p.repsForSet(2), p.repsForSet(3)], [12, 10, 10]);
      expect(p.weightForSet(1), 30);
      expect(p.weightForSet(3), 40);
    });

    test(
      'cambiar una serie no toca las demás y el peso común es el de trabajo',
      () {
        final p = base.withSetValues(1, setReps: 12, weight: 30);
        expect(p.repsPerSet, [12, 10, 10]);
        expect(p.weightsKg, [30, 40, 40]);
        expect(p.weightKg, 40);
        expect(p.reps, 11);
      },
    );

    test('si todas las series quedan iguales basta el valor común', () {
      final p = base.withSetValues(2, setReps: 8).withSetValues(2, setReps: 10);
      expect(p.repsPerSet, isNull);
      expect(p.reps, 10);
    });

    test('añadir copia la última serie y quitar una sube las siguientes', () {
      final pyramid = base.withSetValues(3, setReps: 8);
      final added = pyramid.withSetCount(4);
      expect(added.sets, 4);
      expect(added.repsPerSet, [10, 10, 8, 8]);
      final removed = added.withoutSet(1);
      expect(removed.sets, 3);
      expect(removed.repsPerSet, [10, 8, 8]);
      expect(const ExerciseParameters(sets: 1).withoutSet(1).sets, 1);
    });

    test('quitar todo el peso deja el ejercicio sin carga', () {
      final p = base.withSetValues(1, clearWeight: true);
      expect(p.weightKg, isNull);
      expect(p.weightsKg, isNull);
    });

    test('la duración estimada usa las repeticiones de cada serie', () {
      const p = ExerciseParameters(
        sets: 2,
        reps: 10,
        restSeconds: 60,
        repsPerSet: [12, 8],
      );
      expect(p.estimatedDurationSeconds, (12 + 8) * 3 + 60);
    });
  });

  group('SetFields', () {
    SetFields fields(
      List<MeasurementType> types, {
      Modality modality = Modality.strength,
      ExerciseParameters parameters = const ExerciseParameters(),
    }) => SetFields.from(
      types: types,
      modality: modality,
      parameters: parameters,
    );

    test('press banca: repeticiones y kilos', () {
      expect(
        fields([MeasurementType.repetitions, MeasurementType.weight]).fields,
        [SetField.reps, SetField.weight],
      );
    });

    test('flexiones: solo repeticiones', () {
      expect(fields([MeasurementType.repetitions]).fields, [SetField.reps]);
    });

    test('plancha: segundos de aguante', () {
      expect(fields([MeasurementType.time]).fields, [SetField.hold]);
    });

    test('correr: minutos y metros (por modalidad o por los datos)', () {
      expect(
        fields([MeasurementType.time], modality: Modality.aerobic).fields,
        [SetField.duration, SetField.distance],
      );
      expect(
        fields(
          [MeasurementType.time],
          parameters: const ExerciseParameters(targetDurationSeconds: 600),
        ).isCardio,
        isTrue,
      );
    });

    test('los datos mandan: con aguante es isométrico aunque sea aeróbico', () {
      expect(
        fields(
          [MeasurementType.time],
          modality: Modality.aerobic,
          parameters: const ExerciseParameters(isometricSeconds: 45),
        ).isHold,
        isTrue,
      );
    });
  });
}
