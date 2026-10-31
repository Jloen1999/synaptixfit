import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_setup.freezed.dart';

/// Configuración que falta para que la app funcione bien (la decide el
/// servidor según el enfoque de uso) y hasta cuándo la persona pidió no verla.
@freezed
abstract class HomeSetup with _$HomeSetup {
  const HomeSetup._();

  const factory HomeSetup({
    @Default(<HomeSetupTask>[]) List<HomeSetupTask> pending,
    @Default(0) int total,
    DateTime? snoozedUntil,
  }) = _HomeSetup;

  int get done => (total - pending.length).clamp(0, total);

  /// Se muestra si falta algo y no se pospuso (o ya pasó el plazo).
  bool visibleAt(DateTime now) =>
      pending.isNotEmpty &&
      (snoozedUntil == null || !now.isBefore(snoozedUntil!));
}

/// Tareas de configuración, en el orden de importancia del servidor.
enum HomeSetupTask {
  subjects('SUBJECTS'),
  wellnessProfile('WELLNESS_PROFILE'),
  routine('ROUTINE'),
  weekPlan('WEEK_PLAN'),
  academicProfile('ACADEMIC_PROFILE');

  const HomeSetupTask(this.apiValue);

  final String apiValue;

  /// Las desconocidas (de una versión más nueva del servidor) se ignoran.
  static HomeSetupTask? fromApi(String? value) {
    for (final t in values) {
      if (t.apiValue == value) return t;
    }
    return null;
  }
}
