import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../academico/application/catalogo_provider.dart';
import '../../bienestar/application/rutina_provider.dart';
import '../../bienestar/application/ejercicios_provider.dart';
import '../../../core/design_system/sv_colors.dart';
import '../../dashboard/application/dashboard_provider.dart';
import '../../insignias/application/insignias_provider.dart';
import '../../admin/application/admin_provider.dart';
import '../application/perfil_provider.dart';

// =============================================================================
// PerfilScreen — Pantalla principal de perfil rediseñada
// =============================================================================
class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  int _selectedSection = 0;
  PerfilUsuario? _cachedUsuario;
  PreferenciasNotificacionDb? _cachedPrefs;

  static const _sectionLabels = [
    'Estadísticas',
    'Bienestar',
    'Académico',
    'Ajustes'
  ];
  static const _sectionIcons = [
    Icons.bar_chart_rounded,
    Icons.fitness_center_rounded,
    Icons.school_rounded,
    Icons.settings_rounded,
  ];

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

    final actividad = ref.watch(perfilActividadProvider).valueOrNull ??
        const PerfilActividad(sesiones: 0, logros: 0, caloriasAcumuladas: 0);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return FeatureScaffold(
      title: 'Perfil',
      child: Column(
        children: [
          // ── Header fijo ──
          _ProfileHeader(
            usuario: usuario,
            perfil: perfil,
            actividad: actividad,
            onNombreChanged: () =>
                _onPerfilActualizado(cambio: PerfilCambio.nombre),
          ),

          // ── Selector de sección (ChoiceChips) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _sectionLabels.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final selected = _selectedSection == index;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _sectionIcons[index],
                          size: 16,
                          color: selected
                              ? cs.onSecondaryContainer
                              : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(_sectionLabels[index]),
                      ],
                    ),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedSection = index),
                    labelStyle: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    selectedColor: cs.secondaryContainer,
                    backgroundColor: cs.surfaceContainerLow,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    visualDensity: VisualDensity.compact,
                  );
                },
              ),
            ),
          ),

          // ── Contenido de sección ──
          Expanded(
            child: IndexedStack(
              index: _selectedSection,
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
        ],
      ),
    );
  }
}

// =============================================================================
// _ProfileHeader — Cabecera moderna con gradiente atlético
// =============================================================================
class _ProfileHeader extends StatefulWidget {
  const _ProfileHeader({
    required this.usuario,
    required this.perfil,
    required this.actividad,
    this.onNombreChanged,
  });

  final UsuarioDb usuario;
  final PerfilBienestarDb perfil;
  final PerfilActividad actividad;
  final VoidCallback? onNombreChanged;

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final nombre = widget.usuario.nombreCompleto;
    final initial =
        nombre.isNotEmpty && nombre != '—' ? nombre[0].toUpperCase() : '?';
    final tieneAvatar = widget.usuario.urlAvatar != null &&
        widget.usuario.urlAvatar!.isNotEmpty;
    final act = widget.actividad;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary,
            cs.primaryContainer,
            cs.primary.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Column(
        children: [
          // ── Avatar + Nombre ──
          Row(
            children: [
              // Avatar con anillo de acento
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [cs.secondaryContainer, cs.secondary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cs.secondaryContainer.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(2.5),
                child: ClipOval(
                  child: Container(
                    color: cs.primaryContainer,
                    child: tieneAvatar
                        ? Image.network(
                            widget.usuario.urlAvatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _avatarInitial(initial),
                          )
                        : _avatarInitial(initial),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            nombre,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: cs.onPrimary,
                              fontWeight: FontWeight.w700,
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
                              color: cs.onPrimary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.edit_outlined,
                                size: 14,
                                color: cs.onPrimary.withValues(alpha: 0.7)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.usuario.email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onPrimary.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Stats: sesiones, XP, calorías, retos ──
          Row(
            children: [
              Expanded(child: _statItem(context, '${act.sesiones}', 'Sesiones', Icons.fitness_center_rounded)),
              _statDivider(context),
              Expanded(child: _statItem(context, _formatNum(widget.usuario.xpTotal), 'XP', Icons.stars_rounded)),
              _statDivider(context),
              Expanded(child: _statItem(context, _formatNum(act.caloriasAcumuladas), 'Calorías', Icons.local_fire_department_rounded)),
              _statDivider(context),
              Expanded(child: _statItem(context, '${act.logros}', 'Retos', Icons.emoji_events_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avatarInitial(String initial) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.primaryContainer,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: cs.secondaryContainer,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _statItem(BuildContext context, String value, String label, IconData icon) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: cs.onPrimary.withValues(alpha: 0.7)),
        const SizedBox(height: 4),
        Text(value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: cs.onPrimary,
              fontWeight: FontWeight.w800,
            )),
        const SizedBox(height: 1),
        Text(label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onPrimary.withValues(alpha: 0.6),
            )),
      ],
    );
  }

  Widget _statDivider(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 1,
      height: 40,
      color: cs.onPrimary.withValues(alpha: 0.15),
    );
  }

  String _formatNum(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  Future<void> _editarNombre(BuildContext context) async {
    final repo =
        ProviderScope.containerOf(context).read(bienestarRepositoryProvider);
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
// _EstadisticasTab — Insignias
// =============================================================================
class _EstadisticasTab extends ConsumerWidget {
  const _EstadisticasTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insigniasAsync = ref.watch(insigniasUsuarioProvider);
    final insignias = insigniasAsync.valueOrNull ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _buildInsigniasPreview(context, ref, insignias),
      ],
    );
  }

  Widget _buildInsigniasPreview(
      BuildContext context, WidgetRef ref, List<dynamic> insignias) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final countAsync = ref.watch(insigniasCountProvider);
    final total = countAsync.valueOrNull ?? 0;
    final preview = insignias.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events_rounded,
                size: 18, color: SVColors.accent),
            const SizedBox(width: 8),
            Text('Insignias',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                )),
            const Spacer(),
            Text('$total/15',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: SVColors.accent,
                )),
          ],
        ),
        const SizedBox(height: 12),

        if (preview.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Completa actividades para\ndesbloquear insignias',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: SVColors.onSurfaceMuted,
                ),
              ),
            ),
          )
        else
          Row(
            children: preview.map((ins) {
              final color = Color(ins.colorRareza);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.1),
                          border:
                              Border.all(color: color.withValues(alpha: 0.25)),
                        ),
                        child: Center(
                            child: Text(ins.icono,
                                style: const TextStyle(fontSize: 22))),
                      ),
                      const SizedBox(height: 6),
                      Text(ins.nombre,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/insignias'),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Ver todas'),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Sección de título consistente
// =============================================================================
Widget _sectionTitle(BuildContext context, String title, {Widget? trailing}) {
  final theme = Theme.of(context);
  return Row(
    children: [
      Text(title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          )),
      const Spacer(),
      if (trailing != null) trailing,
    ],
  );
}

// =============================================================================
// Fila editable moderna (basada en ListTile compacto)
// =============================================================================
Widget _editTile(
  BuildContext context, {
  required String label,
  required String value,
  String? subtitle,
  IconData? leadingIcon,
  required VoidCallback onTap,
}) {
  final theme = Theme.of(context);
  return ListTile(
    contentPadding: EdgeInsets.zero,
    visualDensity: VisualDensity.compact,
    leading: leadingIcon != null
        ? Icon(leadingIcon, size: 20, color: theme.colorScheme.primary)
        : null,
    title: Text(label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        )),
    subtitle: subtitle != null
        ? Text(subtitle, style: theme.textTheme.bodySmall)
        : null,
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            )),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right,
            size: 18, color: theme.colorScheme.onSurfaceVariant),
      ],
    ),
    onTap: onTap,
  );
}

// =============================================================================
// Fila de solo lectura
// =============================================================================
Widget _readTile(
  BuildContext context, {
  required String label,
  required String value,
  IconData? leadingIcon,
}) {
  final theme = Theme.of(context);
  return ListTile(
    contentPadding: EdgeInsets.zero,
    visualDensity: VisualDensity.compact,
    leading: leadingIcon != null
        ? Icon(leadingIcon, size: 20, color: theme.colorScheme.primary)
        : null,
    title: Text(label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        )),
    trailing: Text(value,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurfaceVariant,
        )),
  );
}

// =============================================================================
// _BienestarTab
// =============================================================================
class _BienestarTab extends ConsumerStatefulWidget {
  const _BienestarTab({this.onPerfilChanged});
  final VoidCallback? onPerfilChanged;
  @override
  ConsumerState<_BienestarTab> createState() => _BienestarTabState();
}

class _BienestarTabState extends ConsumerState<_BienestarTab> {
  static const _nivelesActividad = ['sedentario', 'ligero', 'moderado', 'alto'];
  static const _opcionesSexo = [
    'masculino',
    'femenino',
    'prefiero_no_decirlo',
  ];

  BienestarRepository get _repo => ref.read(bienestarRepositoryProvider);
  PerfilBienestarDb? _cachedPerfil;

  String _fmt(String o) => o
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // ── Perfil físico ──
        _sectionTitle(context, 'Perfil físico'),
        const SizedBox(height: 8),
        _editTile(context,
            label: 'Peso',
            value: _pesoStr(p.pesoKg),
            leadingIcon: Icons.monitor_weight_outlined,
            onTap: () => _editarNumero('Peso (kg)', p.pesoKg, 30, 250,
                (v) => _guardar({'peso_kg': v, 'altura_cm': p.alturaCm}))),
        _divider(context),
        _editTile(context,
            label: 'Altura',
            value: _alturaStr(p.alturaCm),
            leadingIcon: Icons.height,
            onTap: () => _editarNumero('Altura (cm)', p.alturaCm, 120, 230,
                (v) => _guardar({'altura_cm': v, 'peso_kg': p.pesoKg}))),
        _divider(context),
        _readTile(context,
            label: 'IMC',
            value: p.pesoKg > 0 && p.alturaCm > 0
                ? '${(p.pesoKg / ((p.alturaCm / 100) * (p.alturaCm / 100))).toStringAsFixed(1)} · ${_imcCategoria(p.pesoKg / ((p.alturaCm / 100) * (p.alturaCm / 100)))}'
                : '—',
            leadingIcon: Icons.calculate_outlined),
        _divider(context),
        _editTile(context,
            label: 'Sexo',
            value: p.sexo == 'prefiero_no_decirlo' ? '—' : _fmt(p.sexo),
            leadingIcon: Icons.person_outline,
            onTap: _editarSexo),
        _divider(context),
        _editTile(context,
            label: 'Edad',
            value: p.edad > 0 ? '${p.edad} años' : '—',
            leadingIcon: Icons.cake_outlined,
            onTap: _editarEdad),
        _divider(context),
        _editTile(context,
            label: 'Objetivo',
            value: _fmt(p.objetivoPrincipal),
            leadingIcon: Icons.flag_outlined,
            onTap: _editarObjetivo),
        _divider(context),
        _editTile(context,
            label: 'Actividad',
            value: p.nivelActividad.isNotEmpty ? _fmt(p.nivelActividad) : '—',
            leadingIcon: Icons.directions_run,
            onTap: _editarNivelActividad),
        _divider(context),
        _editTile(context,
            label: 'Días / semana',
            value: p.diasDisponiblesSemana > 0
                ? '${p.diasDisponiblesSemana}'
                : '—',
            leadingIcon: Icons.calendar_today,
            onTap: _editarDias),
        _divider(context),
        _editTile(context,
            label: 'Min / sesión',
            value: p.minutosPorSesion > 0 ? '${p.minutosPorSesion}' : '—',
            leadingIcon: Icons.timer_outlined,
            onTap: _editarMinutos),

        // ── Equipamiento ──
        const SizedBox(height: 24),
        _sectionTitle(context, 'Equipamiento'),
        const SizedBox(height: 8),
        if (p.equipamientoDisponible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Sin equipamiento configurado',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: SVColors.onSurfaceMuted,
                )),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: p.equipamientoDisponible
                  .map((e) => Chip(
                        label: Text(_fmt(e),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            )),
                        backgroundColor: theme.colorScheme.secondaryContainer
                            .withValues(alpha: 0.12),
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ))
                  .toList(),
            ),
          ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _editarEquipamiento,
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Configurar equipamiento'),
          ),
        ),

        // ── Evolución de peso ──
        const SizedBox(height: 24),
        _sectionTitle(context, 'Evolución de peso'),
        const SizedBox(height: 8),
        if (historial.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Sin registros aún',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: SVColors.onSurfaceMuted,
                )),
          )
        else
          ...historial.take(5).map((h) => _readTile(context,
              label:
                  '${h.registradoEn.day}/${h.registradoEn.month}/${h.registradoEn.year}',
              value: '${h.pesoKg} kg · IMC ${h.imc}')),
      ],
    );
  }

  Widget _divider(BuildContext context) => Divider(
      height: 1,
      indent: 48,
      color:
          Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3));

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
// _AcademicoTab
// =============================================================================
class _AcademicoTab extends ConsumerStatefulWidget {
  const _AcademicoTab({this.onPerfilChanged});
  final VoidCallback? onPerfilChanged;
  @override
  ConsumerState<_AcademicoTab> createState() => _AcademicoTabState();
}

class _AcademicoTabState extends ConsumerState<_AcademicoTab> {
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

  Future<void> _seleccionarUniversidad(UniversidadDb? current) async {
    final unisAsync = ref.read(universidadesProvider);
    final unis = unisAsync.valueOrNull ?? [];
    if (unis.isEmpty) return;

    final selected = await showDialog<UniversidadDb>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Selecciona tu universidad'),
        children: [
          RadioGroup<UniversidadDb>(
            groupValue: current,
            onChanged: (v) => Navigator.pop(ctx, v),
            child: Column(
              children: unis
                  .map((u) => RadioListTile<UniversidadDb>(
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

    CarreraDb? selected;
    if (current != null) {
      for (final c in carreras) {
        if (c.nombre == current) selected = c;
      }
    }

    final result = await showDialog<CarreraDb>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Selecciona tu carrera'),
        children: [
          RadioGroup<CarreraDb>(
            groupValue: selected,
            onChanged: (v) => Navigator.pop(ctx, v),
            child: Column(
              children: carreras
                  .map((c) => RadioListTile<CarreraDb>(
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

  Future<void> _seleccionarCurso(int current, int maxCurso) async {
    final options = [for (var i = 1; i <= maxCurso; i++) i];
    final p = ref.read(perfilAcademicoProvider).valueOrNull ?? _empty();
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Selecciona tu curso'),
        children: [
          RadioGroup<int>(
            groupValue: current,
            onChanged: (v) => Navigator.pop(ctx, v),
            child: Column(
              children: options
                  .map((c) => RadioListTile<int>(
                        title: Text('Curso $c'),
                        value: c,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
    if (selected != null && selected != current) {
      final novoSemestreActual = ((selected - 1) * 2) + p.semestreEnCurso;
      await _guardar({'semestre_actual': novoSemestreActual});
    }
  }

  Future<void> _seleccionarSemestre(int current) async {
    final p = ref.read(perfilAcademicoProvider).valueOrNull ?? _empty();
    final selected = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Selecciona el semestre'),
        children: [
          RadioGroup<int>(
            groupValue: current,
            onChanged: (v) => Navigator.pop(ctx, v),
            child: Column(
              children: [1, 2]
                  .map((s) => RadioListTile<int>(
                        title: Text('$s° Semestre'),
                        value: s,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
    if (selected != null && selected != current) {
      final novoSemestreActual = ((p.cursoActual - 1) * 2) + selected;
      await _guardar({'semestre_actual': novoSemestreActual});
    }
  }

  Widget _buildSinSemestreRow(BuildContext context, AsignaturaCatalogoDb s,
      List<AsignaturaUsuarioSemestreDb> mapeos) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final mapeo = mapeos.where((m) => m.asignaturaId == s.id).firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            child: Icon(Icons.menu_book_outlined,
                size: 16, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.nombre,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    )),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (s.creditos != null)
                      _badge(context, '${s.creditos!.round()} ECTS', cs.primary),
                    const SizedBox(width: 6),
                    if (mapeo != null)
                      _badge(context,
                          'Curso ${mapeo.curso} · ${mapeo.semestre}° Sem',
                          cs.secondaryContainer)
                    else
                      _badge(context, 'Sin asignar', cs.outlineVariant),
                  ],
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              if (mapeo != null) {
                _quitarDeSemestre(mapeo);
              } else {
                _asignarSinSemestre(s);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: mapeo != null
                    ? cs.error.withValues(alpha: 0.1)
                    : cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                mapeo != null ? Icons.close : Icons.add,
                size: 16,
                color: mapeo != null ? cs.error : cs.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _asignarSinSemestre(AsignaturaCatalogoDb s) async {
    final p = ref.read(perfilAcademicoProvider).valueOrNull ?? _empty();
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;
    await client.from('asignaturas_usuario_semestre').upsert({
      'usuario_id': user.id,
      'asignatura_id': s.id,
      'curso': p.cursoActual,
      'semestre': p.semestreEnCurso,
    }, onConflict: 'usuario_id, asignatura_id');
    if (mounted) ref.invalidate(asignaturasUsuarioSemestreProvider);
  }

  Future<void> _quitarDeSemestre(AsignaturaUsuarioSemestreDb m) async {
    final client = Supabase.instance.client;
    await client.from('asignaturas_usuario_semestre').delete().eq('id', m.id);
    if (mounted) ref.invalidate(asignaturasUsuarioSemestreProvider);
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(perfilAcademicoProvider).valueOrNull ?? _empty();
    final carreraDataAsync = ref.watch(carreraConAsignaturasProvider);
    final carreraData = carreraDataAsync.valueOrNull ?? [];
    final sinSemestreAsync = ref.watch(asignaturasSinSemestreProvider);
    final sinSemestre = sinSemestreAsync.valueOrNull ?? [];
    final mapeosAsync = ref.watch(asignaturasUsuarioSemestreProvider);
    final mapeos = mapeosAsync.valueOrNull ?? [];

    // Calcular creditos y horas del curso+semestre actual desde el catálogo
    int creditosCalculados = 0;
    int horasCalculadas = 0;
    int maxCurso = 0;
    if (carreraData.isNotEmpty) {
      for (final entry in carreraData) {
        for (final s in entry.subjects) {
          if (s.curso == p.cursoActual && s.semestre == p.semestreEnCurso) {
            creditosCalculados += (s.creditos ?? 0).round();
            horasCalculadas += (s.horas ?? 0);
          }
          if (s.curso != null && s.curso! > maxCurso) maxCurso = s.curso!;
        }
      }
    }
    // Incluir asignaturas mapeadas por el usuario (semestre 0)
    if (mapeos.isNotEmpty) {
      final mappedIds = mapeos
          .where((m) => m.curso == p.cursoActual && m.semestre == p.semestreEnCurso)
          .map((m) => m.asignaturaId)
          .toSet();
      if (mappedIds.isNotEmpty) {
        for (final entry in carreraData) {
          for (final s in entry.subjects) {
            if (mappedIds.contains(s.id)) {
              creditosCalculados += (s.creditos ?? 0).round();
              horasCalculadas += (s.horas ?? 0);
            }
          }
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // ── Header: Universidad + Carrera ──
        _buildInstitucionCard(context, p),

        const SizedBox(height: 20),

        // ── Semestre actual ──
        _sectionTitle(context, 'Semestre actual'),
        const SizedBox(height: 4),
        Text(
          'Curso ${p.cursoActual} · ${p.semestreEnCurso}° Semestre',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),

        // ── Asignaturas (plan de estudios) ──
        if (carreraData.isNotEmpty) ...[
          const SizedBox(height: 16),
          _sectionTitle(context, 'Plan de estudios'),
          const SizedBox(height: 12),
          _buildCursoCards(context, carreraData, mapeos),
        ],

        // ── Asignaturas transversales (semestre 0) — colapsable ──
        if (sinSemestre.isNotEmpty) ...[
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ExpansionTile(
              title: Row(
                children: [
                  Icon(Icons.menu_book_outlined, size: 18,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Text('Asignaturas transversales',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${sinSemestre.length}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ],
              ),
              childrenPadding: const EdgeInsets.only(left: 16, right: 4, bottom: 8),
              initiallyExpanded: false,
              collapsedShape: const Border(),
              shape: const Border(),
              children: sinSemestre
                  .map((s) => _buildSinSemestreRow(context, s, mapeos))
                  .toList(),
            ),
          ),
        ],

        const SizedBox(height: 20),
        _editTile(context,
            label: 'Curso',
            value: '${p.cursoActual}',
            leadingIcon: Icons.layers_outlined,
            onTap: () => _seleccionarCurso(p.cursoActual, maxCurso.clamp(1, 10))),
        _divider(context),
        _editTile(context,
            label: 'Semestre',
            value: '${p.semestreEnCurso}°',
            leadingIcon: Icons.layers_outlined,
            onTap: () => _seleccionarSemestre(p.semestreEnCurso)),
        _divider(context),
        _readTile(context,
            label: 'Créditos del semestre',
            value: creditosCalculados > 0
                ? '$creditosCalculados ECTS'
                : '${p.creditosSemestreActual} ECTS',
            leadingIcon: Icons.school_outlined),
        _divider(context),
        _readTile(context,
            label: 'Horas estimadas / sem',
            value: horasCalculadas > 0
                ? '${horasCalculadas}h'
                : '${p.horasObjetivoEstudioSemana}h',
            leadingIcon: Icons.access_time),
        _divider(context),
        _editTile(context,
            label: 'Promedio objetivo',
            value: p.promedioObjetivo != null
                ? p.promedioObjetivo!.toStringAsFixed(1)
                : '—',
            leadingIcon: Icons.trending_up,
            onTap: () => _editarNumeroDecimal(
                'Promedio objetivo (0-5)',
                p.promedioObjetivo,
                0,
                5,
                (v) => _guardar({'promedio_objetivo': v}))),
      ],
    );
  }

  Widget _buildInstitucionCard(BuildContext context, PerfilAcademicoDb p) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.primaryContainer.withValues(alpha: 0.12),
            cs.secondaryContainer.withValues(alpha: 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Universidad ──
          Row(
            children: [
              Icon(Icons.school_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text('Universidad',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  )),
            ],
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _seleccionarUniversidad(
                p.universidad != null ? null : null),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    p.universidad ?? 'No configurada',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: p.universidad != null
                          ? cs.onSurface
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.edit_outlined,
                      size: 14, color: cs.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // ── Carrera ──
          Row(
            children: [
              Icon(Icons.menu_book_rounded, size: 18, color: cs.secondaryContainer),
              const SizedBox(width: 8),
              Text('Carrera',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  )),
            ],
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () {
              if (_selectedUniversidadId != null || p.universidad != null) {
                _seleccionarCarrera(p.carrera);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    p.carrera ?? 'Selecciona universidad primero',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: p.carrera != null
                          ? cs.onSurface
                          : cs.onSurfaceVariant,
                    ),
                  ),
                ),
                if (p.carrera != null)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.edit_outlined,
                        size: 14, color: cs.secondaryContainer),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCursoCards(
      BuildContext context, List<({CarreraDb carrera, List<AsignaturaCatalogoDb> subjects})> data,
      List<AsignaturaUsuarioSemestreDb> mapeos) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Recopilar todos los cursos disponibles
    final cursos = <int>{};
    final subjectsPorCurso = <int, List<AsignaturaCatalogoDb>>{};
    final nombresCarrera = <String>{};
    for (final entry in data) {
      nombresCarrera.add(entry.carrera.nombre);
      for (final s in entry.subjects) {
        if (s.curso != null) {
          cursos.add(s.curso!);
          subjectsPorCurso.putIfAbsent(s.curso!, () => []).add(s);
        }
      }
    }

    // Contar asignaturas transversales mapeadas por curso
    final extraPorCurso = <int, int>{};
    for (final m in mapeos) {
      extraPorCurso[m.curso] = (extraPorCurso[m.curso] ?? 0) + 1;
    }

    if (cursos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('Sin asignaturas en el catálogo',
            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      );
    }

    final cursosOrdenados = cursos.toList()..sort();
    final carreraLabel = nombresCarrera.length == 1
        ? nombresCarrera.first
        : '${nombresCarrera.length} carreras';
    final totalAsignaturas = data.fold<int>(0, (s, e) => s + e.subjects.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Carrera(s) + contador
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '$carreraLabel · $totalAsignaturas asignaturas',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        // Mini cards de cursos en una sola fila
        Row(
          children: cursosOrdenados.map((curso) {
            final materias = subjectsPorCurso[curso]!;
            final extra = extraPorCurso[curso] ?? 0;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                    right: curso == cursosOrdenados.last ? 0 : 8),
                child: InkWell(
                  onTap: () => _showCursoBottomSheet(context, curso, materias),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Text('$curso°',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                            )),
                        const SizedBox(height: 1),
                        Text('Curso',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            )),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: extra > 0
                                ? cs.tertiary.withValues(alpha: 0.15)
                                : cs.primaryContainer.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            extra > 0
                                ? '${materias.length}+$extra asig.'
                                : '${materias.length} asig.',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: extra > 0 ? cs.tertiary : cs.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 9,
                              )),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showCursoBottomSheet(
      BuildContext context, int curso, List<AsignaturaCatalogoDb> materias) {
    final semestres = materias.map((m) => m.semestre).whereType<int>().toSet().toList()..sort();
    if (semestres.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return DefaultTabController(
              length: semestres.length,
              child: Column(
                children: [
                  // Handle
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Title + tabs
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        Text('Curso $curso',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            )),
                        const Spacer(),
                        Text('${materias.length} asignaturas',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            )),
                      ],
                    ),
                  ),
                  TabBar(
                    tabs: semestres.map((s) => Tab(text: '$s° Semestre')).toList(),
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: TabBarView(
                      children: semestres.map((sem) {
                        final filtered = materias.where((m) => m.semestre == sem).toList();
                        return ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                          children: filtered.map((m) => _subjectRow(context, m)).toList(),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _subjectRow(BuildContext context, AsignaturaCatalogoDb m) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            child: Icon(Icons.menu_book_outlined,
                size: 18, color: cs.primary.withValues(alpha: 0.5)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.nombre,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    )),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (m.creditos != null)
                      _badge(context, '${m.creditos} ECTS', cs.primary),
                    if (m.creditos != null && m.caracter != null)
                      const SizedBox(width: 6),
                    if (m.caracter != null)
                      _badge(context, m.caracter!, cs.secondaryContainer),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(BuildContext context, String text, Color color) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: theme.textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          )),
    );
  }

  Widget _divider(BuildContext context) => Divider(
      height: 1,
      indent: 48,
      color:
          Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3));
}

// =============================================================================
// _AjustesTab
// =============================================================================
class _AjustesTab extends ConsumerWidget {
  const _AjustesTab({
    required this.usuario,
    required this.prefs,
  });

  final UsuarioDb usuario;
  final PreferenciasNotificacionDb prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // ── Opciones de cuenta ──
        _sectionTitle(context, 'Cuenta'),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          leading: Icon(Icons.visibility_outlined, color: cs.primary),
          title:
              Text('Visibilidad del perfil', style: theme.textTheme.bodyMedium),
          subtitle: Text('Privado · Solo tus amigos pueden ver tus rutinas',
              style: theme.textTheme.bodySmall?.copyWith(
                color: SVColors.onSurfaceMuted,
              )),
          trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          onTap: () {},
        ),
        Divider(
            height: 1,
            indent: 56,
            color: cs.outlineVariant.withValues(alpha: 0.3)),
        ListTile(
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          leading: Icon(Icons.notifications_outlined, color: cs.primary),
          title: Text('Notificaciones', style: theme.textTheme.bodyMedium),
          subtitle:
              Text('Modo: ${prefs.modoActual} · ${prefs.limiteDiario}/día',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: SVColors.onSurfaceMuted,
                  )),
          trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          onTap: () => context.push('/notificaciones'),
        ),
        Divider(
            height: 1,
            indent: 56,
            color: cs.outlineVariant.withValues(alpha: 0.3)),
        ListTile(
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          leading: Icon(Icons.dark_mode_outlined, color: cs.primary),
          title: Text('Modo silencio', style: theme.textTheme.bodyMedium),
          subtitle: Text(
            '${prefs.horaSilencioInicio ?? '—'} a ${prefs.horaSilencioFin ?? '—'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: SVColors.onSurfaceMuted,
            ),
          ),
          trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          onTap: () {},
        ),

        const SizedBox(height: 24),
        _sectionTitle(context, 'Aplicación'),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          leading: Icon(Icons.info_outline, color: cs.primary),
          title:
              Text('Acerca de SynaptixFit', style: theme.textTheme.bodyMedium),
          trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          onTap: () {},
        ),

        const SizedBox(height: 24),

        // ── Panel de administración (solo admin) ──
        Consumer(
          builder: (context, ref, _) {
            final esAdminAsync = ref.watch(esAdminProvider);
            return esAdminAsync.when(
              data: (esAdmin) => esAdmin
                  ? Column(
                      children: [
                        _sectionTitle(context, 'Administración'),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          leading: Icon(Icons.admin_panel_settings,
                              color: cs.primary),
                          title: Text('Panel de Administración',
                              style: theme.textTheme.bodyMedium),
                          subtitle: Text('Gestionar usuarios, roles y datos',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: SVColors.onSurfaceMuted,
                              )),
                          trailing: Icon(Icons.chevron_right,
                              color: cs.onSurfaceVariant),
                          onTap: () => context.push('/admin'),
                        ),
                        const SizedBox(height: 24),
                      ],
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            );
          },
        ),

        // ── Cerrar sesión ──
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              try {
                await ref.read(authControllerProvider.notifier).logout();
                ref.invalidate(perfilUsuarioProvider);
                ref.invalidate(dashboardProvider);
                ref.invalidate(rutinasUsuarioProvider);
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
                size: 18, color: SVColors.error),
            label: const Text('Cerrar sesión',
                style: TextStyle(color: SVColors.error)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              side: BorderSide(color: SVColors.error.withValues(alpha: 0.3)),
            ),
          ),
        ),
      ],
    );
  }
}
