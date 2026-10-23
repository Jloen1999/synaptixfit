import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:synaptixfit/domain/enums/user_role.dart';
import 'package:synaptixfit/domain/enums/visibility.dart';
import 'package:synaptixfit/domain/errors/app_error.dart';
import 'package:synaptixfit/domain/models/account/account.dart';
import 'package:synaptixfit/domain/models/result/result.dart';
import 'package:synaptixfit/domain/use_cases/auth/login_use_case.dart';
import 'package:synaptixfit/domain/use_cases/auth/login_with_google_use_case.dart';
import 'package:synaptixfit/presentation/screens/auth/login/bloc/login_bloc.dart';

class _MockLogin extends Mock implements LoginUseCaseContract {}

class _MockGoogle extends Mock implements LoginWithGoogleUseCaseContract {}

void main() {
  const account = Account(
    id: '1',
    email: 'a@b.co',
    fullName: 'Ana',
    level: 1,
    levelXp: 0,
    levelThreshold: 100,
    streak: 0,
    privacy: Visibility.private,
    role: UserRole.user,
    hasPassword: true,
    googleLinked: false,
  );
  late _MockLogin login;
  late _MockGoogle google;

  setUp(() {
    login = _MockLogin();
    google = _MockGoogle();
  });

  blocTest<LoginBloc, LoginState>(
    'emite success cuando las credenciales son correctas',
    setUp: () => when(
      () => login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const Success(account)),
    build: () => LoginBloc(login: login, loginWithGoogle: google),
    act: (bloc) => bloc.add(
      const LoginEvent.submitted(email: 'a@b.co', password: 'secret123'),
    ),
    expect: () => const [LoginState.submitting(), LoginState.success(account)],
  );

  blocTest<LoginBloc, LoginState>(
    'emite failure con el AppError del caso de uso',
    setUp: () =>
        when(
          () => login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async =>
              const Failure(AppError.business('AUTH_INVALID_CREDENTIALS')),
        ),
    build: () => LoginBloc(login: login, loginWithGoogle: google),
    act: (bloc) =>
        bloc.add(const LoginEvent.submitted(email: 'a@b.co', password: 'bad')),
    expect: () => const [
      LoginState.submitting(),
      LoginState.failure(AppError.business('AUTH_INVALID_CREDENTIALS')),
    ],
  );

  blocTest<LoginBloc, LoginState>(
    'cancelar Google vuelve a idle sin error',
    setUp: () => when(() => google()).thenAnswer(
      (_) async => const Failure(AppError.business('GOOGLE_SIGN_IN_CANCELLED')),
    ),
    build: () => LoginBloc(login: login, loginWithGoogle: google),
    act: (bloc) => bloc.add(const LoginEvent.googleRequested()),
    expect: () => const [LoginState.submitting(), LoginState.idle()],
  );

  blocTest<LoginBloc, LoginState>(
    'en web espera al botón de Google sin bloquear el formulario',
    setUp: () =>
        when(() => google()).thenAnswer((_) async => const Success(account)),
    build: () => LoginBloc(login: login, loginWithGoogle: google),
    act: (bloc) =>
        bloc.add(const LoginEvent.googleRequested(awaitsWebButton: true)),
    expect: () => const [LoginState.success(account)],
  );

  var calls = 0;
  blocTest<LoginBloc, LoginState>(
    'en web, si el backend rechaza el token, el botón vuelve a escuchar',
    setUp: () {
      calls = 0;
      when(() => google()).thenAnswer(
        (_) async => ++calls == 1
            ? const Failure(AppError.business('AUTH_ACCOUNT_DISABLED'))
            : const Success(account),
      );
    },
    build: () => LoginBloc(login: login, loginWithGoogle: google),
    act: (bloc) =>
        bloc.add(const LoginEvent.googleRequested(awaitsWebButton: true)),
    expect: () => const [
      LoginState.failure(AppError.business('AUTH_ACCOUNT_DISABLED')),
      LoginState.success(account),
    ],
  );

  blocTest<LoginBloc, LoginState>(
    'en web, un fallo del propio Google no se reintenta en bucle',
    setUp: () => when(() => google()).thenAnswer(
      (_) async => const Failure(AppError.business('GOOGLE_SIGN_IN_FAILED')),
    ),
    build: () => LoginBloc(login: login, loginWithGoogle: google),
    act: (bloc) =>
        bloc.add(const LoginEvent.googleRequested(awaitsWebButton: true)),
    expect: () => const [
      LoginState.failure(AppError.business('GOOGLE_SIGN_IN_FAILED')),
    ],
    verify: (_) => verify(() => google()).called(1),
  );
}
