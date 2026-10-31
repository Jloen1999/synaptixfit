import 'package:flutter_test/flutter_test.dart';
import 'package:synaptixfit/app/config/app_config.dart';
import 'package:synaptixfit/app/di/app_di.dart';
import 'package:synaptixfit/domain/repositories/enrollment_repository_contract.dart';
import 'package:synaptixfit/domain/use_cases/profile/apply_enrollment_use_case.dart';
import 'package:synaptixfit/domain/use_cases/profile/read_enrollment_use_case.dart';
import 'package:synaptixfit/presentation/screens/profile/enrollment_import/bloc/enrollment_import_bloc.dart';

/// La raíz de composición resuelve las piezas nuevas: un tipo mal registrado
/// (p. ej. pedir `Dio` donde se registra `ApiClient`) deja la pantalla en gris.
void main() {
  setUpAll(() => appInitDi(AppConfig.fromEnvironment()));
  tearDownAll(getIt.reset);

  test('la importación de la matrícula se puede construir', () {
    expect(getIt<EnrollmentRepositoryContract>(), isNotNull);
    expect(getIt<ReadEnrollmentUseCaseContract>(), isNotNull);
    expect(getIt<ApplyEnrollmentUseCaseContract>(), isNotNull);
    expect(getIt<EnrollmentImportBloc>(), isNotNull);
  });
}
