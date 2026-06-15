import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Servicio de notificaciones locales para hitos desbloqueados.
// Emite un SnackBar con estilo gamificado cuando un hito pasa de bloqueado
// a disponible.
// ---------------------------------------------------------------------------

/// Clave global para mostrar SnackBars desde cualquier parte de la app
/// sin depender del BuildContext.
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class RetoNotificacionService {
  RetoNotificacionService._();

  /// Muestra una notificacion local cuando un hito se desbloquea.
  ///
  /// Utiliza [scaffoldMessengerKey] para acceder al [ScaffoldMessenger]
  /// sin necesidad de un [BuildContext] directo.
  static void notificarHitoDesbloqueado(String tituloHito) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.lock_open_rounded,
                color: Colors.amberAccent, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '¡Hito desbloqueado!',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    tituloHito,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
