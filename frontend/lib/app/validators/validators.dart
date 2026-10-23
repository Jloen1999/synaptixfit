/// Validaciones de formulario. Devuelven la clave del error o `null` si es válido;
/// la página traduce la clave con `context.localizations`.
enum ValidationFailure { required, invalidEmail, weakPassword, tooShort }

abstract final class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static ValidationFailure? requiredText(String? value) =>
      (value == null || value.trim().isEmpty)
      ? ValidationFailure.required
      : null;

  static ValidationFailure? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ValidationFailure.required;
    }
    return _email.hasMatch(value.trim())
        ? null
        : ValidationFailure.invalidEmail;
  }

  /// Mínimo 8 caracteres, al menos una letra y un dígito (misma política que el backend).
  static ValidationFailure? password(String? value) {
    if (value == null || value.isEmpty) return ValidationFailure.required;
    final ok =
        value.length >= 8 &&
        value.contains(RegExp('[A-Za-z]')) &&
        value.contains(RegExp('[0-9]'));
    return ok ? null : ValidationFailure.weakPassword;
  }

  static ValidationFailure? minLength(String? value, int min) {
    if (value == null || value.trim().isEmpty) {
      return ValidationFailure.required;
    }
    return value.trim().length >= min ? null : ValidationFailure.tooShort;
  }
}
