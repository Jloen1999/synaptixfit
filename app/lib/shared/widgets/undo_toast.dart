import 'dart:async';

import 'package:flutter/material.dart';

/// Toast de acción ("Deshacer") auto-descartable, independiente del
/// `ScaffoldMessenger`.
///
/// ¿Por qué no usar `SnackBar`? El temporizador de auto-cierre del
/// `ScaffoldMessenger` solo arranca cuando la animación de entrada del SnackBar
/// se asienta; si el árbol se reconstruye en ese momento (p. ej. al invalidar
/// providers tras completar un bloque), el temporizador puede no iniciarse y el
/// SnackBar se queda "pegado" hasta que el usuario lo cierra a mano.
///
/// [UndoToast] usa un [OverlayEntry] con su **propio** [Timer], propiedad del
/// estado del overlay, por lo que el cierre automático NO depende del ciclo de
/// rebuilds del resto de la app. Si [onAction] es null, se muestra como un
/// simple toast informativo sin botón.
class UndoToast {
  UndoToast._();

  static OverlayEntry? _current;

  static void show(
    BuildContext context, {
    required String message,
    String actionLabel = 'Deshacer',
    VoidCallback? onAction,
    VoidCallback? onTimeout,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    // Cierra cualquier toast anterior sin disparar su callback de timeout.
    _current?.remove();
    _current = null;

    late OverlayEntry entry;
    var resolved = false;

    void dismiss({required bool byAction}) {
      if (resolved) return;
      resolved = true;
      if (_current == entry) _current = null;
      entry.remove();
      if (byAction) {
        onAction?.call();
      } else {
        onTimeout?.call();
      }
    }

    entry = OverlayEntry(
      builder: (_) => _UndoToastView(
        message: message,
        actionLabel: actionLabel,
        duration: duration,
        showAction: onAction != null,
        onAction: () => dismiss(byAction: true),
        onTimeout: () => dismiss(byAction: false),
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }
}

class _UndoToastView extends StatefulWidget {
  const _UndoToastView({
    required this.message,
    required this.actionLabel,
    required this.duration,
    required this.showAction,
    required this.onAction,
    required this.onTimeout,
  });

  final String message;
  final String actionLabel;
  final Duration duration;
  final bool showAction;
  final VoidCallback onAction;
  final VoidCallback onTimeout;

  @override
  State<_UndoToastView> createState() => _UndoToastViewState();
}

class _UndoToastViewState extends State<_UndoToastView>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  )..forward();

  @override
  void initState() {
    super.initState();
    // Temporizador propio: garantiza el auto-cierre pase lo que pase en el árbol.
    _timer = Timer(widget.duration, widget.onTimeout);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Positioned(
      left: 16,
      right: 16,
      bottom: media.viewInsets.bottom + media.padding.bottom + 16,
      child: FadeTransition(
        opacity: _anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.25),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut)),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding:
                  EdgeInsets.fromLTRB(16, 12, widget.showAction ? 8 : 16, 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (widget.showAction)
                    TextButton(
                      onPressed: widget.onAction,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF72FE8F),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(0, 36),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        widget.actionLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
