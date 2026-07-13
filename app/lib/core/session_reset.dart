import 'package:flutter/material.dart';

/// Notificador global que controla el reinicio total del arbol de
/// providers y widgets. Cada vez que se incrementa, el [ProviderScope]
/// se destruye y recrea con una clave nueva, eliminando cualquier
/// dato residual del usuario anterior.
final sessionResetNotifier = ValueNotifier<int>(0);

/// Fuerza la destruccion y recreacion completa del [ProviderScope] y
/// todo su subarbol de widgets. Debe llamarse al final de [logout]
/// para garantizar que el siguiente usuario arranque con estado limpio.
void resetAllProvidersOnSessionChange() {
  sessionResetNotifier.value++;
}
