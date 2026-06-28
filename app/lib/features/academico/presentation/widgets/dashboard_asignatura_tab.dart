import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/sv_colors.dart';
import '../../../../core/design_system/sv_shapes.dart';
import '../../application/guia_docente_provider.dart';
import '../../application/materiales_estudio_provider.dart';
import '../../domain/guia_docente_dto.dart';
import 'directorio_docente_widget.dart';
import 'rastreador_temario_widget.dart';
import 'simulador_calificaciones_widget.dart';

class DashboardAsignaturaTab extends ConsumerWidget {
  const DashboardAsignaturaTab({
    required this.asignaturaId,
    required this.asignaturaNombre,
    required this.color,
    super.key,
  });

  final String asignaturaId;
  final String asignaturaNombre;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guiaAsync = ref.watch(guiaDocenteDtoProvider(asignaturaId));
    final uiState = ref.watch(guiaDocenteStateProvider);

    return guiaAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _estadoError(context, ref, uiState, e.toString()),
      data: (guia) {
        if (guia == null || !guia.tieneDatos) {
          return _estadoVacio(context, ref, uiState);
        }
        return _dashboardConDatos(context, ref, guia, uiState);
      },
    );
  }

  Widget _estadoVacio(
    BuildContext context,
    WidgetRef ref,
    GuiaDocenteState uiState,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        _DominioRealWidget(asignaturaId: asignaturaId, color: color),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: const BoxDecoration(
            color: SVColors.surfaceContainerLowest,
            borderRadius: SVShapes.standard12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_outlined,
                  size: 42, color: color.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              const Text(
                'Dashboard inteligente',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SVColors.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sube la guía docente de esta asignatura para desbloquear '
                'el directorio de profesores, el simulador de calificaciones '
                'y el rastreador de temario.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SVColors.onSurfaceMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: _BotonExtraer(
                  onPressed: () => _iniciarExtraccion(context, ref),
                  analizando: uiState.analizando,
                  guardando: uiState.guardando,
                  color: color,
                ),
              ),
              if (uiState.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  uiState.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: SVColors.error,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _estadoError(
    BuildContext context,
    WidgetRef ref,
    GuiaDocenteState uiState,
    String error,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        _DominioRealWidget(asignaturaId: asignaturaId, color: color),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: const BoxDecoration(
            color: SVColors.surfaceContainerLowest,
            borderRadius: SVShapes.standard12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 42, color: SVColors.error),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar la guía',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: SVColors.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SVColors.onSurfaceMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: _BotonExtraer(
                  onPressed: () => _iniciarExtraccion(context, ref),
                  analizando: uiState.analizando,
                  guardando: uiState.guardando,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dashboardConDatos(
    BuildContext context,
    WidgetRef ref,
    GuiaDocenteDto guia,
    GuiaDocenteState uiState,
  ) {
    final notifier = ref.read(guiaDocenteStateProvider.notifier);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(guiaDocenteDtoProvider(asignaturaId));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          _DominioRealWidget(asignaturaId: asignaturaId, color: color),
          const SizedBox(height: 18),
          DirectorioDocenteWidget(profesores: guia.profesores),
          const SizedBox(height: 24),
          if (guia.evaluacion.isNotEmpty)
            SimuladorCalificacionesWidget(
              evaluacion: guia.evaluacion,
              colorAsignatura: color,
              onNotaCambiada: (indice, nota) {
                notifier.actualizarNota(
                  asignaturaId: asignaturaId,
                  indice: indice,
                  nota: nota,
                );
              },
            ),
          if (guia.evaluacion.isNotEmpty && guia.temario.isNotEmpty)
            const SizedBox(height: 24),
          if (guia.temario.isNotEmpty)
            RastreadorTemarioWidget(
              temario: guia.temario,
              colorAsignatura: color,
              onToggleTema: (indice, completado) {
                notifier.toggleTema(
                  asignaturaId: asignaturaId,
                  indice: indice,
                  completado: completado,
                );
              },
            ),
          if (guia.temario.isNotEmpty && guia.bibliografia.isNotEmpty)
            const SizedBox(height: 24),
          if (guia.bibliografia.isNotEmpty)
            _BibliografiaSeccion(bibliografia: guia.bibliografia, color: color),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: SVColors.surfaceContainerLowest,
              borderRadius: SVShapes.standard12,
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome_outlined,
                    size: 16, color: color.withValues(alpha: 0.5)),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Guía docente analizada por IA',
                    style: TextStyle(
                      color: SVColors.onSurfaceMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(
                  height: 34,
                  child: _BotonExtraer(
                    onPressed: () => _iniciarExtraccion(context, ref),
                    analizando: uiState.analizando,
                    guardando: uiState.guardando,
                    color: color,
                    compacto: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _iniciarExtraccion(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No se pudo abrir el selector de archivos')),
        );
      }
      return;
    }
    if (result == null || result.files.isEmpty) return;

    final archivo = result.files.first;
    final bytes = archivo.bytes;
    if (bytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo leer el archivo')),
        );
      }
      return;
    }

    final notifier = ref.read(guiaDocenteStateProvider.notifier);
    final dto = await notifier.extraerYGuardar(
      asignaturaId: asignaturaId,
      pdfBytes: bytes,
      asignaturaNombre: asignaturaNombre,
    );

    if (dto != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Guía docente analizada: ${dto.temario.length} temas, '
            '${dto.evaluacion.length} criterios de evaluación',
          ),
        ),
      );
    }
  }
}

class _BotonExtraer extends StatelessWidget {
  const _BotonExtraer({
    required this.onPressed,
    required this.analizando,
    required this.guardando,
    required this.color,
    this.compacto = false,
  });

  final VoidCallback onPressed;
  final bool analizando;
  final bool guardando;
  final Color color;
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    final ocupado = analizando || guardando;
    final label = compacto ? 'Reanalizar' : 'Configurar con Guía Docente';

    if (compacto) {
      return OutlinedButton(
        onPressed: ocupado ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: const RoundedRectangleBorder(borderRadius: SVShapes.standard),
          minimumSize: const Size(0, 34),
        ),
        child: ocupado
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Text(
                label,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
      );
    }

    return FilledButton.icon(
      onPressed: ocupado ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: SVColors.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: const RoundedRectangleBorder(borderRadius: SVShapes.standard12),
      ),
      icon: ocupado
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: SVColors.onPrimary),
            )
          : const Icon(Icons.upload_file_outlined, size: 20),
      label: Text(
        analizando
            ? 'Analizando guía docente…'
            : guardando
                ? 'Guardando…'
                : label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}

class _BibliografiaSeccion extends StatelessWidget {
  const _BibliografiaSeccion({
    required this.bibliografia,
    required this.color,
  });

  final List<String> bibliografia;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Bibliografía',
            style: TextStyle(
              color: SVColors.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: const BoxDecoration(
            color: SVColors.surfaceContainerLowest,
            borderRadius: SVShapes.standard12,
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(bibliografia.length, (i) {
              final ref = bibliografia[i];
              return Padding(
                padding: EdgeInsets.only(
                    top: i > 0 ? 8 : 0,
                    bottom: i < bibliografia.length - 1 ? 8 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ref,
                        style: const TextStyle(
                          color: SVColors.onSurface,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _DominioRealWidget extends ConsumerWidget {
  const _DominioRealWidget({
    required this.asignaturaId,
    required this.color,
  });

  final String asignaturaId;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricas = ref.watch(metricasRetencionProvider(asignaturaId));

    return metricas.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (m) {
        if (m.total == 0) return const SizedBox.shrink();
        final pct = m.total > 0
            ? (m.dominados / m.total * 100).round()
            : 0;
        final pendientes = m.necesitaRepaso + m.sinEvaluar;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SVColors.surfaceContainerLowest,
            borderRadius: SVShapes.standard12,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.psychology_outlined,
                      size: 18, color: color),
                  const SizedBox(width: 8),
                  const Text('Dominio del temario',
                      style: TextStyle(
                        color: SVColors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      )),
                  const Spacer(),
                  Text('$pct%',
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      )),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: m.total > 0 ? m.dominados / m.total : 0,
                  backgroundColor: SVColors.surfaceContainerHighest,
                  color: const Color(0xFF4CAF50),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _miniChip('${m.dominados} dominados',
                      const Color(0xFF4CAF50)),
                  _miniChip('${m.enCurso} en curso',
                      const Color(0xFFFFC107)),
                  _miniChip('$pendientes pendientes',
                      const Color(0xFFEF5350)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _miniChip(String label, Color chipColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: chipColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: SVColors.onSurfaceMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}
