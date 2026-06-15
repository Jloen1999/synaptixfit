import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../application/sync_provider.dart';
import '../../domain/connectivity_state.dart';

// ---------------------------------------------------------------------------
// Widget que muestra una barra de estado en la parte superior de la app
// cuando el dispositivo esta offline o sincronizando cambios pendientes.
// ---------------------------------------------------------------------------

class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityStateProvider).valueOrNull;
    final syncProgress = ref.watch(syncProgressProvider);
    final syncProgressText = ref.watch(syncProgressTextProvider);

    final bool syncing = syncProgress > 0.0 && syncProgress < 1.0;
    final bool offline = connectivity == ConnectivityState.offline && !syncing;

    // Si hay sincronizacion activa, mostramos banner azul con progreso
    if (syncing) {
      final message =
          syncProgressText.isNotEmpty ? syncProgressText : 'Sincronizando...';
      return _Banner(
        color: SVColors.kpiSesiones,
        icon: Icons.sync_rounded,
        message: message,
      );
    }

    // Si esta offline, mostramos banner rojo
    if (offline) {
      return const _Banner(
        color: SVColors.error,
        icon: Icons.wifi_off_rounded,
        message: 'Sin conexion — cambios guardados localmente',
      );
    }

    // Online: no mostrar nada
    return const SizedBox.shrink();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner interno con animacion de entrada/salida
// ─────────────────────────────────────────────────────────────────────────────

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.icon,
    required this.message,
  });

  final Color color;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Container(
          key: ValueKey(message),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          color: color,
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
