import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/insignia_dto.dart';
import '../infrastructure/insignias_repository.dart';
import '../infrastructure/insignia_engine.dart';
import '../infrastructure/racha_service.dart';

// ---------------------------------------------------------------------------
// Proveedores de infraestructura
// ---------------------------------------------------------------------------

final insigniasRepositoryProvider = Provider<InsigniasRepository>((ref) {
  return InsigniasRepository(Supabase.instance.client);
});

final insigniaEngineProvider = Provider<InsigniaEngine>((ref) {
  return InsigniaEngine(Supabase.instance.client);
});

final rachaServiceProvider = Provider<RachaService>((ref) {
  return RachaService(Supabase.instance.client);
});

// ---------------------------------------------------------------------------
// Proveedores de datos
// ---------------------------------------------------------------------------

/// Catálogo completo (obtenidas + bloqueadas).
final catalogoInsigniasProvider = FutureProvider<List<Insignia>>((ref) async {
  final repo = ref.watch(insigniasRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  return repo.obtenerCatalogo(userId);
});

/// Solo las obtenidas por el usuario.
final insigniasUsuarioProvider = FutureProvider<List<Insignia>>((ref) async {
  final repo = ref.watch(insigniasRepositoryProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  return repo.obtenerInsigniasUsuario(userId);
});

/// Cantidad de insignias obtenidas (para badges).
final insigniasCountProvider = FutureProvider<int>((ref) async {
  final insignias = await ref.watch(insigniasUsuarioProvider.future);
  return insignias.length;
});

/// Estado de la racha diaria.
final rachaStateProvider = FutureProvider<RachaState>((ref) async {
  final service = ref.watch(rachaServiceProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) {
    return const RachaState(diasConsecutivos: 0, mejorRacha: 0);
  }
  return service.calcularRacha(userId);
});

/// Cola de insignias recién obtenidas (para mostrar toast animado).
final insigniasRecienObtenidasProvider =
    StateProvider<List<Insignia>>((ref) => []);

// ---------------------------------------------------------------------------
// Acciones
// ---------------------------------------------------------------------------

/// Evalúa y otorga insignias según los criterios actuales del usuario.
/// Debe llamarse después de eventos clave: completar sesión, completar reto, etc.
Future<void> evaluarInsignias(WidgetRef ref) async {
  final engine = ref.read(insigniaEngineProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return;

  try {
    final nuevas = await engine.evaluarYOtorgar(userId);
    if (nuevas.isNotEmpty) {
      ref.read(insigniasRecienObtenidasProvider.notifier).state = nuevas;
      ref.invalidate(catalogoInsigniasProvider);
      ref.invalidate(insigniasUsuarioProvider);
      ref.invalidate(insigniasCountProvider);
    }
  } catch (e) {
    debugPrint('[evaluarInsignias] Error: $e');
  }
}

/// Evalúa y otorga insignias usando [ProviderContainer] (sin [WidgetRef]).
/// Útil para llamar desde callbacks que no tienen acceso a un widget.
Future<void> evaluarInsigniasDesdeContainer(ProviderContainer container) async {
  final engine = container.read(insigniaEngineProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return;

  try {
    final nuevas = await engine.evaluarYOtorgar(userId);
    if (nuevas.isNotEmpty) {
      container.read(insigniasRecienObtenidasProvider.notifier).state = nuevas;
      container.invalidate(catalogoInsigniasProvider);
      container.invalidate(insigniasUsuarioProvider);
      container.invalidate(insigniasCountProvider);
    }
  } catch (_) {}
}

/// Muestra el toast de insignia recién obtenida usando Overlay.
void mostrarInsigniaToast(BuildContext context, List<Insignia> insignias) {
  if (insignias.isEmpty) return;

  // Solo mostramos la primera; las demás quedan en cola para la próxima evaluación
  final insignia = insignias.first;

  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => _InsigniaToastWidget(
      insignia: insignia,
      onDismiss: () {
        entry.remove();
        // Limpiar del provider después de mostrar
        final container = ProviderScope.containerOf(context);
        container.read(insigniasRecienObtenidasProvider.notifier).state = [];
      },
    ),
  );

  overlay.insert(entry);

  // Auto-dismiss tras 4 segundos
  Future.delayed(const Duration(seconds: 4), () {
    if (entry.mounted) {
      entry.remove();
    }
  });
}

// ---------------------------------------------------------------------------
// Widget interno del toast
// ---------------------------------------------------------------------------

class _InsigniaToastWidget extends StatefulWidget {
  const _InsigniaToastWidget({
    required this.insignia,
    required this.onDismiss,
  });

  final Insignia insignia;
  final VoidCallback onDismiss;

  @override
  State<_InsigniaToastWidget> createState() => _InsigniaToastWidgetState();
}

class _InsigniaToastWidgetState extends State<_InsigniaToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnim = Tween<double>(begin: -80, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();

    // Auto-dismiss después de 4s con fade out
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _rarezaColor(String rareza) {
    switch (rareza) {
      case 'legendaria':
        return const Color(0xFFFBBF24);
      case 'epica':
        return const Color(0xFFA78BFA);
      case 'rara':
        return const Color(0xFF60A5FA);
      default:
        return const Color(0xFF4ADE80);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _rarezaColor(widget.insignia.rareza);
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 12,
      left: 16,
      right: 16,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnim.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnim.value),
              child: child,
            ),
          );
        },
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E293B),
                  color.withValues(alpha: 0.15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icono grande
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.3),
                        color.withValues(alpha: 0.1),
                      ],
                    ),
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: Text(
                      widget.insignia.icono,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '¡Nueva insignia!',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.insignia.nombre,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFF1F5F9),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.insignia.descripcion,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF94A3B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Botón cerrar
                GestureDetector(
                  onTap: widget.onDismiss,
                  child: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: Color(0xFF64748B),
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
