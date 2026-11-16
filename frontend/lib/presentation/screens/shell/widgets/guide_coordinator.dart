import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../bloc/guide_tour_bloc.dart';

/// Lo que comparten las guías la primera vez (ADR 0049): crea el bloc de cada
/// pantalla, sabe si hay una hoja o un diálogo abierto en el navegador raíz
/// ([observer], que se da al router) y si la pantalla se acaba de abrir desde
/// un aviso o un enlace ([markExternalArrival]). Una sola instancia, en
/// [GuideScope] sobre el navegador.
class GuideCoordinator {
  GuideCoordinator({required this._createBloc, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// Lo que tarda como mucho la pantalla en abrirse tras tocar el aviso: lo
  /// que se abra en ese rato cuenta como llegado desde fuera.
  static const externalWindow = Duration(seconds: 5);

  final GuideTourBloc Function() _createBloc;
  final DateTime Function() _clock;
  final _popups = _PopupRouteObserver();
  DateTime? _externalAt;

  /// Observa el navegador raíz: diálogos y hojas que tapan la pantalla.
  NavigatorObserver get observer => _popups;

  /// Diálogos y hojas abiertos en el navegador raíz (también la propia guía).
  ValueListenable<int> get popups => _popups.open;

  GuideTourBloc createBloc() => _createBloc();

  /// Un aviso del móvil o un enlace va a abrir una pantalla: su guía espera a
  /// la próxima vez que se entre por la app.
  void markExternalArrival() => _externalAt = _clock();

  /// La visita que empieza ahora la ha abierto un aviso o un enlace.
  bool get arrivedFromOutside {
    final at = _externalAt;
    return at != null && _clock().difference(at) < externalWindow;
  }
}

/// Cuenta los diálogos y hojas ([PopupRoute]) del navegador raíz.
class _PopupRouteObserver extends NavigatorObserver {
  final open = ValueNotifier<int>(0);

  void _add(Route<dynamic>? route, int delta) {
    if (route is PopupRoute) open.value = math.max(0, open.value + delta);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _add(route, 1);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _add(route, -1);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _add(route, -1);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _add(oldRoute, -1);
    _add(newRoute, 1);
  }
}

/// Da el [GuideCoordinator] a todas las pantallas (va sobre el navegador, en
/// la app raíz). Sin él (p. ej. en un test de pantalla) no salen guías.
class GuideScope extends InheritedWidget {
  const GuideScope({
    super.key,
    required this.coordinator,
    required super.child,
  });

  final GuideCoordinator coordinator;

  static GuideCoordinator? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<GuideScope>()?.coordinator;

  @override
  bool updateShouldNotify(GuideScope oldWidget) =>
      coordinator != oldWidget.coordinator;
}
