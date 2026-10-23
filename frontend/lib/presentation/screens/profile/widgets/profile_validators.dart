import '../../../l10n/gen_l10n/app_localizations.dart';

/// Validaciones numéricas de los formularios del perfil (mismos límites que la API).
abstract final class ProfileValidators {
  /// Lee un decimal admitiendo coma o punto.
  static double? parseDecimal(String? value) =>
      double.tryParse((value ?? '').trim().replaceAll(',', '.'));

  static int? parseInt(String? value) => int.tryParse((value ?? '').trim());

  /// Entero obligatorio entre [min] y [max].
  static String? requiredInt(
    AppLocalizations l10n,
    String? value,
    int min,
    int max,
  ) {
    if ((value ?? '').trim().isEmpty) return l10n.validationRequired;
    return optionalInt(l10n, value, min, max);
  }

  /// Entero opcional entre [min] y [max].
  static String? optionalInt(
    AppLocalizations l10n,
    String? value,
    int min,
    int max,
  ) {
    if ((value ?? '').trim().isEmpty) return null;
    final parsed = parseInt(value);
    if (parsed == null || parsed < min || parsed > max) {
      return l10n.profileValidationRange('$min', '$max');
    }
    return null;
  }

  /// Decimal obligatorio entre [min] y [max].
  static String? requiredDecimal(
    AppLocalizations l10n,
    String? value,
    num min,
    num max,
  ) {
    if ((value ?? '').trim().isEmpty) return l10n.validationRequired;
    return optionalDecimal(l10n, value, min, max);
  }

  /// Decimal opcional entre [min] y [max].
  static String? optionalDecimal(
    AppLocalizations l10n,
    String? value,
    num min,
    num max,
  ) {
    if ((value ?? '').trim().isEmpty) return null;
    final parsed = parseDecimal(value);
    if (parsed == null || parsed < min || parsed > max) {
      return l10n.profileValidationRange('$min', '$max');
    }
    return null;
  }
}
