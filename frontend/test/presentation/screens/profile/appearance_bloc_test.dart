import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/appearance_mode.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/profile/get_appearance_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/set_appearance_use_case.dart';
import 'package:synaptixfit/presentation/screens/profile/appearance/bloc/appearance_bloc.dart';

class _Get extends Mock implements GetAppearanceUseCaseContract {}

class _Set extends Mock implements SetAppearanceUseCaseContract {}

void main() {
  late _Get get;
  late _Set set;

  setUpAll(() => registerFallbackValue(AppearanceMode.dark));

  setUp(() {
    get = _Get();
    set = _Set();
    when(() => set(any())).thenAnswer((_) async => const Success(unit));
  });

  blocTest<AppearanceBloc, AppearanceState>(
    'arranca con la apariencia guardada',
    setUp: () => when(
      () => get(),
    ).thenAnswer((_) async => const Success(AppearanceMode.light)),
    build: () => AppearanceBloc(get: get, set: set),
    act: (bloc) => bloc.add(const AppearanceEvent.started()),
    expect: () => const [AppearanceState(mode: AppearanceMode.light)],
  );

  blocTest<AppearanceBloc, AppearanceState>(
    'sin poder leerla se queda en oscuro',
    setUp: () => when(
      () => get(),
    ).thenAnswer((_) async => const Failure(AppError.unknown())),
    build: () => AppearanceBloc(get: get, set: set),
    act: (bloc) => bloc.add(const AppearanceEvent.started()),
    expect: () => const <AppearanceState>[],
  );

  blocTest<AppearanceBloc, AppearanceState>(
    'al elegir, se aplica al momento y se guarda',
    build: () => AppearanceBloc(get: get, set: set),
    act: (bloc) =>
        bloc.add(const AppearanceEvent.changed(AppearanceMode.system)),
    expect: () => const [AppearanceState(mode: AppearanceMode.system)],
    verify: (_) => verify(() => set(AppearanceMode.system)).called(1),
  );

  blocTest<AppearanceBloc, AppearanceState>(
    'si el usuario elige mientras se lee la guardada, manda su elección',
    setUp: () => when(() => get()).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return const Success(AppearanceMode.dark);
    }),
    build: () => AppearanceBloc(get: get, set: set),
    act: (bloc) => bloc
      ..add(const AppearanceEvent.started())
      ..add(const AppearanceEvent.changed(AppearanceMode.light)),
    wait: const Duration(milliseconds: 30),
    expect: () => const [AppearanceState(mode: AppearanceMode.light)],
  );

  test('un valor guardado desconocido cuenta como oscuro', () {
    expect(AppearanceMode.fromStorage('sepia'), AppearanceMode.dark);
    expect(AppearanceMode.fromStorage('light'), AppearanceMode.light);
  });
}
