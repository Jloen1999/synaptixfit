import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/app_language.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/profile/get_language_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/set_language_use_case.dart';
import 'package:synaptixfit/presentation/screens/profile/language/bloc/language_bloc.dart';

class _Get extends Mock implements GetLanguageUseCaseContract {}

class _Set extends Mock implements SetLanguageUseCaseContract {}

void main() {
  late _Get get;
  late _Set set;

  setUpAll(() => registerFallbackValue(AppLanguage.system));

  setUp(() {
    get = _Get();
    set = _Set();
    when(() => set(any())).thenAnswer((_) async => const Success(unit));
  });

  blocTest<LanguageBloc, LanguageState>(
    'arranca con el idioma guardado',
    setUp: () => when(
      () => get(),
    ).thenAnswer((_) async => const Success(AppLanguage.fr)),
    build: () => LanguageBloc(get: get, set: set),
    act: (bloc) => bloc.add(const LanguageEvent.started()),
    expect: () => const [LanguageState(language: AppLanguage.fr)],
  );

  blocTest<LanguageBloc, LanguageState>(
    'al elegir se aplica al momento y se guarda; manda sobre la lectura lenta',
    setUp: () => when(() => get()).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return const Success(AppLanguage.es);
    }),
    build: () => LanguageBloc(get: get, set: set),
    act: (bloc) => bloc
      ..add(const LanguageEvent.started())
      ..add(const LanguageEvent.changed(AppLanguage.pt)),
    wait: const Duration(milliseconds: 30),
    expect: () => const [LanguageState(language: AppLanguage.pt)],
    verify: (_) => verify(() => set(AppLanguage.pt)).called(1),
  );
}
