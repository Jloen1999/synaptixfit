import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../academico/application/usuario_carreras_provider.dart';
import '../../bienestar/application/rutina_provider.dart';
import '../../dashboard/application/dashboard_provider.dart';
import '../../auth/infrastructure/bienestar_repository.dart';
import '../application/perfil_provider.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  PerfilUsuario? _cachedUsuario;
  PerfilActividad? _cachedActividad;
  PreferenciasNotificacionDb? _cachedPrefs;
  PerfilBienestarCompleto? _cachedBienestar;

  void _onPerfilActualizado({PerfilCambio cambio = PerfilCambio.todo}) {
    switch (cambio) {
      case PerfilCambio.nombre:
        ref.invalidate(perfilUsuarioProvider);
      case PerfilCambio.bienestar:
        ref.invalidate(perfilBienestarProvider);
        ref.invalidate(perfilBienestarCompletoProvider);
        ref.invalidate(perfilUsuarioProvider);
      case PerfilCambio.preferencias:
        ref.invalidate(perfilPreferenciasProvider);
      case PerfilCambio.todo:
        ref.invalidate(perfilBienestarProvider);
        ref.invalidate(perfilUsuarioProvider);
        ref.invalidate(perfilBienestarCompletoProvider);
        ref.invalidate(perfilActividadProvider);
        ref.invalidate(perfilPreferenciasProvider);
    }
    ref.invalidate(dashboardProvider);
  }

  @override
  Widget build(BuildContext context) {
    final usuarioAsync = ref.watch(perfilUsuarioProvider);
    final actividadAsync = ref.watch(perfilActividadProvider);
    final preferenciasAsync = ref.watch(perfilPreferenciasProvider);

    // Actualizar cachés cuando llegan datos nuevos.
    if (usuarioAsync.hasValue) _cachedUsuario = usuarioAsync.value;
    if (actividadAsync.hasValue) _cachedActividad = actividadAsync.value;
    if (preferenciasAsync.hasValue) _cachedPrefs = preferenciasAsync.value;

    // Solo mostrar loading en la primera carga (sin datos cacheados).
    if (usuarioAsync.isLoading && _cachedUsuario == null) {
      return const FeatureScaffold(
        title: '',
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final usuarioData = _cachedUsuario;
    if (usuarioData == null) {
      return const FeatureScaffold(
        title: '',
        child: Center(child: Text('Error al cargar perfil')),
      );
    }

    final usuario = usuarioData.usuario;
    final perfil = usuarioData.perfil;
    final actividad = _cachedActividad ??
        const PerfilActividad(sesiones: 0, logros: 0, caloriasAcumuladas: 0);
    final preferencias = _cachedPrefs ??
        PreferenciasNotificacionDb(
          id: '',
          usuarioId: '',
          categoriasActivas: const [],
          limiteDiario: 10,
          modoActual: 'normal',
          creadoEn: DateTime.now(),
          actualizadoEn: DateTime.now(),
        );

    final bienestarAsync = ref.watch(perfilBienestarCompletoProvider);
    if (bienestarAsync.hasValue) _cachedBienestar = bienestarAsync.value;
    final historial = _cachedBienestar?.historial ?? <HistorialPesoDb>[];

    return FeatureScaffold(
      title: '',
      child: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: _HeroHeader(
                usuario: usuario,
                perfil: perfil,
                onNombreChanged: () =>
                    _onPerfilActualizado(cambio: PerfilCambio.nombre),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  tabs: const [
                    Tab(text: 'Estadísticas'),
                    Tab(text: 'Bienestar'),
                    Tab(text: 'Ajustes'),
                  ],
                  labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  indicatorSize: TabBarIndicatorSize.label,
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _EstadisticasTab(
                usuario: usuario,
                sesiones: actividad.sesiones,
                logros: actividad.logros,
                caloriasAcumuladas: actividad.caloriasAcumuladas,
              ),
              _BienestarTab(
                perfil: perfil,
                historial: historial,
                onPerfilChanged: () =>
                    _onPerfilActualizado(cambio: PerfilCambio.bienestar),
              ),
              _AjustesTab(usuario: usuario, prefs: preferencias),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// HERO HEADER — Modern athletic dashboard
// =============================================================================
class _HeroHeader extends StatefulWidget {
  const _HeroHeader({
    required this.usuario,
    required this.perfil,
    this.onNombreChanged,
  });

  final UsuarioDb usuario;
  final PerfilBienestarDb perfil;
  final VoidCallback? onNombreChanged;

  @override
  State<_HeroHeader> createState() => _HeroHeaderState();
}

class _HeroHeaderState extends State<_HeroHeader> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nombre = widget.usuario.nombreCompleto;
    final initial =
        nombre.isNotEmpty && nombre != '—' ? nombre[0].toUpperCase() : '?';
    final xpMax = 1000 * widget.usuario.nivel;
    final xpProgreso =
        xpMax > 0 ? (widget.usuario.xpTotal / xpMax).clamp(0.0, 1.0) : 0.0;
    final tieneAvatar = widget.usuario.urlAvatar != null &&
        widget.usuario.urlAvatar!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A1628), Color(0xFF152238), Color(0xFF0D1B2A)],
        ),
      ),
      child: Column(
        children: [
          // Avatar — gradient border ring
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF72FE8F), Color(0xFF006E2D)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF72FE8F).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: ClipOval(
              child: Container(
                color: const Color(0xFF1A2A40),
                child: tieneAvatar
                    ? Image.network(
                        widget.usuario.urlAvatar!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _avatarInitial(initial, 24);
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            _avatarInitial(initial, 24),
                      )
                    : _avatarInitial(initial, 24),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Name row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  nombre,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => _editarNombre(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.edit, size: 14, color: Colors.white54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            widget.usuario.email,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          // XP Level badge + bar
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded,
                        size: 16, color: Color(0xFF72FE8F)),
                    const SizedBox(width: 6),
                    Text(
                      'Nivel ${widget.usuario.nivel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${widget.usuario.xpTotal} / $xpMax XP',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: xpProgreso,
                        minHeight: 5,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF72FE8F),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _miniStat('🔥', '${widget.usuario.rachaActual}', 'racha'),
              const SizedBox(width: 24),
              _miniStat(
                  '📅', '${widget.perfil.diasDisponiblesSemana}', 'días/sem'),
              const SizedBox(width: 24),
              _miniStat('⏱', '${widget.perfil.minutosPorSesion}', 'min/ses'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarInitial(String initial, double size) {
    return Container(
      color: const Color(0xFF1A2A40),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: const Color(0xFF72FE8F),
          fontSize: size,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _miniStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 10)),
      ],
    );
  }

  Future<void> _editarNombre(BuildContext context) async {
    final repo = const BienestarRepository();
    final ctrl = TextEditingController(text: widget.usuario.nombreCompleto);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar nombre'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Nombre completo'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      await repo.actualizarNombre(result);
      widget.onNombreChanged?.call();
    }
  }
}

// =============================================================================
// TAB 1: Estadísticas — Metric grid with glass cards
// =============================================================================
class _EstadisticasTab extends StatelessWidget {
  const _EstadisticasTab({
    required this.usuario,
    required this.sesiones,
    required this.logros,
    required this.caloriasAcumuladas,
  });

  final UsuarioDb usuario;
  final int sesiones;
  final int logros;
  final int caloriasAcumuladas;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: _metricCard(
                '${usuario.xpTotal}',
                'XP Total',
                subtitle: 'Nivel ${usuario.nivel}',
                color: const Color(0xFF72FE8F),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                '$sesiones',
                'Sesiones',
                color: const Color(0xFF60A5FA),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                '$logros',
                'Retos',
                color: const Color(0xFFE8A838),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                '$caloriasAcumuladas',
                'Calorías',
                color: const Color(0xFFFF6B35),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _metricCard(
          '${usuario.rachaActual}',
          'Racha actual',
          subtitle: 'días consecutivos',
          color: const Color(0xFFA78BFA),
        ),
      ],
    );
  }

  Widget _metricCard(
    String value,
    String label, {
    String? subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// TAB 2: Bienestar — All onboarding fields editable
// =============================================================================
class _BienestarTab extends StatefulWidget {
  const _BienestarTab({
    required this.perfil,
    required this.historial,
    this.onPerfilChanged,
  });

  final PerfilBienestarDb perfil;
  final List<HistorialPesoDb> historial;
  final VoidCallback? onPerfilChanged;

  @override
  State<_BienestarTab> createState() => _BienestarTabState();
}

class _BienestarTabState extends State<_BienestarTab> {
  static const _objetivos = [
    'fitness_general',
    'perder_peso',
    'ganar_masa',
    'fuerza',
    'resistencia',
    'movilidad',
  ];
  static const _nivelesActividad = [
    'sedentario',
    'ligero',
    'moderado',
    'alto',
  ];
  static const _opcionesSexo = [
    'masculino',
    'femenino',
    'prefiero_no_decirlo',
  ];
  static const _equipamientoOpciones = [
    'peso_corporal',
    'mancuernas',
    'barra',
    'banda_elastica',
    'kettlebell',
    'polea',
    'maquina',
    'medicina_ball',
  ];

  final _repo = const BienestarRepository();

  String _fmt(String o) => o
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final p = widget.perfil;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        _sectionCard('Perfil físico', [
          _editRow(
              'Peso',
              _pesoStr(p.pesoKg),
              () => _editarNumero('Peso (kg)', p.pesoKg, 30, 250,
                  (v) => _guardar({'peso_kg': v, 'altura_cm': p.alturaCm}))),
          _editRow(
              'Altura',
              _alturaStr(p.alturaCm),
              () => _editarNumero('Altura (cm)', p.alturaCm, 120, 230,
                  (v) => _guardar({'altura_cm': v, 'peso_kg': p.pesoKg}))),
          _readRow(
              'IMC',
              p.imc > 0
                  ? '${p.imc.toStringAsFixed(1)} · ${p.imcCategoria}'
                  : '—'),
          _editRow('Sexo', p.sexo == 'prefiero_no_decirlo' ? '—' : _fmt(p.sexo),
              _editarSexo),
          _editRow('Edad', p.edad > 0 ? '${p.edad} años' : '—', _editarEdad),
          _editRow('Objetivo', _fmt(p.objetivoPrincipal), _editarObjetivo),
          _editRow(
              'Actividad',
              p.nivelActividad.isNotEmpty ? _fmt(p.nivelActividad) : '—',
              _editarNivelActividad),
          _editRow(
              'Días/semana',
              p.diasDisponiblesSemana > 0 ? '${p.diasDisponiblesSemana}' : '—',
              _editarDias),
          _editRow(
              'Min/sesión',
              p.minutosPorSesion > 0 ? '${p.minutosPorSesion}' : '—',
              _editarMinutos),
        ]),
        const SizedBox(height: 16),
        _sectionCard('Equipamiento', [
          if (p.equipamientoDisponible.isEmpty)
            const _RowText('Sin equipamiento configurado', isSub: true)
          else ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: p.equipamientoDisponible
                  .map((e) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF006E2D).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _fmt(e),
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF006E2D)),
                        ),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _editarEquipamiento,
              icon: const Icon(Icons.edit, size: 14),
              label: const Text('Configurar equipamiento',
                  style: TextStyle(fontSize: 12)),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        _sectionCard('Evolución de peso', [
          if (widget.historial.isEmpty)
            const _RowText('Sin registros aún', isSub: true)
          else
            ...widget.historial.take(5).map((h) => _readRow(
                  '${h.registradoEn.day}/${h.registradoEn.month}/${h.registradoEn.year}',
                  '${h.pesoKg} kg · IMC ${h.imc}',
                )),
        ]),
      ],
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFF1E293B).withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE2E8F0))),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _editRow(String label, String value, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF94A3B8)))),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              const Icon(Icons.edit, size: 13, color: Color(0xFF64748B)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _readRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)))),
          Text(value,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _pesoStr(double kg) => kg > 0 ? '${kg.toStringAsFixed(1)} kg' : '—';
  String _alturaStr(double cm) => cm > 0 ? '${cm.toStringAsFixed(0)} cm' : '—';

  Future<void> _guardar(Map<String, dynamic> data) async {
    await _repo.actualizarPerfilParcial(data);
    widget.onPerfilChanged?.call();
  }

  Future<void> _editarNumero(String title, double current, int min, int max,
      void Function(double) onSave) async {
    final ctrl = TextEditingController(
        text: current > 0 ? current.toStringAsFixed(1) : '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(hintText: '$min–$max'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Guardar')),
        ],
      ),
    );
    final val = double.tryParse(result ?? '');
    if (val != null && val >= min && val <= max && mounted) {
      onSave(val);
    }
  }

  void _editarSexo() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Sexo'),
        children: _opcionesSexo
            .map((s) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, s),
                  child: Row(children: [
                    Icon(
                        widget.perfil.sexo == s
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 18),
                    const SizedBox(width: 12),
                    Text(s == 'prefiero_no_decirlo'
                        ? 'Prefiero no decirlo'
                        : _fmt(s)),
                  ]),
                ))
            .toList(),
      ),
    );
    if (result != null && mounted) {
      await _guardar({'sexo': result});
    }
  }

  void _editarEdad() async {
    final ctrl = TextEditingController(
        text: widget.perfil.edad > 0 ? '${widget.perfil.edad}' : '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edad'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Años'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Guardar')),
        ],
      ),
    );
    final edad = int.tryParse(result ?? '');
    if (edad != null && edad > 0 && edad < 120 && mounted) {
      await _guardar({'edad': edad});
    }
  }

  void _editarObjetivo() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Objetivo deportivo'),
        children: _objetivos
            .map((o) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, o),
                  child: Row(children: [
                    Icon(
                        widget.perfil.objetivoPrincipal == o
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 18),
                    const SizedBox(width: 12),
                    Text(_fmt(o)),
                  ]),
                ))
            .toList(),
      ),
    );
    if (result != null && mounted) {
      await _guardar({'objetivo_principal': result});
    }
  }

  void _editarNivelActividad() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Nivel de actividad'),
        children: _nivelesActividad
            .map((n) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, n),
                  child: Row(children: [
                    Icon(
                        widget.perfil.nivelActividad == n
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 18),
                    const SizedBox(width: 12),
                    Text(_fmt(n)),
                  ]),
                ))
            .toList(),
      ),
    );
    if (result != null && mounted) {
      await _guardar({'nivel_actividad': result});
    }
  }

  void _editarDias() async {
    final ctrl = TextEditingController(
        text: widget.perfil.diasDisponiblesSemana > 0
            ? '${widget.perfil.diasDisponiblesSemana}'
            : '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Días por semana'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(hintText: '1–7'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Guardar')),
        ],
      ),
    );
    final val = int.tryParse(result ?? '');
    if (val != null && val >= 1 && val <= 7 && mounted) {
      await _guardar({'dias_disponibles_semana': val});
    }
  }

  void _editarMinutos() async {
    final ctrl = TextEditingController(
        text: widget.perfil.minutosPorSesion > 0
            ? '${widget.perfil.minutosPorSesion}'
            : '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Minutos por sesión'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(hintText: '10–180'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Guardar')),
        ],
      ),
    );
    final val = int.tryParse(result ?? '');
    if (val != null && val >= 10 && val <= 180 && mounted) {
      await _guardar({'minutos_por_sesion': val});
    }
  }

  void _editarEquipamiento() async {
    final seleccionados =
        Set<String>.from(widget.perfil.equipamientoDisponible);
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Equipamiento disponible'),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _equipamientoOpciones
                  .map((e) => FilterChip(
                        label:
                            Text(_fmt(e), style: const TextStyle(fontSize: 12)),
                        selected: seleccionados.contains(e),
                        onSelected: (v) => setD(() =>
                            v ? seleccionados.add(e) : seleccionados.remove(e)),
                      ))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _guardar({'equipamiento_disponible': seleccionados.toList()});
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// TAB 3: Ajustes
// =============================================================================
class _AjustesTab extends ConsumerWidget {
  const _AjustesTab({required this.usuario, required this.prefs});

  final UsuarioDb usuario;
  final PreferenciasNotificacionDb prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF1E293B).withValues(alpha: 0.6)),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.visibility_rounded,
                    color: Color(0xFF94A3B8)),
                title: const Text('Visibilidad del perfil',
                    style: TextStyle(fontSize: 13)),
                subtitle: const Text(
                    'Privado · Solo tus amigos pueden ver tus rutinas',
                    style: TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF64748B)),
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.notifications_rounded,
                    color: Color(0xFF94A3B8)),
                title: const Text('Notificaciones',
                    style: TextStyle(fontSize: 13)),
                subtitle: Text(
                    'Modo: ${prefs.modoActual} · ${prefs.limiteDiario}/día',
                    style: const TextStyle(fontSize: 11)),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF64748B)),
                onTap: () => context.push('/notificaciones'),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.dark_mode_rounded,
                    color: Color(0xFF94A3B8)),
                title:
                    const Text('Modo silencio', style: TextStyle(fontSize: 13)),
                subtitle: Text(
                  '${prefs.horaSilencioInicio ?? '—'} a ${prefs.horaSilencioFin ?? '—'}',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFF64748B)),
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _CarrerasCard(),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                await ref.read(authControllerProvider.notifier).logout();
                if (!context.mounted) return;
                context.go('/acceso');
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No se pudo cerrar la sesión.')),
                );
              }
            },
            icon: const Icon(Icons.logout_rounded,
                size: 18, color: Color(0xFFEF4444)),
            label: const Text('Cerrar sesión',
                style: TextStyle(color: Color(0xFFEF4444))),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              side: const BorderSide(color: Color(0xFF3B1C1C)),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Helpers
// =============================================================================

class _RowText extends StatelessWidget {
  const _RowText(this.text, {this.isSub = false});
  final String text;
  final bool isSub;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(text,
          style: TextStyle(
              fontSize: 13, color: isSub ? const Color(0xFF64748B) : null)),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  const _TabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
        color: Theme.of(context).scaffoldBackgroundColor, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _TabBarDelegate old) => old.tabBar != tabBar;
}

class _CarrerasCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carrerasAsync = ref.watch(usuarioCarrerasProvider);
    return carrerasAsync.when(
      data: (carreras) {
        if (carreras.isEmpty) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF1E293B).withValues(alpha: 0.6)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Carreras universitarias',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                  '${carreras.length} carrera${carreras.length != 1 ? 's' : ''} registrada${carreras.length != 1 ? 's' : ''}',
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/academico/configuracion'),
                  icon: const Icon(Icons.settings, size: 14),
                  label: const Text('Gestionar carreras',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
