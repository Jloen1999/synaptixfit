import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/usage_focus.dart';
import '../../enums/user_role.dart';
import '../../enums/visibility.dart';

part 'account.freezed.dart';

/// Cuenta del usuario autenticado y su progresión.
@freezed
abstract class Account with _$Account {
  const factory Account({
    required String id,
    required String email,
    required String fullName,
    String? avatarUrl,
    required int level,
    required int levelXp,
    required int levelThreshold,
    required int streak,
    required Visibility privacy,
    required UserRole role,
    required bool hasPassword,
    required bool googleLinked,

    /// Para qué usa la app; decide qué pestañas y secciones se ven.
    @Default(UsageFocus.both) UsageFocus usageFocus,

    /// Si ya lo eligió (el onboarding lo pregunta si no).
    @Default(true) bool usageFocusChosen,

    /// Fecha de nacimiento (opcional, ADR 0036). Solo la ve la propia persona.
    DateTime? birthDate,

    /// Edad calculada por el servidor con [birthDate]; nula sin fecha.
    int? age,
  }) = _Account;

  const Account._();

  bool get isAdmin => role == UserRole.admin;

  /// Nombre de pila con el que se le habla («¡Feliz cumpleaños, Ana!»).
  String get firstName {
    final trimmed = fullName.trim();
    final space = trimmed.indexOf(' ');
    return space < 0 ? trimmed : trimmed.substring(0, space);
  }

  /// Progreso del nivel actual entre 0 y 1.
  double get levelProgress => levelThreshold == 0
      ? 0
      : (levelXp / levelThreshold).clamp(0, 1).toDouble();
}
