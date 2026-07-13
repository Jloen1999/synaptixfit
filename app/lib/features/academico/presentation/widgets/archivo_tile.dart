import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../../../core/design_system/sv_shapes.dart';
import '../../application/artefacto_efimero_provider.dart';
import '../../application/documento_ia_provider.dart';
import '../../application/generacion_global_provider.dart';
import '../../application/materiales_estudio_provider.dart';
import '../../application/practica_provider.dart';
import '../../infrastructure/estudio_ia_service.dart';
import '../../../../shared/models/db_models.dart';
import '../../domain/archivo_asignatura_dto.dart';
import '../../domain/fuente_estudio.dart';
import '../centro_generacion_screen.dart';
import '../cuestionario_formato_screen.dart';
import '../mapa_mental_screen.dart';
import '../resumen_ia_screen.dart';

/// Fila plana de un archivo ya almacenado (Clean UI) con indicadores de
/// documentos generados por IA (resumen / mapa mental).
///
/// Micro-chip semántico (icono según tipo) + nombre con ellipsis + peso, y
/// acción de eliminar.
class ArchivoTile extends ConsumerWidget {
  const ArchivoTile({
    required this.archivo,
    required this.onAbrir,
    required this.onEliminar,
    this.onLongPress,
    this.modoSeleccion = false,
    this.seleccionado = false,
    this.onToggleSeleccion,
    this.materialId,
    super.key,
  });

  final ArchivoAsignaturaDto archivo;
  final VoidCallback onAbrir;
  final VoidCallback onEliminar;
  final VoidCallback? onLongPress;
  final bool modoSeleccion;
  final bool seleccionado;
  final VoidCallback? onToggleSeleccion;
  final String? materialId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref
        .watch(docsGuardadosProvider((
          fuenteTipo: 'archivo',
          fuenteId: archivo.id,
        )))
        .valueOrNull;
    final material = ref
        .watch(materialPorFuenteProvider((
          tipoOrigen: 'archivo',
          origenId: archivo.id,
        )))
        .valueOrNull;
    final tipo = archivo.tipo;
    final tieneResumen = docs?.resumen == true;
    final tieneMapa = docs?.mapa == true;
    final colorBorde = _colorSemaforo(material);
    final repasoMeta = _formatearProximoRepaso(material);

    final bancoData = material != null
        ? ref.watch(bancoPreguntasProvider(material.id))
        : null;
    final tienePreguntas = bancoData != null &&
        bancoData.hasValue &&
        bancoData.requireValue.total > 0;
    final totalPreguntas =
        bancoData?.hasValue == true ? bancoData!.requireValue.total : 0;

    final fuente = FuenteArchivo(
      titulo: archivo.nombreArchivo,
      fuenteId: archivo.id,
      asignaturaId: archivo.asignaturaId,
      url: archivo.urlPublica,
      mimeType: archivo.tipoMime ?? 'application/octet-stream',
    );

    return Material(
      color: SVColors.surfaceContainerLowest,
      borderRadius: SVShapes.standard12,
      elevation: 1,
      shadowColor: SVColors.outlineVariant.withValues(alpha: 0.2),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onAbrir,
        onLongPress: onLongPress,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: colorBorde != null
                ? Border(left: BorderSide(color: colorBorde, width: 3))
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                if (modoSeleccion) ...[
                  GestureDetector(
                    onTap: onToggleSeleccion,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: seleccionado
                              ? const Color(0xFF3B82F6)
                              : SVColors.outlineVariant,
                          width: 2,
                        ),
                        color: seleccionado
                            ? const Color(0xFF3B82F6)
                            : Colors.transparent,
                      ),
                      child: seleccionado
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: tipo.color.withValues(alpha: 0.12),
                    borderRadius: SVShapes.standard,
                  ),
                  child: Icon(tipo.icono, color: tipo.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        archivo.nombreArchivo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SVColors.onSurface,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        archivo.tamanoLegible,
                        style: const TextStyle(
                          color: SVColors.onSurfaceMuted,
                          fontSize: 11.5,
                        ),
                      ),
                      if (repasoMeta != null)
                        Text(repasoMeta,
                            style: const TextStyle(
                                color: SVColors.onSurfaceMuted,
                                fontSize: 11,
                                fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                _buildMenuArchivo(context, ref, fuente,
                    tieneResumen: tieneResumen,
                    tieneMapa: tieneMapa,
                    tienePreguntas: tienePreguntas,
                    totalPreguntas: totalPreguntas),
                IconButton(
                  onPressed: onEliminar,
                  icon: const Icon(Icons.delete_outline,
                      color: SVColors.onSurfaceMuted, size: 20),
                  tooltip: 'Eliminar',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color? _colorSemaforo(MaterialEstudioDb? material) {
  if (material == null) return null;
  final ahora = DateTime.now();
  if (material.siguienteRepasoEn != null &&
      material.siguienteRepasoEn!.isBefore(ahora)) {
    return const Color(0xFFEF5350);
  }
  return switch (material.estadoDominio) {
    'dominado' => const Color(0xFF4CAF50),
    'en_progreso' => const Color(0xFFFFC107),
    'necesita_repaso' => const Color(0xFFEF5350),
    _ => null,
  };
}

String? _formatearProximoRepaso(MaterialEstudioDb? material) {
  if (material == null || material.siguienteRepasoEn == null) return null;
  final f = DateFormat('d MMM', 'es').format(material.siguienteRepasoEn!);
  final ef = material.facilidad.toStringAsFixed(1);
  return 'Próximo repaso: $f · EF $ef';
}

/// Fila plana de un archivo en proceso de subida (Clean UI).
///
/// `LinearProgressIndicator` integrado con el color semántico del tipo de
/// archivo.
class ArchivoSubiendoTile extends StatelessWidget {
  const ArchivoSubiendoTile({
    required this.nombre,
    required this.progreso,
    super.key,
  });

  final String nombre;
  final double progreso;

  @override
  Widget build(BuildContext context) {
    final tipo = TipoArchivo.desdeNombre(nombre);
    final pct = (progreso.clamp(0.0, 1.0) * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: SVColors.surfaceContainerLowest,
        borderRadius: SVShapes.standard12,
        boxShadow: [
          BoxShadow(
            color: SVColors.outlineVariant.withValues(alpha: 0.2),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tipo.color.withValues(alpha: 0.12),
              borderRadius: SVShapes.standard,
            ),
            child: Icon(tipo.icono, color: tipo.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SVColors.onSurface,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: SVShapes.standard,
                  child: LinearProgressIndicator(
                    value: progreso <= 0 ? null : progreso.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: SVColors.surfaceContainerLow,
                    valueColor: AlwaysStoppedAnimation<Color>(tipo.color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Subiendo $pct%',
            style:
                const TextStyle(color: SVColors.onSurfaceMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

Widget _buildMenuArchivo(
  BuildContext context,
  WidgetRef ref,
  FuenteArchivo fuente, {
  required bool tieneResumen,
  required bool tieneMapa,
  required bool tienePreguntas,
  required int totalPreguntas,
}) {
  return PopupMenuButton<String>(
    icon:
        const Icon(Icons.more_vert, color: SVColors.onSurfaceVariant, size: 22),
    padding: EdgeInsets.zero,
    constraints: const BoxConstraints(),
    color: SVColors.surfaceContainerLowest,
    shape: RoundedRectangleBorder(borderRadius: SVShapes.standard12),
    onSelected: (action) {
      switch (action) {
        case 'resumen':
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ResumenIaScreen(fuente: fuente)));
        case 'mapa':
          Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => MapaMentalScreen(fuente: fuente)));
        case 'generar-resumen':
          _lanzarGeneracionArchivo(
              context, ref, fuente, TipoGeneracion.resumen);
        case 'generar-mapa':
          _lanzarGeneracionArchivo(
              context, ref, fuente, TipoGeneracion.mapaMental);
        case 'generar':
          _lanzarGeneracionArchivo(
              context, ref, fuente, TipoGeneracion.cuestionario);
        case 'practica':
          _iniciarPracticaArchivo(context, ref, fuente);
        case 'flashcards':
          _iniciarFlashcards(context, ref, fuente);
      }
    },
    itemBuilder: (_) => [
      if (tieneResumen)
        PopupMenuItem<String>(
          value: 'resumen',
          child: Row(children: [
            const Icon(Icons.article_outlined,
                size: 18, color: SVColors.primary),
            const SizedBox(width: 12),
            const Text('Ver resumen',
                style: TextStyle(
                    color: SVColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ]),
        )
      else
        PopupMenuItem<String>(
          value: 'generar-resumen',
          child: Row(children: [
            const Icon(Icons.article_outlined,
                size: 18, color: SVColors.primary),
            const SizedBox(width: 12),
            const Text('Generar resumen',
                style: TextStyle(
                    color: SVColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      if (tieneMapa)
        PopupMenuItem<String>(
          value: 'mapa',
          child: Row(children: [
            const Icon(Icons.account_tree_outlined,
                size: 18, color: SVColors.primary),
            const SizedBox(width: 12),
            const Text('Ver mapa mental',
                style: TextStyle(
                    color: SVColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ]),
        )
      else
        PopupMenuItem<String>(
          value: 'generar-mapa',
          child: Row(children: [
            const Icon(Icons.account_tree_outlined,
                size: 18, color: SVColors.primary),
            const SizedBox(width: 12),
            const Text('Generar mapa mental',
                style: TextStyle(
                    color: SVColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      PopupMenuItem<String>(
        value: 'generar',
        child: Row(children: [
          const Icon(Icons.auto_awesome_rounded,
              size: 18, color: SVColors.primary),
          const SizedBox(width: 12),
          Text(
              totalPreguntas > 0
                  ? 'Generar más preguntas'
                  : 'Generar preguntas',
              style: const TextStyle(
                  color: SVColors.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
      if (tienePreguntas)
        PopupMenuItem<String>(
          value: 'practica',
          child: Row(children: [
            const Icon(Icons.play_arrow_rounded,
                size: 18, color: SVColors.primary),
            const SizedBox(width: 12),
            Text('Iniciar práctica ($totalPreguntas)',
                style: const TextStyle(
                    color: SVColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      if (tienePreguntas)
        PopupMenuItem<String>(
          value: 'flashcards',
          child: Row(children: [
            const Icon(Icons.style_outlined, size: 18, color: SVColors.primary),
            const SizedBox(width: 12),
            const Text('Estudiar Flashcards',
                style: TextStyle(
                    color: SVColors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
    ],
  );
}

Future<void> _iniciarPracticaArchivo(
    BuildContext context, WidgetRef ref, FuenteArchivo fuente) async {
  try {
    final result = await Supabase.instance.client
        .from('materiales_estudio')
        .select('id')
        .eq('tipo_origen', 'archivo')
        .eq('origen_id', fuente.fuenteId)
        .maybeSingle();
    final materialId = result?['id'] as String?;
    if (materialId == null) return;
    final repo = ref.read(practicaRepositoryProvider);
    final banco = await repo.obtenerOCrearBanco(materialId);
    final session =
        await repo.crearSesion(materialId: materialId, bancoId: banco.id);
    if (context.mounted) {
      ref.invalidate(sesionActivaProvider(materialId));
      context.push('/academico/practica/$materialId?sessionId=${session.id}');
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al iniciar práctica: $e'),
          backgroundColor: const Color(0xFFC62828)));
    }
  }
}

Future<void> _iniciarFlashcards(
    BuildContext context, WidgetRef ref, FuenteArchivo fuente) async {
  try {
    final result = await Supabase.instance.client
        .from('materiales_estudio')
        .select('id')
        .eq('tipo_origen', 'archivo')
        .eq('origen_id', fuente.fuenteId)
        .maybeSingle();
    final materialId = result?['id'] as String?;
    if (materialId == null || !context.mounted) return;
    context.push('/academico/flashcards/$materialId');
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al abrir flashcards: $e'),
          backgroundColor: const Color(0xFFC62828)));
    }
  }
}

void _lanzarGeneracionArchivo(
  BuildContext context,
  WidgetRef ref,
  FuenteArchivo fuente,
  TipoGeneracion tipo,
) {
  final ia = EstudioIaService();
  if (!ia.disponible) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('IA no configurada.'),
        backgroundColor: Color(0xFFC62828)));
    return;
  }
  final notifier = ref.read(artefactoEfimeroProvider.notifier);
  notifier.limpiar();

  final tarea = ref.read(generacionGlobalProvider).registrar(
        titulo: fuente.titulo,
        tipo: tipo.name,
        onNavigate: () {},
      );

  notifier.iniciarYGenerar([fuente], tipo,
      asignaturaId: fuente.asignaturaId, tareaGlobalId: tarea.id);
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => tipo == TipoGeneracion.cuestionario
          ? const CuestionarioFormatoScreen()
          : CentroGeneracionScreen(
              tipo: tipo,
              asignaturaId: fuente.asignaturaId ?? '',
            ),
    ),
  );
}
