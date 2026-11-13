import 'package:flutter/foundation.dart';

/// Día de rutina cuya sesión abierta retoma ahora mismo «Continuar» de la
/// tarjeta de Gimnasio (nulo si la tarjeta no lo ofrece). Una sola instancia:
/// la escribe Gimnasio y la lee `OpenSessionBar`, que no sale para esa sesión
/// porque serían dos caminos al mismo sitio (ADR 0039). Cualquier otra sesión
/// abierta sigue teniendo su barra.
class ContinueSessionTarget extends ValueNotifier<String?> {
  ContinueSessionTarget() : super(null);
}
