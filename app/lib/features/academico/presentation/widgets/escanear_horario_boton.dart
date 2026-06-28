import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/asignaturas_provider.dart';
import '../../application/escanear_horario_provider.dart';
import '../../infrastructure/ai_schedule_parser_service.dart';
import '../../../perfil/application/perfil_provider.dart';

/// Botón + flujo completo «Escanear horario con IA» con estética Clean UI.
///
/// Flujo:
/// 1. Verifica si el semestre tiene fechas configuradas en el perfil académico.
/// 2. Rama A (sin fechas): solicita inicio/fin en un BottomSheet plano y las
///    guarda en el perfil antes de continuar.
/// 3. Rama B (con fechas): omite el modal y procede de inmediato.
/// 4. Selecciona el documento (PDF/imagen), lo analiza con IA, genera las
///    clases y muestra feedback (progreso + SnackBar).
class EscanearHorarioBoton extends ConsumerStatefulWidget {
  const EscanearHorarioBoton({super.key});

  @override
  ConsumerState<EscanearHorarioBoton> createState() =>
      _EscanearHorarioBotonState();
}

class _EscanearHorarioBotonState extends ConsumerState<EscanearHorarioBoton> {
  bool _procesando = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: Material(
        color: cs.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _procesando ? null : _iniciar,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: _procesando
                      ? Padding(
                          padding: const EdgeInsets.all(6),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: cs.primary),
                        )
                      : Icon(Icons.document_scanner_outlined,
                          size: 17, color: cs.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _procesando
                        ? 'Analizando horario…'
                        : 'Escanear horario con IA',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600, color: cs.onSurface),
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Orquestación del flujo
  // ---------------------------------------------------------------------------

  Future<void> _iniciar() async {
    // Verificación previa: ¿el semestre ya tiene fechas configuradas?
    final perfil = await ref.read(perfilAcademicoProvider.future);

    if (perfil != null && perfil.tieneFechasSemestre) {
      // Rama B: fricción cero.
      await _seleccionarYProcesar(
        perfil.fechaInicioClases!,
        perfil.fechaFinClases!,
      );
      return;
    }

    // Rama A: solicitar fechas (y guardarlas para el futuro).
    if (!mounted) return;
    final rango = await _pedirFechasSemestre();
    if (rango == null) return;

    await guardarFechasSemestre(
      inicio: rango.$1,
      fin: rango.$2,
      ref: ref,
    );
    await _seleccionarYProcesar(rango.$1, rango.$2);
  }

  Future<(DateTime, DateTime)?> _pedirFechasSemestre() {
    return showModalBottomSheet<(DateTime, DateTime)>(
      context: context,
      isScrollControlled: true,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _FechasSemestreSheet(),
    );
  }

  Future<void> _seleccionarYProcesar(DateTime inicio, DateTime fin) async {
    final FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );
    } catch (_) {
      _mostrarSnack('No se pudo abrir el selector de archivos', error: true);
      return;
    }

    if (result == null || result.files.isEmpty) return; // cancelado

    final file = result.files.single;
    final Uint8List? bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      _mostrarSnack('No se pudo leer el documento seleccionado', error: true);
      return;
    }
    final mime = _mimeDesdeExtension(file.extension);
    if (mime == null) {
      _mostrarSnack('Formato no admitido. Usa PDF o imagen.', error: true);
      return;
    }

    setState(() => _procesando = true);
    try {
      final asignaturas = await ref.read(asignaturasActivasProvider.future);
      final nombres = asignaturas.map((a) => a.nombre).toList();

      final servicio = ref.read(aiScheduleParserServiceProvider);
      final paquete = await servicio.parseAndAssembleSchedule(
        bytes: bytes,
        mimeType: mime,
        subjects: nombres,
        semesterStart: inicio,
        semesterEnd: fin,
      );

      final res = await generarHorariosDesdePaquete(paquete, asignaturas, ref);

      if (!mounted) return;
      _mostrarExito(res);
    } on AiParsingException catch (e) {
      _mostrarSnack(e.message, error: true);
    } catch (e) {
      _mostrarSnack('No se pudo sincronizar el horario: $e', error: true);
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _mostrarExito(GeneracionHorarioResultado res) {
    const base = 'Horario sincronizado con éxito';
    final detalle = res.asignaturasSinVincular.isEmpty
        ? base
        : '$base · ${res.asignaturasSinVincular.length} sin vincular';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(detalle),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  void _mostrarSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: error ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  String? _mimeDesdeExtension(String? ext) {
    switch ((ext ?? '').toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return null;
    }
  }
}

// =============================================================================
// BottomSheet plano (Clean UI) para solicitar las fechas del semestre
// =============================================================================
class _FechasSemestreSheet extends StatefulWidget {
  const _FechasSemestreSheet();

  @override
  State<_FechasSemestreSheet> createState() => _FechasSemestreSheetState();
}

class _FechasSemestreSheetState extends State<_FechasSemestreSheet> {
  DateTime? _inicio;
  DateTime? _fin;

  bool get _valido =>
      _inicio != null && _fin != null && _fin!.isAfter(_inicio!);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fmt = DateFormat('d MMM y', 'es');

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Fechas del semestre',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Las usaremos para colocar tus clases en el calendario. Solo se piden una vez.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          _campoFecha(
            label: 'Fecha de inicio',
            valor: _inicio == null ? 'Seleccionar' : fmt.format(_inicio!),
            activo: _inicio != null,
            onTap: () => _elegir(esInicio: true),
          ),
          const SizedBox(height: 10),
          _campoFecha(
            label: 'Fecha de fin',
            valor: _fin == null ? 'Seleccionar' : fmt.format(_fin!),
            activo: _fin != null,
            onTap: () => _elegir(esInicio: false),
          ),
          if (_inicio != null && _fin != null && !_fin!.isAfter(_inicio!)) ...[
            const SizedBox(height: 10),
            Text('La fecha de fin debe ser posterior a la de inicio.',
                style: TextStyle(color: cs.error, fontSize: 12)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _valido
                  ? () => Navigator.pop(context, (_inicio!, _fin!))
                  : null,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Continuar',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _campoFecha({
    required String label,
    required String valor,
    required bool activo,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.event_outlined, size: 20, color: cs.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(valor,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: activo ? cs.onSurface : cs.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _elegir({required bool esInicio}) async {
    final ahora = DateTime.now();
    final base =
        (esInicio ? _inicio : _fin) ?? (esInicio ? ahora : (_inicio ?? ahora));
    final picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(ahora.year - 1),
      lastDate: DateTime(ahora.year + 2),
      helpText: esInicio ? 'Inicio del semestre' : 'Fin del semestre',
    );
    if (picked == null) return;
    setState(() {
      if (esInicio) {
        _inicio = picked;
      } else {
        _fin = picked;
      }
    });
  }
}
