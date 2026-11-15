import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_icons.dart';

/// Flecha «Volver» de la barra de toda pantalla que no es pestaña. Con una
/// pantalla debajo vuelve a ella; abierta sin pila (un aviso del móvil, un
/// enlace, una redirección, recargar en web) va a [fallback], la pantalla de la
/// que cuelga, en vez de dejar a la persona sin salida. Usa [AppBackNavigation].
///
/// El «atrás» del sistema (Android) hace lo mismo ([BackButtonListener]): sin
/// pila iba a cerrar la app. Solo responde la pantalla visible y de arriba del
/// navegador principal: las pestañas que go_router mantiene montadas detrás no
/// tienen el `TickerMode` activo, y un diálogo encima se cierra como siempre.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, required this.fallback});

  /// A dónde ir sin pila: una pestaña (`/training/history`,
  /// `/progress?tab=challenges`) o una pantalla completa cuya propia flecha
  /// acabe en una pestaña.
  final String fallback;

  // `AppBar` solo centra el `leading` si es un `IconButton`: sin `Center` el
  // botón se estiraría a todo el hueco (56 × alto de la barra).
  @override
  Widget build(BuildContext context) {
    final button = Center(
      child: IconButton(
        tooltip: context.localizations.commonBack,
        icon: const Icon(AppIcons.back),
        onPressed: () => context.backOr(fallback),
      ),
    );
    // Sin `Router` (una pantalla suelta en un test) no hay «atrás» que atender.
    if (Router.maybeOf(context) == null) return button;
    return BackButtonListener(
      onBackButtonPressed: () async {
        if (!context.mounted || !TickerMode.valuesOf(context).enabled) {
          return false;
        }
        // Solo la pantalla de arriba del navegador principal: con un diálogo o
        // una hoja encima, o dentro de una pestaña (allí go_router ya vuelve
        // bien), se deja el «atrás» de siempre, que cierra lo de arriba.
        final navigator = Navigator.of(context);
        final root = Navigator.of(context, rootNavigator: true);
        if (navigator != root || !(ModalRoute.isCurrentOf(context) ?? false)) {
          return false;
        }
        await context.backOr(fallback);
        return true;
      },
      child: button,
    );
  }
}

/// Volver atrás sin quedarse sin salida: lo usan [AppBackButton] y las
/// pantallas que salen solas al guardar, borrar o descartar.
extension AppBackNavigation on BuildContext {
  /// Lo que hace la flecha. `maybePop` respeta los `PopScope` (cambios sin
  /// guardar, «Pausar y salir…») también sin pila. Solo si nadie lo
  /// retiene y no hay pantalla debajo se va con `go` a [fallback]: entonces
  /// el armazón de pestañas ya no está montado y `go` no destruye nada.
  Future<void> backOr(String fallback) async {
    if (await Navigator.maybePop(this)) return;
    if (mounted) go(fallback);
  }

  /// Salir sin preguntar (ya confirmado o terminado): `pop` con [result] si
  /// hay pantalla debajo; si no, `go` a [fallback]. `pop` sin pila fallaría.
  void popOrGo(String fallback, [Object? result]) =>
      canPop() ? pop(result) : go(fallback);

  /// Salir cuando se cierra el «Deshacer» de salir de algo (sala, entreno o
  /// reto con amigos): como [popOrGo], también sin pila. Solo si esta pantalla
  /// sigue arriba: si la persona ya se fue (la flecha, otra pestaña), el aviso
  /// se cerró al irse y no hay que mover nada más.
  void leaveAfterUndo(String fallback) {
    if (!mounted || !(ModalRoute.isCurrentOf(this) ?? false)) return;
    popOrGo(fallback);
  }
}
