import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../retos/application/retos_core.dart';
import '../../application/calendar_grid_provider.dart';
import '../../application/entregas_examenes_provider.dart';
import '../../application/inbox_config_provider.dart';
import '../../domain/calendar_dtos.dart';
import '../../infrastructure/grid_math.dart';
import 'pickers.dart';

enum _TipoBloque { estudio, clase, examen, entrega, deporte, reto }

class AcademicBlockSheet extends ConsumerStatefulWidget {
  const AcademicBlockSheet({
    required this.fecha,
    required this.horaInicio,
    this.editBlock,
    super.key,
  });

  final DateTime fecha;
  final TimeOfDay horaInicio;
  final TimeBlock? editBlock;

  @override
  ConsumerState<AcademicBlockSheet> createState() => _AcademicBlockSheetState();
}

class _AcademicBlockSheetState extends ConsumerState<AcademicBlockSheet> {
  _TipoBloque _tipo = _TipoBloque.estudio;
  double _duracionHoras = 1.0;
  String? _asignaturaId;
  String? _asignaturaNombre;
  String? _rutinaId;
  String? _rutinaNombre;
  String? _retoId;
  String? _retoTitulo;
  String? _retoTipo;
  final _tituloCtrl = TextEditingController();
  final _temaInputCtrl = TextEditingController();
  final _aulaCtrl = TextEditingController();
  final _temas = <String>[];
  TimeOfDay? _horaExamen;
  TimeOfDay? _horaInicioOverride;
  bool _creando = false;

  final Set<int> _diasDistribucion = {};
  DateTime _fechaInicioDistribucion = DateTime.now();
  int? _totalDiasRutina;
  bool _cargandoDias = false;
  int? _duracionSemanasRutina;

  bool get _esEdicion => widget.editBlock != null;

  @override
  void initState() {
    super.initState();
    _cargarDiasDisponiblesPerfil();
    final b = widget.editBlock;
    if (b != null) {
      _duracionHoras = b.duracionHoras.clamp(0.5, 4.0);
      _asignaturaId = b.asignaturaId;
      _asignaturaNombre = b.asignaturaNombre;
      _rutinaId = b.rutinaId;
      _rutinaNombre = b.rutinaNombre;
      _retoId = b.retoId;
      _retoTitulo = b.retoTitulo;
      _retoTipo = null;

      switch (b.tipo) {
        case TimeBlockTipo.deporte:
          _tipo = _TipoBloque.deporte;
          break;
        case TimeBlockTipo.clase:
          _tipo = _TipoBloque.clase;
          if (b.ubicacion != null) _aulaCtrl.text = b.ubicacion!;
          break;
        case TimeBlockTipo.examen:
          _tipo = _TipoBloque.examen;
          if (b.titulo != null) _tituloCtrl.text = b.titulo!;
          if (b.ubicacion != null) _aulaCtrl.text = b.ubicacion!;
          break;
        case TimeBlockTipo.entrega:
          _tipo = _TipoBloque.entrega;
          if (b.titulo != null) _tituloCtrl.text = b.titulo!;
          break;
        case TimeBlockTipo.estudio:
        default:
          _tipo = _TipoBloque.estudio;
          break;
      }

      if (b.temas != null && b.temas!.isNotEmpty) {
        final texto = b.temas!;
        if (texto.startsWith('Examen: ') || texto.startsWith('Entrega: ')) {
          if (_tituloCtrl.text.isEmpty) {
            _tituloCtrl.text = texto.substring(texto.indexOf(': ') + 2);
          }
          if (texto.startsWith('Examen: ')) {
            _tipo = _TipoBloque.examen;
          } else {
            _tipo = _TipoBloque.entrega;
          }
        } else if (_tipo == _TipoBloque.estudio) {
          _temas.addAll(texto.split(' | ').where((t) => t.isNotEmpty));
        }
      }
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _temaInputCtrl.dispose();
    _aulaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDiasDisponiblesPerfil() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;
      final data = await client
          .from('perfil_bienestar_usuario')
          .select('dias_disponibles')
          .eq('usuario_id', userId)
          .maybeSingle();
      if (data != null && data['dias_disponibles'] != null && mounted) {
        final dias = (data['dias_disponibles'] as List)
            .map((e) => e is int ? e : int.tryParse('$e') ?? 0)
            .where((e) => e >= 1 && e <= 7)
            .toSet();
        if (dias.isNotEmpty) {
          setState(() => _diasDistribucion.addAll(dias));
        }
      }
    } catch (_) {}
  }

  /// Hora de inicio efectiva del bloque: la del override (si el usuario la
  /// cambió, p. ej. en una clase) o la de la celda pulsada.
  TimeOfDay get _inicio => _horaInicioOverride ?? widget.horaInicio;

  TimeOfDay get _horaFin {
    final min =
        (_inicio.hour * 60 + _inicio.minute + (_duracionHoras * 60).round())
            .clamp(0, 23 * 60 + 59);
    return TimeOfDay(hour: min ~/ 60, minute: min % 60);
  }

  void _agregarTema() {
    final texto = _temaInputCtrl.text.trim();
    if (texto.isEmpty) return;
    setState(() {
      _temas.add(texto);
      _temaInputCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final asignaturasAsync = ref.watch(asignaturasActivasInboxProvider);
    final config = ref.watch(inboxConfigProvider);
    final rutinas = config.rutinasActivas;
    final tema = Theme.of(context);
    final diaLabel = GridMath.dayHeaderLabel(widget.fecha);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
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
                  color: tema.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Cabecera: icono del tipo + título + día y franja horaria
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _colorTipo().withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(_iconoTipo(), color: _colorTipo(), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _esEdicion ? 'Editar bloque' : 'Nuevo bloque',
                        style: tema.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.event_outlined,
                              size: 13,
                              color: tema.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(diaLabel,
                              style: tema.textTheme.bodySmall?.copyWith(
                                  color: tema.colorScheme.onSurfaceVariant)),
                          const SizedBox(width: 10),
                          Icon(Icons.schedule,
                              size: 13,
                              color: tema.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '${GridMath.formatTimeOfDay(_inicio)}–${GridMath.formatTimeOfDay(_horaFin)}',
                            style: tema.textTheme.bodySmall?.copyWith(
                                color: tema.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _sectionLabel('Tipo de bloque'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _tipoChip(_TipoBloque.estudio, 'Estudio', Icons.menu_book),
                _tipoChip(_TipoBloque.clase, 'Clase', Icons.school),
                _tipoChip(_TipoBloque.examen, 'Examen', Icons.quiz),
                _tipoChip(_TipoBloque.entrega, 'Entrega', Icons.assignment),
                _tipoChip(_TipoBloque.deporte, 'Deporte', Icons.fitness_center),
                _tipoChip(_TipoBloque.reto, 'Reto', Icons.emoji_events),
              ],
            ),
            const SizedBox(height: 18),
            _sectionLabel('Detalles'),
            const SizedBox(height: 8),
            if (_tipo != _TipoBloque.deporte && _tipo != _TipoBloque.reto)
              asignaturasAsync.when(
                data: (asignaturas) => _buildAsignaturaSelector(asignaturas),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error cargando asignaturas',
                    style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            if (_tipo == _TipoBloque.deporte) ...[
              _buildRutinaPickerButton(rutinas),
              if (_rutinaId != null) _buildDistribucionSection(),
            ],
            if (_tipo == _TipoBloque.reto) _buildRetoPicker(),
            if (_tipo == _TipoBloque.estudio) _buildTemasSection(),
            if (_tipo == _TipoBloque.clase) _buildClaseFields(),
            if (_tipo == _TipoBloque.examen) _buildExamenFields(),
            if (_tipo == _TipoBloque.entrega) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _tituloCtrl,
                decoration: const InputDecoration(
                  labelText: 'Título del entregable',
                  isDense: true,
                  prefixIcon: Icon(Icons.assignment, size: 18),
                ),
              ),
            ],
            const SizedBox(height: 18),
            _sectionLabel('Duración'),
            const SizedBox(height: 4),
            _buildDuracionSlider(),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _creando ? null : _crearBloque,
                icon: _creando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Icon(_iconoTipo(), size: 20),
                label: Text(_labelBoton(),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  backgroundColor: _colorTipo(),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            if (_esEdicion) ...[
              const SizedBox(height: 6),
              Center(
                child: TextButton.icon(
                  onPressed: _creando ? null : _eliminarBloque,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Eliminar bloque'),
                  style: TextButton.styleFrom(
                    foregroundColor: tema.colorScheme.error,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildTemasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            Text('Temas a repasar',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Text('· obligatorio',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _temaInputCtrl,
                decoration: InputDecoration(
                  hintText: 'Ej: Capítulo 3, Ejercicios derivadas...',
                  hintStyle:
                      TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                style: const TextStyle(fontSize: 13),
                onSubmitted: (_) => _agregarTema(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _agregarTema,
              icon: const Icon(Icons.add, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                minimumSize: const Size(40, 40),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        if (_temas.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _temas.asMap().entries.map((entry) {
              return Chip(
                label: Text(entry.value, style: const TextStyle(fontSize: 11)),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () => setState(() => _temas.removeAt(entry.key)),
                visualDensity: VisualDensity.compact,
                backgroundColor:
                    const Color(0xFF3B82F6).withValues(alpha: 0.08),
                side: BorderSide(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }

  Color _colorDeTipo(_TipoBloque tipo) {
    return switch (tipo) {
      _TipoBloque.estudio => const Color(0xFF3B82F6),
      _TipoBloque.clase => const Color(0xFF64748B),
      _TipoBloque.examen => const Color(0xFFD97706),
      _TipoBloque.entrega => const Color(0xFFDC2626),
      _TipoBloque.deporte => const Color(0xFFF97316),
      _TipoBloque.reto => const Color(0xFF7B1FA2),
    };
  }

  Widget _tipoChip(_TipoBloque tipo, String label, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    final sel = _tipo == tipo;
    final color = _colorDeTipo(tipo);
    return ChoiceChip(
      label: Text(label),
      avatar: Icon(icon, size: 16, color: sel ? color : cs.onSurfaceVariant),
      selected: sel,
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      backgroundColor: cs.surfaceContainerHigh,
      selectedColor: color.withValues(alpha: 0.16),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: sel ? color : cs.onSurfaceVariant,
      ),
      side: BorderSide(
        color: sel
            ? color.withValues(alpha: 0.6)
            : cs.outlineVariant.withValues(alpha: 0.5),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onSelected: (_) => setState(() => _tipo = tipo),
    );
  }

  Widget _buildClaseFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: _inicio,
              helpText: 'Hora de inicio de la clase',
            );
            if (picked != null) {
              setState(() => _horaInicioOverride = picked);
            }
          },
          icon: const Icon(Icons.schedule, size: 16),
          label: Text('Inicio: ${GridMath.formatTimeOfDay(_inicio)}',
              style: const TextStyle(fontSize: 13)),
          style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            minimumSize: const Size(double.infinity, 44),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _aulaCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Aula (opcional)',
            isDense: true,
            prefixIcon: Icon(Icons.room, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildExamenFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        TextField(
          controller: _tituloCtrl,
          decoration: const InputDecoration(
            labelText: 'Título del examen',
            isDense: true,
            prefixIcon: Icon(Icons.quiz, size: 18),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: widget.horaInicio,
                    helpText: 'Hora del examen',
                  );
                  if (picked != null) {
                    setState(() => _horaExamen = picked);
                  }
                },
                icon: const Icon(Icons.schedule, size: 16),
                label: Text(
                  _horaExamen != null
                      ? 'Hora: ${GridMath.formatTimeOfDay(_horaExamen!)}'
                      : 'Hora del examen (opcional)',
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _aulaCtrl,
          decoration: const InputDecoration(
            labelText: 'Aula (opcional)',
            isDense: true,
            prefixIcon: Icon(Icons.room, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildAsignaturaSelector(List<AsignaturaActivaItem> asignaturas) {
    if (_asignaturaId == null && asignaturas.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _asignaturaId = asignaturas.first.id;
            _asignaturaNombre = asignaturas.first.nombre;
          });
        }
      });
    }

    if (asignaturas.isEmpty) {
      return Card(
        elevation: 0,
        color: Colors.orange.withValues(alpha: 0.08),
        child: ListTile(
          dense: true,
          leading:
              const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
          title: const Text('Sin asignaturas',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          subtitle: const Text('Configura tu carrera para cargar asignaturas',
              style: TextStyle(fontSize: 11)),
          trailing: TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/academico/configuracion');
            },
            child: const Text('Configurar'),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _mostrarSelectorAsignatura(asignaturas),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Asignatura',
          isDense: true,
          suffixIcon: Icon(Icons.arrow_drop_down, size: 20),
        ),
        child: Text(
          _asignaturaNombre ?? 'Seleccionar',
          style: TextStyle(
            fontSize: 14,
            color: _asignaturaNombre != null
                ? Theme.of(context).colorScheme.onSurface
                : Colors.grey,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _mostrarSelectorAsignatura(List<AsignaturaActivaItem> asignaturas) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _AsignaturaSearchSheet(
        asignaturas: asignaturas,
        seleccionadaId: _asignaturaId,
        onSelected: (a) {
          setState(() {
            _asignaturaId = a.id;
            _asignaturaNombre = a.nombre;
          });
        },
      ),
    );
  }

  Widget _buildRutinaPickerButton(List<RutinaActivaItem> rutinas) {
    final selectedLabel = _rutinaNombre ?? 'Seleccionar rutina';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _mostrarRutinaPicker(rutinas),
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Rutina',
              isDense: true,
              suffixIcon: Icon(Icons.arrow_drop_down, size: 20),
            ),
            child: Text(
              selectedLabel,
              style: TextStyle(
                fontSize: 14,
                color: _rutinaNombre != null
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.push('/bienestar/nueva-rutina');
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Crear rutina nueva'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarRutinaPicker(List<RutinaActivaItem> rutinas) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.7,
        expand: false,
        builder: (ctx, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          child: RoutinePicker(
            rutinas: rutinas,
            onSelected: (r) {
              setState(() {
                _rutinaId = r.id;
                _rutinaNombre = r.nombre;
                _duracionSemanasRutina = r.duracionSemanas;
                _totalDiasRutina = null;
              });
              _cargarTotalDias(r.id);
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _cargarTotalDias(String rutinaId) async {
    setState(() => _cargandoDias = true);
    try {
      final client = Supabase.instance.client;
      final semanasData = await client
          .from('semanas_rutina')
          .select('id')
          .eq('rutina_id', rutinaId);
      final semanaIds = (semanasData as List)
          .map((s) => (s as Map<String, dynamic>)['id'] as String)
          .toList();
      if (semanaIds.isEmpty) {
        if (mounted) {
          setState(() {
            _totalDiasRutina = null;
            _cargandoDias = false;
          });
        }
        return;
      }
      final diasData = await client
          .from('dias_rutina')
          .select('id')
          .inFilter('semana_id', semanaIds);
      final total = (diasData as List).length;
      if (mounted) {
        setState(() {
          _totalDiasRutina = total > 0 ? total : null;
          _cargandoDias = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _totalDiasRutina = null;
          _cargandoDias = false;
        });
      }
    }
  }

  int get _bloquesDistribucion {
    if (_diasDistribucion.isEmpty) return 0;
    if (_totalDiasRutina != null && _totalDiasRutina! > 0) {
      return _totalDiasRutina!;
    }
    final semanas = _duracionSemanasRutina ?? 1;
    return semanas * _diasDistribucion.length;
  }

  static const _diasLabels = ['L', 'Ma', 'Mi', 'J', 'V', 'S', 'D'];

  Widget _buildDistribucionSection() {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text('Días disponibles',
            style: tema.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(7, (i) {
            final dia = i + 1;
            final selected = _diasDistribucion.contains(dia);
            return FilterChip(
              label: Text(_diasLabels[i], style: const TextStyle(fontSize: 12)),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _diasDistribucion.add(dia);
                  } else {
                    _diasDistribucion.remove(dia);
                  }
                });
              },
              visualDensity: VisualDensity.compact,
              selectedColor: const Color(0xFF059669).withValues(alpha: 0.15),
              checkmarkColor: const Color(0xFF059669),
              side: BorderSide(
                color:
                    selected ? const Color(0xFF059669) : Colors.grey.shade300,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            );
          }),
        ),
        const SizedBox(height: 12),
        _buildFechaInicioPicker(),
        if (_bloquesDistribucion > 0 || _cargandoDias) ...[
          const SizedBox(height: 10),
          _buildDistribucionResumen(),
        ],
      ],
    );
  }

  Widget _buildFechaInicioPicker() {
    final fechaStr =
        '${_fechaInicioDistribucion.day}/${_fechaInicioDistribucion.month}/${_fechaInicioDistribucion.year}';
    final hoy =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFF059669).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.calendar_today,
            color: Color(0xFF059669), size: 16),
      ),
      title: const Text('Fecha de inicio',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(fechaStr, style: const TextStyle(fontSize: 12)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _fechaInicioDistribucion,
          firstDate: hoy,
          lastDate: hoy.add(const Duration(days: 180)),
        );
        if (picked != null && mounted) {
          setState(() => _fechaInicioDistribucion = picked);
        }
      },
    );
  }

  Widget _buildDistribucionResumen() {
    final total = _bloquesDistribucion;
    final semanasReales = _diasDistribucion.isNotEmpty
        ? (total / _diasDistribucion.length).ceil()
        : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: const Color(0xFF059669).withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF059669), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _cargandoDias
                  ? 'Calculando días de entrenamiento...'
                  : '$total bloques en ~$semanasReales semanas',
              style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetoPicker() {
    final retosAsync = ref.watch(retosProvider);

    return retosAsync.when(
      data: (retos) {
        final activos = retos.where((r) => !r.reto.estaCompletado).toList();
        if (activos.isEmpty) {
          return Card(
            elevation: 0,
            color: Colors.orange.withValues(alpha: 0.08),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.emoji_events_rounded,
                  color: Colors.orange, size: 20),
              title: const Text('Sin retos activos',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              subtitle: const Text('Crea un reto para vincularlo al bloque',
                  style: TextStyle(fontSize: 11)),
              trailing: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/retos/crear');
                },
                child: const Text('Crear reto'),
              ),
            ),
          );
        }

        final selectedLabel = _retoTitulo ?? 'Seleccionar reto';

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => _mostrarRetoPickerModal(activos),
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Reto',
                  isDense: true,
                  suffixIcon: Icon(Icons.arrow_drop_down, size: 20),
                ),
                child: Text(
                  selectedLabel,
                  style: TextStyle(
                    fontSize: 14,
                    color: _retoTitulo != null
                        ? Theme.of(context).colorScheme.onSurface
                        : Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (_retoId != null) ...[
              const SizedBox(height: 8),
              Text(
                'El bloque heredará el color y tipo del reto',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('Error cargando retos',
          style: TextStyle(color: Colors.red, fontSize: 12)),
    );
  }

  void _mostrarRetoPickerModal(List<RetoResumen> retos) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.7,
        expand: false,
        builder: (ctx, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          child: ChallengePicker(
            retos: retos,
            onSelected: (r) {
              setState(() {
                _retoId = r.reto.id;
                _retoTitulo = r.reto.titulo;
                _retoTipo = r.reto.tipo;
              });
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDuracionSlider() {
    final durLabel = _duracionHoras % 1 == 0
        ? '${_duracionHoras.toInt()} h'
        : '${_duracionHoras.toStringAsFixed(1)} h';
    final color = _colorTipo();

    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.15),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.12),
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            ),
            child: Slider(
              value: _duracionHoras,
              min: 0.5,
              max: 4.0,
              divisions: 7,
              label: durLabel,
              onChanged: (v) => setState(() => _duracionHoras = v),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(durLabel,
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: color, fontSize: 13)),
        ),
      ],
    );
  }

  Color _colorTipo() {
    if (_tipo == _TipoBloque.reto) {
      return _retoTipo == 'fitness'
          ? const Color(0xFFF97316)
          : const Color(0xFF7B1FA2);
    }
    return _colorDeTipo(_tipo);
  }

  IconData _iconoTipo() {
    return switch (_tipo) {
      _TipoBloque.estudio => Icons.menu_book,
      _TipoBloque.clase => Icons.school,
      _TipoBloque.examen => Icons.quiz,
      _TipoBloque.entrega => Icons.assignment,
      _TipoBloque.deporte => Icons.fitness_center,
      _TipoBloque.reto => Icons.emoji_events,
    };
  }

  String _labelBoton() {
    if (_esEdicion) return 'Guardar cambios';
    if (_tipo == _TipoBloque.deporte && _rutinaId != null) {
      return 'Distribuir $_bloquesDistribucion bloques';
    }
    return switch (_tipo) {
      _TipoBloque.estudio => 'Crear bloque de estudio',
      _TipoBloque.clase => 'Registrar clase',
      _TipoBloque.examen => 'Registrar examen',
      _TipoBloque.entrega => 'Registrar entrega',
      _TipoBloque.deporte => 'Crear sesión de deporte',
      _TipoBloque.reto => 'Vincular reto',
    };
  }

  Future<void> _eliminarBloque() async {
    final blockId = widget.editBlock?.idLocal;
    if (blockId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar bloque'),
        content: const Text(
            '¿Seguro que quieres eliminar este bloque? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    ref.read(calendarGridProvider.notifier).removeBlock(blockId);
    if (mounted) Navigator.pop(context);
  }

  /// Valida los campos obligatorios según el tipo de bloque.
  /// Devuelve un mensaje de error o null si todo es válido.
  String? _validarCampos() {
    switch (_tipo) {
      case _TipoBloque.estudio:
        if (_asignaturaId == null) return 'Selecciona una asignatura';
        if (_temas.isEmpty) return 'Añade al menos un tema a repasar';
      case _TipoBloque.clase:
        if (_asignaturaId == null) return 'Selecciona una asignatura';
      case _TipoBloque.examen:
        if (_asignaturaId == null) return 'Selecciona una asignatura';
        if (_tituloCtrl.text.trim().isEmpty) {
          return 'Introduce el título del examen';
        }
      case _TipoBloque.entrega:
        if (_asignaturaId == null) return 'Selecciona una asignatura';
        if (_tituloCtrl.text.trim().isEmpty) {
          return 'Introduce el título del entregable';
        }
      case _TipoBloque.deporte:
        if (!_esEdicion) {
          if (_rutinaId == null) return 'Selecciona o crea una rutina';
          if (_diasDistribucion.isEmpty) {
            return 'Selecciona al menos un día de la semana';
          }
        }
      case _TipoBloque.reto:
        if (_retoId == null) return 'Selecciona un reto';
    }
    return null;
  }

  Future<void> _crearBloque() async {
    // Si hay un tema escrito pero sin añadir, lo añadimos automáticamente para
    // no perder la información antes de validar.
    if (_tipo == _TipoBloque.estudio && _temaInputCtrl.text.trim().isNotEmpty) {
      _agregarTema();
    }

    // Validación de campos obligatorios (al crear y al editar): no se permite
    // guardar un bloque sin su información esencial.
    final error = _validarCampos();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    setState(() => _creando = true);

    try {
      final notifier = ref.read(calendarGridProvider.notifier);
      final temasStr = _temas.isNotEmpty ? _temas.join(' | ') : null;
      final editBlock = widget.editBlock;

      if (editBlock != null) {
        // Modo edición: actualizar bloque existente
        final tipo = switch (_tipo) {
          _TipoBloque.estudio => TimeBlockTipo.estudio,
          _TipoBloque.clase => TimeBlockTipo.clase,
          _TipoBloque.examen => TimeBlockTipo.examen,
          _TipoBloque.entrega => TimeBlockTipo.entrega,
          _TipoBloque.deporte => TimeBlockTipo.deporte,
          _TipoBloque.reto => _retoTipo == 'fitness'
              ? TimeBlockTipo.deporte
              : TimeBlockTipo.estudio,
        };
        notifier.updateBlock(
          blockId: editBlock.idLocal,
          diaSemana: widget.fecha.weekday,
          horaInicio: _inicio,
          horaFin: _horaFin,
          tipo: tipo,
          asignaturaId: _asignaturaId,
          asignaturaNombre: _asignaturaNombre,
          rutinaId: _rutinaId,
          rutinaNombre: _rutinaNombre,
          titulo: (_tipo == _TipoBloque.examen || _tipo == _TipoBloque.entrega)
              ? _tituloCtrl.text.trim()
              : null,
          ubicacion: (_tipo == _TipoBloque.examen || _tipo == _TipoBloque.clase)
              ? _aulaCtrl.text.trim()
              : null,
          temas: _tipo == _TipoBloque.estudio
              ? temasStr
              : (_tipo == _TipoBloque.clase ? _asignaturaNombre : null),
          retoId: _retoId,
          retoTitulo: _retoTitulo,
        );
        if (mounted) Navigator.pop(context);
        return;
      }

      switch (_tipo) {
        case _TipoBloque.estudio:
          notifier.placeBlock(
            asignaturaId: _asignaturaId,
            asignaturaNombre: _asignaturaNombre,
            diaSemana: widget.fecha.weekday,
            horaInicio: _inicio,
            horaFin: _horaFin,
            tipo: TimeBlockTipo.estudio,
            temas: temasStr,
            fecha: widget.fecha,
          );

        case _TipoBloque.clase:
          final aula = _aulaCtrl.text.trim();
          notifier.placeBlock(
            asignaturaId: _asignaturaId,
            asignaturaNombre: _asignaturaNombre,
            diaSemana: widget.fecha.weekday,
            horaInicio: _inicio,
            horaFin: _horaFin,
            tipo: TimeBlockTipo.clase,
            ubicacion: aula.isNotEmpty ? aula : null,
            temas: _asignaturaNombre,
            fecha: widget.fecha,
          );

        case _TipoBloque.examen:
          final titulo = _tituloCtrl.text.trim();
          if (titulo.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Introduce el título del examen')),
            );
            setState(() => _creando = false);
            return;
          }
          final horaEx = _horaExamen ?? widget.horaInicio;
          final fechaLimite = DateTime(widget.fecha.year, widget.fecha.month,
              widget.fecha.day, horaEx.hour, horaEx.minute);
          final aula = _aulaCtrl.text.trim();
          await crearEntrega(
            titulo: titulo,
            tipo: 'examen',
            fechaLimite: fechaLimite,
            dificultad: 'media',
            asignaturaId: _asignaturaId,
            ref: ref,
          );
          notifier.placeBlock(
            asignaturaId: _asignaturaId,
            asignaturaNombre: _asignaturaNombre,
            diaSemana: widget.fecha.weekday,
            horaInicio: widget.horaInicio,
            horaFin: _horaFin,
            tipo: TimeBlockTipo.examen,
            titulo: titulo,
            ubicacion: aula.isNotEmpty ? aula : null,
            fecha: widget.fecha,
          );

        case _TipoBloque.entrega:
          final titulo = _tituloCtrl.text.trim();
          if (titulo.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Introduce el título del entregable')),
            );
            setState(() => _creando = false);
            return;
          }
          await crearEntrega(
            titulo: titulo,
            tipo: 'entrega',
            fechaLimite: DateTime(widget.fecha.year, widget.fecha.month,
                widget.fecha.day, _horaFin.hour, _horaFin.minute),
            dificultad: 'media',
            asignaturaId: _asignaturaId,
            ref: ref,
          );
          notifier.placeBlock(
            asignaturaId: _asignaturaId,
            asignaturaNombre: _asignaturaNombre,
            diaSemana: widget.fecha.weekday,
            horaInicio: widget.horaInicio,
            horaFin: _horaFin,
            tipo: TimeBlockTipo.entrega,
            titulo: titulo,
            fecha: widget.fecha,
          );

        case _TipoBloque.deporte:
          if (_rutinaId != null) {
            if (_diasDistribucion.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Selecciona al menos un día de la semana')),
              );
              setState(() => _creando = false);
              return;
            }
            final durMin = (_duracionHoras * 60).round();
            final count = await notifier.placeRutinaDistribuida(
              rutinaId: _rutinaId!,
              rutinaNombre: _rutinaNombre ?? '',
              diasSemana: _diasDistribucion.toList(),
              duracionMinutos: durMin,
              fechaInicio: _fechaInicioDistribucion,
              duracionSemanas: _duracionSemanasRutina ?? 1,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '$count bloques de deporte distribuidos en el calendario'),
                  backgroundColor: const Color(0xFF059669),
                ),
              );
            }
          } else {
            notifier.placeBlock(
              asignaturaId: null,
              asignaturaNombre: null,
              diaSemana: widget.fecha.weekday,
              horaInicio: widget.horaInicio,
              horaFin: _horaFin,
              tipo: TimeBlockTipo.deporte,
              rutinaId: _rutinaId,
              rutinaNombre: _rutinaNombre,
              fecha: widget.fecha,
            );
          }

        case _TipoBloque.reto:
          if (_retoId == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Selecciona un reto primero')),
            );
            setState(() => _creando = false);
            return;
          }
          final bloqueTipo = _retoTipo == 'fitness'
              ? TimeBlockTipo.deporte
              : TimeBlockTipo.estudio;
          notifier.placeBlock(
            asignaturaId: _asignaturaId,
            asignaturaNombre: _asignaturaNombre,
            diaSemana: widget.fecha.weekday,
            horaInicio: widget.horaInicio,
            horaFin: _horaFin,
            tipo: bloqueTipo,
            retoId: _retoId,
            retoTitulo: _retoTitulo,
            fecha: widget.fecha,
          );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _creando = false);
    }
  }
}

class _AsignaturaSearchSheet extends StatefulWidget {
  const _AsignaturaSearchSheet({
    required this.asignaturas,
    required this.onSelected,
    this.seleccionadaId,
  });

  final List<AsignaturaActivaItem> asignaturas;
  final ValueChanged<AsignaturaActivaItem> onSelected;
  final String? seleccionadaId;

  @override
  State<_AsignaturaSearchSheet> createState() => _AsignaturaSearchSheetState();
}

class _AsignaturaSearchSheetState extends State<_AsignaturaSearchSheet> {
  final _buscarCtrl = TextEditingController();
  List<AsignaturaActivaItem> _filtradas = [];

  @override
  void initState() {
    super.initState();
    _filtradas = widget.asignaturas;
  }

  @override
  void dispose() {
    _buscarCtrl.dispose();
    super.dispose();
  }

  void _filtrar(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _filtradas = q.isEmpty
          ? widget.asignaturas
          : widget.asignaturas
              .where((a) => a.nombre.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _buscarCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Buscar asignatura...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: _buscarCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _buscarCtrl.clear();
                              _filtrar('');
                            },
                          )
                        : null,
                  ),
                  onChanged: _filtrar,
                ),
              ],
            ),
          ),
          Expanded(
            child: _filtradas.isEmpty
                ? Center(
                    child: Text(
                      'Sin resultados',
                      style: tema.textTheme.bodyMedium
                          ?.copyWith(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _filtradas.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final a = _filtradas[i];
                      final selected = a.id == widget.seleccionadaId;
                      return ListTile(
                        dense: true,
                        selected: selected,
                        leading: Icon(
                          Icons.menu_book_rounded,
                          size: 20,
                          color: selected
                              ? const Color(0xFF3B82F6)
                              : Colors.grey.shade400,
                        ),
                        title: Text(
                          a.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                        trailing: selected
                            ? const Icon(Icons.check_circle,
                                color: Color(0xFF3B82F6), size: 18)
                            : null,
                        onTap: () {
                          widget.onSelected(a);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
