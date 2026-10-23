/// Acción registrada en la auditoría de administración.
enum AdminAuditAction {
  updateName,
  updateEmail,
  setProgress,
  resetXp,
  changeLevel,
  changeRole,
  activateShadowban,
  deactivateShadowban,
  wipeUserData,
  anonymizeUser,
  deleteUser,
  exportUserData,
  selfDeleteAccount,
  activateLockdown,
  deactivateLockdown,
  updateGlobalSettings,
  approveContent,
  deleteContent,
  createExercise,
  editExercise,
  activateExercise,
  deactivateExercise,
  deleteExercise,
  other;

  /// Valor que espera la API (UPPER_SNAKE_CASE).
  String get apiValue =>
      name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]}').toUpperCase();

  static AdminAuditAction fromApi(String? value) => values.firstWhere(
    (v) => v.apiValue == value,
    orElse: () => AdminAuditAction.other,
  );

  /// Convierte una lista de la API ignorando valores desconocidos.
  static List<AdminAuditAction> listFromApi(List<String>? raw) => [
    for (final value in raw ?? const <String>[])
      for (final v in values)
        if (v.apiValue == value) v,
  ];
}
