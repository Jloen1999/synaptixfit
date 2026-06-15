// ignore_for_file: constant_identifier_names

enum EstadoHito {
  bloqueado,
  disponible,
  enProgreso,
  completado;
}

enum TipoCondicion {
  /// Todos los hitos dependientes deben estar completados.
  AND,

  /// Al menos un hito dependiente debe estar completado.
  OR,

  /// Al menos N de los hitos dependientes deben estar completados.
  X_OF_Y;
}
