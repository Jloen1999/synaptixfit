import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../application/calendar_grid_provider.dart';
import '../../application/inbox_config_provider.dart';
import '../../domain/calendar_dtos.dart';

class RutinaConfigSheet extends ConsumerStatefulWidget {
  const RutinaConfigSheet({super.key});

  @override
  ConsumerState<RutinaConfigSheet> createState() => _RutinaConfigSheetState();
}

class _RutinaConfigSheetState extends ConsumerState<RutinaConfigSheet> {
  String? _rutinaId;
  String? _rutinaNombre;
  int _duracionMinutos = 60;
  final Set<int> _diasSeleccionados = {};
  DateTime _fechaInicio = DateTime.now();
  bool _creando = false;
  int? _totalDiasRutina;
  bool _cargandoDias = false;

  static const _diasLabels = ['L', 'Ma', 'Mi', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    _fechaInicio = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
  }

  String get _duracionLabel {
    final horas = _duracionMinutos ~/ 60;
    final minutos = _duracionMinutos % 60;
    if (minutos == 0) {
      return 'Duración: ${horas}h';
    }
    return 'Duración: ${horas}h ${minutos}min';
  }

  int get _bloquesEstimados {
    final rutina = _rutinaSeleccionada;
    if (rutina == null || _diasSeleccionados.isEmpty) return 0;
    if (_totalDiasRutina != null && _totalDiasRutina! > 0) {
      return _totalDiasRutina!;
    }
    return rutina.duracionSemanas * _diasSeleccionados.length;
  }

  RutinaActivaItem? get _rutinaSeleccionada {
    if (_rutinaId == null) return null;
    final config = ref.read(inboxConfigProvider);
    return config.rutinasActivas.where((r) => r.id == _rutinaId).firstOrNull;
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

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(inboxConfigProvider);
    final rutinas = config.rutinasActivas;
    final tema = Theme.of(context);

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
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.fitness_center,
                    color: Color(0xFF059669), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Distribuir rutina deportiva',
                  style: tema.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRutinaSelector(rutinas),
            const SizedBox(height: 16),
            _buildDiasSelector(),
            const SizedBox(height: 16),
            _buildDuracionSlider(),
            const SizedBox(height: 16),
            _buildFechaPicker(),
            if (_bloquesEstimados > 0) ...[
              const SizedBox(height: 12),
              _buildResumen(),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _puedeCrear && !_creando ? _crearDistribucion : null,
                icon: _creando
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.fitness_center, size: 18),
                label: Text(_creando
                    ? 'Creando bloques...'
                    : _cargandoDias
                        ? 'Calculando días...'
                        : 'Crear $_bloquesEstimados bloques'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  bool get _puedeCrear =>
      _rutinaId != null &&
      _diasSeleccionados.isNotEmpty &&
      !_cargandoDias &&
      _bloquesEstimados > 0;

  Widget _buildRutinaSelector(List<RutinaActivaItem> rutinas) {
    final tema = Theme.of(context);

    if (rutinas.isEmpty) {
      return Card(
        elevation: 0,
        color: Colors.orange.withValues(alpha: 0.08),
        child: const ListTile(
          dense: true,
          leading: Icon(Icons.warning_amber, color: Colors.orange, size: 20),
          title: Text('Sin rutinas activas',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          subtitle: Text(
              'Crea una rutina de entrenamiento para distribuirla en el calendario',
              style: TextStyle(fontSize: 11)),
        ),
      );
    }

    final selectedLabel = _rutinaNombre ?? 'Seleccionar rutina';

    return InkWell(
      onTap: () => _mostrarRutinaPicker(rutinas),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Rutina',
          isDense: true,
          suffixIcon: const Icon(Icons.arrow_drop_down, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          selectedLabel,
          style: TextStyle(
            fontSize: 14,
            color: _rutinaNombre != null
                ? tema.colorScheme.onSurface
                : Colors.grey,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
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
        maxChildSize: 0.6,
        expand: false,
        builder: (ctx, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
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
            ...rutinas.map((r) => ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fitness_center,
                        color: Color(0xFF059669), size: 18),
                  ),
                  title: Text(r.nombre,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${r.objetivo} · ${r.duracionSemanas} semanas · ${r.cantidadEjercicios} ejercicios'),
                  selected: r.id == _rutinaId,
                  onTap: () {
                    setState(() {
                      _rutinaId = r.id;
                      _rutinaNombre = r.nombre;
                      _totalDiasRutina = null;
                    });
                    _cargarTotalDias(r.id);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDiasSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Días de entrenamiento',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(7, (i) {
            final dia = i + 1;
            final selected = _diasSeleccionados.contains(dia);
            return FilterChip(
              label: Text(_diasLabels[i], style: const TextStyle(fontSize: 12)),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _diasSeleccionados.add(dia);
                  } else {
                    _diasSeleccionados.remove(dia);
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
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildDuracionSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.schedule, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Text(_duracionLabel,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        Slider(
          value: _duracionMinutos.toDouble(),
          min: 30,
          max: 120,
          divisions: 6,
          label: _duracionLabel,
          onChanged: (v) => setState(() => _duracionMinutos = v.round()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('30min',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            Text('120min',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
      ],
    );
  }

  Widget _buildFechaPicker() {
    final fechaStr =
        '${_fechaInicio.day}/${_fechaInicio.month}/${_fechaInicio.year}';
    final hoy =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF059669).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.calendar_today,
            color: Color(0xFF059669), size: 18),
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
          initialDate: _fechaInicio,
          firstDate: hoy,
          lastDate: hoy.add(const Duration(days: 180)),
          helpText: 'Fecha de inicio de la rutina',
        );
        if (picked != null && mounted) {
          setState(() => _fechaInicio = picked);
        }
      },
    );
  }

  Widget _buildResumen() {
    final semanas = _rutinaSeleccionada?.duracionSemanas ?? 0;
    final semanasNecesarias = _diasSeleccionados.isNotEmpty
        ? (_bloquesEstimados / _diasSeleccionados.length).ceil()
        : 0;

    final String descripcion;
    if (_cargandoDias) {
      descripcion = 'Calculando días de entrenamiento...';
    } else if (_totalDiasRutina != null && _totalDiasRutina! > 0) {
      descripcion =
          'Rutina con $_totalDiasRutina días de entrenamiento ($semanas semanas). '
          'Distribuidos en $semanasNecesarias semanas reales a partir de la fecha de inicio.';
    } else {
      descripcion =
          'Rutina de $semanas semanas × ${_diasSeleccionados.length} días/semana (estimado). '
          'Distribuidos en $semanasNecesarias semanas reales a partir de la fecha de inicio.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF059669).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: const Color(0xFF059669).withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFF059669), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _cargandoDias
                      ? 'Calculando...'
                      : 'Se crearán $_bloquesEstimados bloques de entrenamiento',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF059669),
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            descripcion,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Future<void> _crearDistribucion() async {
    if (_rutinaId == null || _rutinaNombre == null) return;
    if (_diasSeleccionados.isEmpty) return;

    setState(() => _creando = true);

    try {
      final count =
          await ref.read(calendarGridProvider.notifier).placeRutinaDistribuida(
                rutinaId: _rutinaId!,
                rutinaNombre: _rutinaNombre!,
                diasSemana: _diasSeleccionados.toList(),
                duracionMinutos: _duracionMinutos,
                fechaInicio: _fechaInicio,
                duracionSemanas: _rutinaSeleccionada?.duracionSemanas ?? 1,
              );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('$count bloques de deporte distribuidos en el calendario'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _creando = false);
    }
  }
}
