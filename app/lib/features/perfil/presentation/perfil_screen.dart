import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../academico/application/usuario_carreras_provider.dart';
import '../../academico/application/catalogo_provider.dart';
import '../../bienestar/application/rutina_provider.dart';
import '../../bienestar/application/ejercicios_provider.dart';
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
  PreferenciasNotificacionDb? _cachedPrefs;

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
      case PerfilCambio.academico:
        ref.invalidate(perfilAcademicoProvider);
      case PerfilCambio.todo:
        ref.invalidate(perfilBienestarProvider);
        ref.invalidate(perfilUsuarioProvider);
        ref.invalidate(perfilBienestarCompletoProvider);
        ref.invalidate(perfilActividadProvider);
        ref.invalidate(perfilPreferenciasProvider);
        ref.invalidate(perfilAcademicoProvider);
    }
    ref.invalidate(dashboardProvider);
  }

  @override
  Widget build(BuildContext context) {
    final usuarioAsync = ref.watch(perfilUsuarioProvider);
    final preferenciasAsync = ref.watch(perfilPreferenciasProvider);

    if (usuarioAsync.hasValue) _cachedUsuario = usuarioAsync.value;
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

    return FeatureScaffold(
      title: '',
      child: DefaultTabController(
        length: 4,
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
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  indicatorSize: TabBarIndicatorSize.label,
                  tabs: const [
                    Tab(text: 'Estadísticas'),
                    Tab(text: 'Bienestar'),
                    Tab(text: 'Académico'),
                    Tab(text: 'Ajustes'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            children: [
              const _EstadisticasTab(),
              _BienestarTab(
                onPerfilChanged: () =>
                    _onPerfilActualizado(cambio: PerfilCambio.bienestar),
              ),
              _AcademicoTab(
                onPerfilChanged: () =>
                    _onPerfilActualizado(cambio: PerfilCambio.academico),
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
// Widgets compartidos entre tabs
// =============================================================================
Widget _buildSectionCard(
    BuildContext context, String title, List<Widget> children) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF1E293B).withValues(alpha: 0.6)),
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

Widget _buildEditRow(String label, String value, VoidCallback onTap,
    {String? tooltip}) {
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
                child: Row(
              children: [
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF94A3B8))),
                ),
                if (tooltip != null) ...[
                  const SizedBox(width: 4),
                  Tooltip(
                    message: tooltip,
                    child: const Icon(Icons.help_outline_rounded,
                        size: 14, color: Color(0xFF64748B)),
                  ),
                ],
              ],
            )),
            Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            const Icon(Icons.edit, size: 13, color: Color(0xFF64748B)),
          ],
        ),
      ),
    ),
  );
}

Widget _buildReadRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Expanded(
            child: Text(label,
                style:
                    const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)))),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}

class _RowText extends StatelessWidget {
  const _RowText(this.text, {this.isSub = false});

  final String text;
  final bool isSub;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: TextStyle(
            fontSize: isSub ? 12 : 13,
            color: isSub ? const Color(0xFF64748B) : const Color(0xFFE2E8F0)));
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
    const repo = BienestarRepository();
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
class _EstadisticasTab extends ConsumerWidget {
  const _EstadisticasTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuarioAsync = ref.watch(perfilUsuarioProvider);
    final actividadAsync = ref.watch(perfilActividadProvider);
    final usuario = usuarioAsync.valueOrNull?.usuario;
    final actividad = actividadAsync.valueOrNull ??
        const PerfilActividad(sesiones: 0, logros: 0, caloriasAcumuladas: 0);

    if (usuario == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

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
                '${actividad.sesiones}',
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
                '${actividad.logros}',
                'Retos',
                color: const Color(0xFFE8A838),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                '${actividad.caloriasAcumuladas}',
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
class _BienestarTab extends ConsumerStatefulWidget {
  const _BienestarTab({this.onPerfilChanged});

  final VoidCallback? onPerfilChanged;

  @override
  ConsumerState<_BienestarTab> createState() => _BienestarTabState();
}

class _BienestarTabState extends ConsumerState<_BienestarTab> {
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
  final _repo = const BienestarRepository();

  PerfilBienestarDb? _cachedPerfil;

  String _fmt(String o) => o
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final bienestarAsync = ref.watch(perfilBienestarCompletoProvider);
    if (bienestarAsync.hasValue && bienestarAsync.value != null) {
      _cachedPerfil = bienestarAsync.value!.perfil;
    }
    final p = _cachedPerfil ??
        PerfilBienestarDb(
          id: '',
          usuarioId: '',
          edad: 0,
          sexo: 'prefiero_no_decirlo',
          pesoKg: 0,
          alturaCm: 0,
          imc: 0,
          nivelActividad: 'sedentario',
          objetivoPrincipal: 'fitness_general',
          objetivos: const [],
          equipamientoDisponible: const [],
          diasDisponiblesSemana: 0,
          minutosPorSesion: 0,
          onboardingCompletado: false,
          creadoEn: DateTime.now(),
          actualizadoEn: DateTime.now(),
        );
    final historial = bienestarAsync.valueOrNull?.historial ?? [];
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
              p.pesoKg > 0 && p.alturaCm > 0
                  ? '${(p.pesoKg / ((p.alturaCm / 100) * (p.alturaCm / 100))).toStringAsFixed(1)} · ${_imcCategoria(p.pesoKg / ((p.alturaCm / 100) * (p.alturaCm / 100)))}'
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
          if (historial.isEmpty)
            const _RowText('Sin registros aún', isSub: true)
          else
            ...historial.take(5).map((h) => _readRow(
                  '${h.registradoEn.day}/${h.registradoEn.month}/${h.registradoEn.year}',
                  '${h.pesoKg} kg · IMC ${h.imc}',
                )),
        ]),
      ],
    );
  }

  Widget _sectionCard(String title, List<Widget> children) {
    return _buildSectionCard(context, title, children);
  }

  Widget _editRow(String label, String value, VoidCallback onTap) {
    return _buildEditRow(label, value, onTap);
  }

  Widget _readRow(String label, String value) {
    return _buildReadRow(label, value);
  }

  String _pesoStr(double kg) => kg > 0 ? '${kg.toStringAsFixed(1)} kg' : '—';
  String _alturaStr(double cm) => cm > 0 ? '${cm.toStringAsFixed(0)} cm' : '—';
  String _imcCategoria(double imc) {
    if (imc < 18.5) return 'Bajo peso';
    if (imc < 25) return 'Normal';
    if (imc < 30) return 'Sobrepeso';
    return 'Obesidad';
  }

  Future<void> _guardar(Map<String, dynamic> data) async {
    await _repo.actualizarPerfilParcial(data);
    widget.onPerfilChanged?.call();
    if (mounted) setState(() {});
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
                        _cachedPerfil!.sexo == s
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
        text: _cachedPerfil!.edad > 0 ? '${_cachedPerfil!.edad}' : '');
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
        children: finalidadesEstandar
            .map((f) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, f),
                  child: Row(children: [
                    Icon(
                        _cachedPerfil!.objetivoPrincipal == f
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 18),
                    const SizedBox(width: 12),
                    Icon(iconoFinalidad(f), size: 18),
                    const SizedBox(width: 8),
                    Text(f),
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
                        _cachedPerfil!.nivelActividad == n
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
        text: _cachedPerfil!.diasDisponiblesSemana > 0
            ? '${_cachedPerfil!.diasDisponiblesSemana}'
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
        text: _cachedPerfil!.minutosPorSesion > 0
            ? '${_cachedPerfil!.minutosPorSesion}'
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
        Set<String>.from(_cachedPerfil!.equipamientoDisponible);

    final client = Supabase.instance.client;
    final data =
        await client.from('equipamientos').select('nombre').order('nombre');
    final equipDB = (data as List).map((e) => e['nombre'] as String).toList();

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          var query = '';
          return AlertDialog(
            title: const Text('Equipamiento disponible'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Buscar equipamiento...',
                      prefixIcon: Icon(Icons.search, size: 20),
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (v) => setD(() => query = v.toLowerCase()),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: equipDB
                            .where((e) =>
                                query.isEmpty ||
                                e.toLowerCase().contains(query))
                            .map((e) => FilterChip(
                                  label: Text(_fmt(e),
                                      style: const TextStyle(fontSize: 12)),
                                  selected: seleccionados.contains(e),
                                  onSelected: (v) => setD(() => v
                                      ? seleccionados.add(e)
                                      : seleccionados.remove(e)),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ],
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
                child: Text('Guardar (${seleccionados.length})'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// TAB 3: Académico
// =============================================================================
class _AcademicoTab extends ConsumerStatefulWidget {
  const _AcademicoTab({this.onPerfilChanged});

  final VoidCallback? onPerfilChanged;

  @override
  ConsumerState<_AcademicoTab> createState() => _AcademicoTabState();
}

class _AcademicoTabState extends ConsumerState<_AcademicoTab> {
  static const _modalidades = ['presencial', 'hibrida', 'virtual'];

  String? _selectedUniversidadId;

  PerfilAcademicoDb _empty() => PerfilAcademicoDb(
        id: '',
        usuarioId: '',
        semestreActual: 1,
        modalidad: 'presencial',
        creditosSemestreActual: 20,
        horasObjetivoEstudioSemana: 14,
        creadoEn: DateTime.now(),
        actualizadoEn: DateTime.now(),
      );

  Future<void> _guardar(Map<String, dynamic> data) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    final existing = await client
        .from('perfil_academico_usuario')
        .select('id')
        .eq('usuario_id', user.id)
        .maybeSingle();

    if (existing != null) {
      await client
          .from('perfil_academico_usuario')
          .update(data)
          .eq('usuario_id', user.id);
    } else {
      await client.from('perfil_academico_usuario').insert({
        'usuario_id': user.id,
        ...data,
      });
    }
    if (mounted) ref.invalidate(perfilAcademicoProvider);
  }

  Future<void> _editarNumero(
      String label, int current, int min, int max, Function(int) onSave) async {
    final ctrl = TextEditingController(text: current.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (ok == true) {
      final v = int.tryParse(ctrl.text.trim()) ?? current;
      onSave(v.clamp(min, max));
    }
  }

  Future<void> _editarNumeroDecimal(String label, double? current, double min,
      double max, Function(double) onSave) async {
    final ctrl = TextEditingController(text: current?.toStringAsFixed(1) ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (ok == true) {
      final v = double.tryParse(ctrl.text.trim()) ?? (current ?? 0);
      onSave(v.clamp(min, max));
    }
  }

  Future<void> _seleccionarUniversidad(CatalogoUniversidadDb? current) async {
    final unisAsync = ref.read(universidadesProvider);
    final unis = unisAsync.valueOrNull ?? [];
    if (unis.isEmpty) return;

    final selected = await showDialog<CatalogoUniversidadDb>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Selecciona tu universidad'),
        children: [
          RadioGroup<CatalogoUniversidadDb>(
            groupValue: current,
            onChanged: (v) => Navigator.pop(ctx, v),
            child: Column(
              children: unis
                  .map((u) => RadioListTile<CatalogoUniversidadDb>(
                        title: Text(u.nombre,
                            style: const TextStyle(fontSize: 13)),
                        value: u,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
    if (selected != null) {
      _selectedUniversidadId = selected.id;
      await _guardar({
        'universidad': selected.nombre,
        'carrera': null,
      });
    }
  }

  Future<void> _seleccionarCarrera(String? current) async {
    if (_selectedUniversidadId == null) return;
    final carrerasAsync =
        ref.read(carrerasPorUniversidadProvider(_selectedUniversidadId!));
    final carreras = carrerasAsync.valueOrNull ?? [];
    if (carreras.isEmpty) return;

    CatalogoCarreraDb? selected;
    if (current != null) {
      for (final c in carreras) {
        if (c.nombre == current) selected = c;
      }
    }

    final result = await showDialog<CatalogoCarreraDb>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Selecciona tu carrera'),
        children: [
          RadioGroup<CatalogoCarreraDb>(
            groupValue: selected,
            onChanged: (v) => Navigator.pop(ctx, v),
            child: Column(
              children: carreras
                  .map((c) => RadioListTile<CatalogoCarreraDb>(
                        title: Text(c.nombre,
                            style: const TextStyle(fontSize: 13)),
                        value: c,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
    if (result != null) {
      final subjectsAsync =
          ref.read(catalogoAsignaturasPorCarreraProvider(result.id));
      final subjects = subjectsAsync.valueOrNull ?? [];
      final totalCreditos =
          subjects.fold<double>(0, (sum, s) => sum + (s.creditos ?? 0));
      final horasCalc = (totalCreditos * 2).round().clamp(0, 80);

      await _guardar({
        'carrera': result.nombre,
        'creditos_semestre_actual':
            totalCreditos > 0 ? totalCreditos.round() : 20,
        'horas_objetivo_estudio_semana': horasCalc > 0 ? horasCalc : 14,
        'semestre_actual': 1,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(perfilAcademicoProvider).valueOrNull ?? _empty();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        _buildUniversitySection(p),
        const SizedBox(height: 16),
        _buildCareerSection(p),
        const SizedBox(height: 16),
        _buildSectionCard(context, 'Datos del semestre', [
          _buildEditRow(
              'Semestre',
              '${p.semestreActual}°',
              () => _editarNumero('Semestre actual', p.semestreActual, 1, 20,
                  (v) => _guardar({'semestre_actual': v}))),
          _buildEditRow(
              'Modalidad',
              p.modalidad[0].toUpperCase() + p.modalidad.substring(1),
              () => _editarModalidad(p.modalidad)),
          _buildEditRow(
              'Créditos',
              '${p.creditosSemestreActual}',
              () => _editarNumero(
                  'Créditos del semestre',
                  p.creditosSemestreActual,
                  1,
                  60,
                  (v) => _guardar({'creditos_semestre_actual': v}))),
          _buildEditRow(
              'Horas estudio / sem',
              '${p.horasObjetivoEstudioSemana}h',
              () => _editarNumero(
                  'Horas objetivo de estudio por semana',
                  p.horasObjetivoEstudioSemana,
                  0,
                  80,
                  (v) => _guardar({'horas_objetivo_estudio_semana': v}))),
          _buildEditRow(
              'Promedio objetivo',
              p.promedioObjetivo != null
                  ? p.promedioObjetivo!.toStringAsFixed(1)
                  : '—',
              () => _editarNumeroDecimal(
                  'Promedio objetivo (0-5)',
                  p.promedioObjetivo,
                  0,
                  5,
                  (v) => _guardar({'promedio_objetivo': v})),
              tooltip:
                  'Calificación promedio que deseas mantener. Escala 0-5. Ej: 4.0 para un buen promedio.'),
        ]),
      ],
    );
  }

  Widget _buildUniversitySection(PerfilAcademicoDb p) {
    final unisAsync = ref.watch(universidadesProvider);
    final unis = unisAsync.valueOrNull ?? [];

    CatalogoUniversidadDb? currentUni;
    for (final u in unis) {
      if (u.nombre == p.universidad) {
        currentUni = u;
        _selectedUniversidadId = u.id;
        break;
      }
    }

    return _buildSectionCard(context, 'Universidad', [
      const _RowText(
          'Selecciona tu universidad del catálogo para acceder a las carreras disponibles.',
          isSub: true),
      const SizedBox(height: 10),
      if (unisAsync.isLoading)
        const Center(child: CircularProgressIndicator(strokeWidth: 2))
      else
        _buildDropdownTile(
          icon: Icons.school_rounded,
          label: 'Universidad',
          value: p.universidad ?? 'Seleccionar...',
          onTap: () => _seleccionarUniversidad(currentUni),
          onClear: p.universidad != null
              ? () async {
                  _selectedUniversidadId = null;
                  await _guardar({'universidad': null, 'carrera': null});
                }
              : null,
        ),
    ]);
  }

  Widget _buildCareerSection(PerfilAcademicoDb p) {
    final carrerasAsync = _selectedUniversidadId != null
        ? ref.watch(carrerasPorUniversidadProvider(_selectedUniversidadId!))
        : null;
    final userCareersAsync = ref.watch(usuarioCarrerasProvider);
    final userCareerIds =
        (userCareersAsync.valueOrNull ?? []).map((uc) => uc.carreraId).toSet();

    final carreras = (carrerasAsync?.valueOrNull ?? [])
        .where((c) => !userCareerIds.contains(c.id))
        .toList();

    return _buildSectionCard(context, 'Carrera', [
      const _RowText(
          'Selecciona primero una universidad. Las carreras disponibles dependen de la universidad elegida.',
          isSub: true),
      const SizedBox(height: 10),
      if (carrerasAsync != null && carrerasAsync.isLoading)
        const Center(child: CircularProgressIndicator(strokeWidth: 2))
      else
        _buildDropdownTile(
          icon: Icons.menu_book_rounded,
          label: 'Carrera',
          value: p.carrera ?? 'Seleccionar...',
          onTap: () => _seleccionarCarrera(p.carrera),
          onClear: p.carrera != null ? () => _guardar({'carrera': null}) : null,
        ),
      if (carreras.isNotEmpty) ...[
        const SizedBox(height: 8),
        _RowText(
            '${carreras.length} carrera(s) disponible(s) en esta universidad',
            isSub: true),
      ],
    ]);
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    final hasValue = value != 'Seleccionar...';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: Theme.of(context)
                  .colorScheme
                  .outlineVariant
                  .withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            if (hasValue && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded,
                      size: 18, color: Color(0xFF64748B)),
                ),
              )
            else
              const Icon(Icons.arrow_drop_down_rounded,
                  color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  Future<void> _editarModalidad(String current) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Modalidad'),
        children: [
          RadioGroup<String>(
            groupValue: current,
            onChanged: (v) => Navigator.pop(ctx, v),
            child: Column(
              children: _modalidades
                  .map((m) => RadioListTile<String>(
                        title: Text(m[0].toUpperCase() + m.substring(1)),
                        value: m,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
    if (selected != null && selected != current) {
      await _guardar({'modalidad': selected});
    }
  }
}

// =============================================================================
// TAB 4: Ajustes
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
