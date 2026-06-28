import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../application/documento_ia_provider.dart';
import '../../domain/fuente_estudio.dart';
import '../mapa_mental_screen.dart';
import '../resumen_ia_screen.dart';

enum _OpcionIa { resumen, mapa }

/// Muestra el bottom sheet "Asistente de estudio" con las acciones de IA
/// (resumen y mapa mental) y navega a la pantalla elegida. Marca con un badge
/// "Guardado" las acciones que ya tienen un documento persistido para la fuente.
///
/// Punto de entrada compartido por el visor de apuntes y el de archivos.
Future<void> mostrarAsistenteIa(
  BuildContext context,
  FuenteEstudio fuente,
) async {
  final opcion = await showModalBottomSheet<_OpcionIa>(
    context: context,
    backgroundColor: SVColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _AsistenteSheet(fuente: fuente),
  );
  if (opcion == null || !context.mounted) return;

  final Widget pantalla = switch (opcion) {
    _OpcionIa.resumen => ResumenIaScreen(fuente: fuente),
    _OpcionIa.mapa => MapaMentalScreen(fuente: fuente),
  };
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => pantalla));
}

class _AsistenteSheet extends ConsumerWidget {
  const _AsistenteSheet({required this.fuente});

  final FuenteEstudio fuente;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref
        .watch(docsGuardadosProvider(
          (fuenteTipo: fuente.fuenteTipo, fuenteId: fuente.fuenteId),
        ))
        .valueOrNull;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: SVColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome,
                    size: 18, color: SVColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Asistente de estudio',
                          style: TextStyle(
                              color: SVColors.onSurface,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      Text(
                        fuente.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: SVColors.onSurfaceMuted, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _Opcion(
            icono: Icons.summarize_outlined,
            titulo: 'Resumen',
            descripcion: 'Resume el material en puntos clave.',
            guardado: docs?.resumen ?? false,
            onTap: () => Navigator.pop(context, _OpcionIa.resumen),
          ),
          _Opcion(
            icono: Icons.account_tree_outlined,
            titulo: 'Mapa mental',
            descripcion: 'Visualiza las ideas como un mapa interactivo.',
            guardado: docs?.mapa ?? false,
            onTap: () => Navigator.pop(context, _OpcionIa.mapa),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.guardado,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final bool guardado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: SVColors.primary.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icono, color: SVColors.primary, size: 22),
      ),
      title: Text(titulo,
          style: const TextStyle(
              color: SVColors.onSurface, fontWeight: FontWeight.w700)),
      subtitle: Text(
        guardado ? 'Toca para ver el guardado' : descripcion,
        style: const TextStyle(color: SVColors.onSurfaceMuted, fontSize: 12.5),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (guardado) const _PillGuardado(),
          const Icon(Icons.chevron_right, color: SVColors.outlineVariant),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _PillGuardado extends StatelessWidget {
  const _PillGuardado();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: SVColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 12, color: SVColors.secondary),
          SizedBox(width: 4),
          Text('Guardado',
              style: TextStyle(
                  color: SVColors.secondary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
