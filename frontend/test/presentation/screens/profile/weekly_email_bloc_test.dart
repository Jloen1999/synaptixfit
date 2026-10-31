import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/weekly_email_status.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/profile/disable_weekly_email_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/enable_weekly_email_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/get_weekly_email_status_use_case.dart';
import 'package:synaptixfit/presentation/screens/profile/notification_settings/bloc/weekly_email_bloc.dart';

class _Get extends Mock implements GetWeeklyEmailStatusUseCaseContract {}

class _Enable extends Mock implements EnableWeeklyEmailUseCaseContract {}

class _Disable extends Mock implements DisableWeeklyEmailUseCaseContract {}

void main() {
  late _Get get;
  late _Enable enable;
  late _Disable disable;

  setUp(() {
    get = _Get();
    enable = _Enable();
    disable = _Disable();
    when(
      () => get(),
    ).thenAnswer((_) async => const Success(WeeklyEmailStatus.off));
  });

  WeeklyEmailBloc build() =>
      WeeklyEmailBloc(getStatus: get, enable: enable, disable: disable);

  blocTest<WeeklyEmailBloc, WeeklyEmailState>(
    'activarlo sin Google queda pendiente de confirmar por correo',
    setUp: () => when(
      () => enable(),
    ).thenAnswer((_) async => const Success(WeeklyEmailStatus.pending)),
    build: build,
    act: (bloc) async {
      bloc.add(const WeeklyEmailEvent.started());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const WeeklyEmailEvent.toggled(true));
    },
    expect: () => const [
      WeeklyEmailState(status: WeeklyEmailStatus.off),
      WeeklyEmailState(status: WeeklyEmailStatus.off, busy: true),
      WeeklyEmailState(status: WeeklyEmailStatus.pending),
    ],
  );

  blocTest<WeeklyEmailBloc, WeeklyEmailState>(
    'desactivarlo lo apaga; un fallo deja el estado como estaba',
    setUp: () => when(
      () => disable(),
    ).thenAnswer((_) async => const Failure(AppError.network())),
    build: build,
    seed: () => const WeeklyEmailState(status: WeeklyEmailStatus.active),
    act: (bloc) => bloc.add(const WeeklyEmailEvent.toggled(false)),
    expect: () => const [
      WeeklyEmailState(status: WeeklyEmailStatus.active, busy: true),
      WeeklyEmailState(
        status: WeeklyEmailStatus.active,
        error: AppError.network(),
      ),
    ],
  );

  blocTest<WeeklyEmailBloc, WeeklyEmailState>(
    'si no se puede leer el estado, la sección muestra el error y se reintenta',
    setUp: () {
      var calls = 0;
      when(() => get()).thenAnswer(
        (_) async => calls++ == 0
            ? const Failure(AppError.network())
            : const Success(WeeklyEmailStatus.off),
      );
    },
    build: build,
    act: (bloc) async {
      bloc.add(const WeeklyEmailEvent.started());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const WeeklyEmailEvent.started());
    },
    expect: () => const [
      WeeklyEmailState(loadError: AppError.network()),
      WeeklyEmailState(),
      WeeklyEmailState(status: WeeklyEmailStatus.off),
    ],
  );
}
