import 'package:flutter/material.dart';

import 'app_focus_group.dart';

/// Comportamiento de desplazamiento de la app: además del de Material, cada
/// zona desplazable es un grupo de foco del tamaño de lo que se ve.
///
/// Por qué: el orden de foco de Flutter es geométrico y usa la posición real
/// de cada elemento, también la de los que el desplazamiento ha dejado fuera.
/// Sin el grupo, lo desplazado por encima contaba como «antes» de la barra
/// superior y lo que queda bajo el borde, «después» del botón de un pie fijo
/// (que se colaba entre campo y campo). Con el grupo, el contenido se recorre
/// entero en su sitio: barra superior → contenido → pie fijo.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => AppFocusGroup(child: super.buildScrollbar(context, child, details));
}
