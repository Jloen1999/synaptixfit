import 'package:flutter/widgets.dart';

/// Mantiene vivo lo que hay dentro de una pestaña interna ([TabBarView]) al
/// cambiar a otra: su bloc y su desplazamiento siguen al volver.
class AppKeepAlive extends StatefulWidget {
  const AppKeepAlive({super.key, required this.child});

  final Widget child;

  @override
  State<AppKeepAlive> createState() => _AppKeepAliveState();
}

class _AppKeepAliveState extends State<AppKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
