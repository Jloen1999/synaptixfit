import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../../shared/models/db_models.dart';
import '../../../shared/utils/image_utils.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../academico/application/asignaturas_provider.dart';
import '../../academico/application/catalogo_provider.dart';
import '../../academico/infrastructure/ics_sync_service.dart';
import '../../bienestar/application/rutina_provider.dart';
import '../../bienestar/application/ejercicios_provider.dart';
import '../../../core/design_system/sv_colors.dart';
import '../../dashboard/application/dashboard_provider.dart';
import '../../insignias/application/insignias_provider.dart';
import '../../insignias/presentation/widgets/racha_indicator.dart';
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
  String? _userIdActual;

  static const _sectionLabels = [
    'Bienestar',
    'Logros',
    'Ajustes',
  ];
  static const _sectionIcons = [
    Icons.fitness_center_rounded,
    Icons.military_tech_rounded,
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
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final usuarioCambio = _userIdActual != null &&
        currentUserId != null &&
        _userIdActual != currentUserId;

    if (currentUserId != null && currentUserId != _userIdActual) {
      _userIdActual = currentUserId;
    }

    if (usuarioCambio) {
      _cachedUsuario = null;
      _cachedPrefs = null;
    }

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
                _BienestarTab(
                  onPerfilChanged: () =>
                      _onPerfilActualizado(cambio: PerfilCambio.bienestar),
                ),
                const _EstadisticasTab(),
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
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            children: [
              // ── Avatar + Nombre ──
              Row(
                children: [
                  // Avatar con anillo de acento
                  Container(
                    width: 56,
                    height: 56,
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
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: Container(
                        color: cs.primaryContainer,
                        child: tieneAvatar
                            ? Image.network(
                                normalizarUrlAvatar(widget.usuario.urlAvatar!),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _avatarInitial(initial),
                              )
                            : _avatarInitial(initial),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                            const SizedBox(width: 40),
                          ],
                        ),
                        const SizedBox(height: 1),
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

              const SizedBox(height: 14),

              // ── Nivel + barra de progreso XP ──
              _xpProgress(context),
              const SizedBox(height: 14),

              // ── Stats: sesiones, racha, calorías, retos ──
              Row(
                children: [
                  Expanded(
                      child: _statItem(context, '${act.sesiones}', 'Sesiones',
                          Icons.fitness_center_rounded)),
                  _statDivider(context),
                  Expanded(
                    child: Consumer(
                      builder: (context, ref, _) {
                        final racha = ref.watch(rachaStateProvider).valueOrNull;
                        final dias = racha?.diasConsecutivos ??
                            widget.usuario.rachaActual;
                        return _statItem(
                            context, '$dias', 'Racha', Icons.whatshot_rounded);
                      },
                    ),
                  ),
                  _statDivider(context),
                  Expanded(
                      child: _statItem(
                          context,
                          _formatNum(act.caloriasAcumuladas),
                          'Calorías',
                          Icons.local_fire_department_rounded)),
                  _statDivider(context),
                  Expanded(
                      child: _statItem(context, '${act.logros}', 'Retos',
                          Icons.emoji_events_rounded)),
                ],
              ),
            ],
          ),
          Positioned(
            top: -4,
            right: -8,
            child: Consumer(
              builder: (context, ref, _) => IconButton(
                onPressed: () async {
                  try {
                    await ref.read(authControllerProvider.notifier).logout();
                  } catch (_) {}
                  if (!context.mounted) return;
                  context.go('/acceso');
                },
                icon: const Icon(Icons.logout_rounded, size: 20),
                color: cs.onPrimary.withValues(alpha: 0.8),
                tooltip: 'Cerrar sesión',
                splashRadius: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _xpProgress(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final nivel = widget.usuario.nivel.clamp(1, 999);
    final objetivo = nivel * 100;
    final xp = widget.usuario.xpTotal;
    final progreso = objetivo > 0 ? (xp / objetivo).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars_rounded,
                    size: 14, color: cs.secondaryContainer),
                const SizedBox(width: 4),
                Text('Nivel $nivel',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
            Text('$xp / $objetivo XP',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onPrimary.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progreso,
            minHeight: 6,
            backgroundColor: cs.onPrimary.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(cs.secondaryContainer),
          ),
        ),
      ],
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
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _statItem(
      BuildContext context, String value, String label, IconData icon) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: cs.onPrimary.withValues(alpha: 0.7)),
        const SizedBox(height: 2),
        Text(value,
            style: theme.textTheme.titleMedium?.copyWith(
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
      height: 32,
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
    final cs = Theme.of(context).colorScheme;
    final insigniasAsync = ref.watch(insigniasUsuarioProvider);
    final insignias = insigniasAsync.valueOrNull ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        const RachaIndicator(),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
          ),
          child: _buildInsigniasPreview(context, ref, insignias),
        ),
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
// _dataChip — chip compacto para créditos/horas/promedio
// =============================================================================
Widget _dataChip(
  BuildContext context, {
  required IconData icon,
  required String value,
  required String label,
  VoidCallback? onTap,
}) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: cs.primary),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 2),
            Icon(Icons.chevron_right, size: 14, color: cs.onSurfaceVariant),
          ],
        ],
      ),
    ),
  );
}

Widget _dataDivider(BuildContext context) {
  return Container(
    width: 1,
    height: 32,
    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
  );
}

// =============================================================================
// _sectionCard — tarjeta de sección unificada (clean UI)
// =============================================================================
Widget _sectionCard(
  BuildContext context, {
  IconData? icon,
  required String title,
  Widget? trailing,
  EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(16, 14, 16, 14),
  required List<Widget> children,
}) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 14),
    padding: padding,
    decoration: BoxDecoration(
      color: cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: cs.primary),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
            if (trailing != null) trailing,
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
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
          diasDisponibles: const [],
          minutosPorSesion: 0,
          onboardingCompletado: false,
          creadoEn: DateTime.now(),
          actualizadoEn: DateTime.now(),
        );
    final historial = bienestarAsync.valueOrNull?.historial ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // ── Cuerpo ──
        _sectionCard(
          context,
          icon: Icons.accessibility_new_rounded,
          title: 'Cuerpo',
          children: [
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
          ],
        ),

        // ── Entrenamiento ──
        _sectionCard(
          context,
          icon: Icons.fitness_center_rounded,
          title: 'Entrenamiento',
          children: [
            _editTile(context,
                label: 'Objetivo',
                value: _fmt(p.objetivoPrincipal),
                leadingIcon: Icons.flag_outlined,
                onTap: _editarObjetivo),
            _divider(context),
            _editTile(context,
                label: 'Actividad',
                value:
                    p.nivelActividad.isNotEmpty ? _fmt(p.nivelActividad) : '—',
                leadingIcon: Icons.directions_run,
                onTap: _editarNivelActividad),
            _divider(context),
            _editTile(context,
                label: 'Días / semana',
                value: p.diasDisponibles.isNotEmpty
                    ? p.diasDisponibles
                        .map((d) =>
                            const ['', 'L', 'M', 'X', 'J', 'V', 'S', 'D'][d])
                        .join(', ')
                    : '—',
                leadingIcon: Icons.calendar_today,
                onTap: _editarDias),
            _divider(context),
            _editTile(context,
                label: 'Min / sesión',
                value: p.minutosPorSesion > 0 ? '${p.minutosPorSesion}' : '—',
                leadingIcon: Icons.timer_outlined,
                onTap: _editarMinutos),
          ],
        ),

        // ── Equipamiento ──
        _sectionCard(
          context,
          icon: Icons.sports_gymnastics_outlined,
          title: 'Equipamiento',
          children: [
            if (p.equipamientoDisponible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('Sin equipamiento configurado',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: SVColors.onSurfaceMuted,
                    )),
              )
            else
              Wrap(
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
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _editarEquipamiento,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Configurar equipamiento'),
              ),
            ),
          ],
        ),

        // ── Evolución de peso ──
        _sectionCard(
          context,
          icon: Icons.trending_up_rounded,
          title: 'Evolución de peso',
          children: [
            if (historial.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
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
        ),
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
    final diasActuales = Set<int>.from(_cachedPerfil!.diasDisponibles);
    final result = await showDialog<Set<int>>(
      context: context,
      builder: (ctx) {
        var seleccionados = Set<int>.from(diasActuales);
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Días de entrenamiento'),
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (i) {
                final dia = i + 1;
                const labels = [
                  'Lunes',
                  'Martes',
                  'Miércoles',
                  'Jueves',
                  'Viernes',
                  'Sábado',
                  'Domingo',
                ];
                return FilterChip(
                  label: Text(labels[i]),
                  selected: seleccionados.contains(dia),
                  onSelected: (v) => setDialogState(() {
                    if (v) {
                      seleccionados.add(dia);
                    } else {
                      seleccionados.remove(dia);
                    }
                  }),
                );
              }),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar')),
              FilledButton(
                onPressed: seleccionados.isEmpty
                    ? null
                    : () => Navigator.pop(ctx, seleccionados),
                child: const Text('Guardar'),
              ),
            ],
          ),
        );
      },
    );
    if (result != null && result.isNotEmpty && mounted) {
      final sorted = result.toList()..sort();
      await _guardar({
        'dias_disponibles': sorted,
        'dias_disponibles_semana': sorted.length,
      });
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

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(perfilAcademicoProvider).valueOrNull ?? _empty();
    final carreraDataAsync = ref.watch(carreraConAsignaturasProvider);
    final carreraData = carreraDataAsync.valueOrNull ?? [];
    final activasAsync = ref.watch(asignaturasActivasProvider);
    final activas = activasAsync.valueOrNull ?? [];
    final tema = Theme.of(context);
    final cs = tema.colorScheme;

    int creditosCalculados = 0;
    int horasCalculadas = 0;
    if (carreraData.isNotEmpty) {
      for (final entry in carreraData) {
        for (final s in entry.subjects) {
          if (s.curso == p.cursoActual && s.semestre == p.semestreEnCurso) {
            creditosCalculados += (s.creditos ?? 0).round();
            horasCalculadas += (s.horas ?? 0);
          }
        }
      }
    }

    final catalogoMap = <String, AsignaturaCatalogoDb>{};
    for (final entry in carreraData) {
      for (final s in entry.subjects) {
        catalogoMap[s.id] = s;
      }
    }
    final cursoCount = <int, int>{};
    for (final a in activas) {
      final cat = a.catalogoAsignaturaId != null
          ? catalogoMap[a.catalogoAsignaturaId]
          : null;
      if (cat?.curso != null) {
        cursoCount[cat!.curso!] = (cursoCount[cat.curso!] ?? 0) + 1;
      }
    }
    final cursosOrdenados = cursoCount.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _buildInstitucionCard(context, p),
        const SizedBox(height: 14),
        _sectionCard(
          context,
          icon: Icons.event_note_outlined,
          title: 'Curso actual',
          children: [
            _editTile(context,
                label: 'Semestre',
                value: '${p.semestreEnCurso}° Semestre',
                leadingIcon: Icons.calendar_today_outlined,
                onTap: () => _seleccionarSemestre(p.semestreEnCurso)),
            if (cursosOrdenados.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: cursosOrdenados.map((c) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$c° Curso · ${cursoCount[c]} asig.',
                      style: tema.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSecondaryContainer,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            _divider(context),
            Row(
              children: [
                Expanded(
                  child: _dataChip(context,
                      icon: Icons.school_outlined,
                      value: creditosCalculados > 0
                          ? '$creditosCalculados ECTS'
                          : '${p.creditosSemestreActual} ECTS',
                      label: 'Créditos'),
                ),
                _dataDivider(context),
                Expanded(
                  child: _dataChip(context,
                      icon: Icons.access_time,
                      value: horasCalculadas > 0
                          ? '${horasCalculadas}h'
                          : '${p.horasObjetivoEstudioSemana}h',
                      label: 'Horas / sem'),
                ),
                _dataDivider(context),
                Expanded(
                  child: _dataChip(context,
                      icon: Icons.trending_up,
                      value: p.promedioObjetivo != null
                          ? p.promedioObjetivo!.toStringAsFixed(1)
                          : '—',
                      label: 'Promedio',
                      onTap: () => _editarNumeroDecimal(
                          'Promedio objetivo (0-5)',
                          p.promedioObjetivo,
                          0,
                          5,
                          (v) => _guardar({'promedio_objetivo': v}))),
                ),
              ],
            ),
          ],
        ),
        _buildMisAsignaturasCard(context, carreraData),
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
            onTap: () =>
                _seleccionarUniversidad(p.universidad != null ? null : null),
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
                  child: Icon(Icons.edit_outlined, size: 14, color: cs.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // ── Carrera ──
          Row(
            children: [
              Icon(Icons.menu_book_rounded,
                  size: 18, color: cs.secondaryContainer),
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

  Widget _buildMisAsignaturasCard(
    BuildContext context,
    List<({CarreraDb carrera, List<AsignaturaCatalogoDb> subjects})>
        carreraData,
  ) {
    final tema = Theme.of(context);
    final cs = tema.colorScheme;
    final activasAsync = ref.watch(asignaturasActivasProvider);

    return activasAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (activas) {
        final catalogoMap = <String, AsignaturaCatalogoDb>{};
        for (final entry in carreraData) {
          for (final s in entry.subjects) {
            catalogoMap[s.id] = s;
          }
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 6, 14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.book_outlined, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Mis asignaturas',
                    style: tema.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${activas.length}',
                      style: tema.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () =>
                        context.push('/perfil/asignaturas/selector'),
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Editar selección'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (activas.isEmpty)
                Text(
                  'No tienes asignaturas seleccionadas',
                  style: tema.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                )
              else
                for (final a in activas)
                  if (a.catalogoAsignaturaId != null &&
                      catalogoMap[a.catalogoAsignaturaId] != null)
                    _SubjectRow(
                        catalogoSubject: catalogoMap[a.catalogoAsignaturaId]!)
                  else
                    _buildAsignaturaRow(a, catalogoMap, tema, cs),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAsignaturaRow(
    AsignaturaDb a,
    Map<String, AsignaturaCatalogoDb> catalogoMap,
    ThemeData tema,
    ColorScheme cs,
  ) {
    final cat = a.catalogoAsignaturaId != null
        ? catalogoMap[a.catalogoAsignaturaId]
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              a.nombre,
              style: tema.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (cat?.creditos != null) ...[
            const SizedBox(width: 6),
            Text(
              '${cat!.creditos!.toStringAsFixed(cat.creditos!.truncateToDouble() == cat.creditos! ? 0 : 1)} ECTS',
              style: tema.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
          if (cat?.curso != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${cat!.curso}°',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: cs.onTertiaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
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
        // ── Cuenta ──
        _sectionCard(
          context,
          icon: Icons.manage_accounts_outlined,
          title: 'Cuenta',
          children: [
            _ajusteTile(
              context,
              icon: Icons.visibility_outlined,
              title: 'Visibilidad del perfil',
              subtitle: _privacidadDescripcion(usuario.nivelPrivacidad),
              onTap: () => _editarVisibilidad(context, ref),
            ),
            _dividerAjuste(cs),
            _ajusteTile(
              context,
              icon: Icons.notifications_outlined,
              title: 'Notificaciones',
              subtitle: 'Modo: ${prefs.modoActual} · ${prefs.limiteDiario}/día',
              onTap: () => context.push('/notificaciones'),
            ),
            _dividerAjuste(cs),
            _ajusteTile(
              context,
              icon: Icons.dark_mode_outlined,
              title: 'Modo silencio',
              subtitle: (prefs.horaSilencioInicio != null &&
                      prefs.horaSilencioFin != null)
                  ? '${_horaCorta(prefs.horaSilencioInicio!)} – ${_horaCorta(prefs.horaSilencioFin!)}'
                  : 'Desactivado',
              onTap: () => _editarModoSilencio(context, ref),
            ),
          ],
        ),

        // ── Aplicación ──
        _sectionCard(
          context,
          icon: Icons.tune_rounded,
          title: 'Aplicación',
          children: [
            _ajusteTile(
              context,
              icon: Icons.info_outline,
              title: 'Acerca de SynaptixFit',
              subtitle: 'Versión, créditos y licencia',
              onTap: () => _mostrarAcercaDe(context),
            ),
          ],
        ),

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

  Widget _ajusteTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      leading: Icon(icon, color: cs.primary),
      title: Text(title, style: theme.textTheme.bodyMedium),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: SVColors.onSurfaceMuted,
              ))
          : null,
      trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
      onTap: onTap,
    );
  }

  Widget _dividerAjuste(ColorScheme cs) => Divider(
        height: 1,
        indent: 40,
        color: cs.outlineVariant.withValues(alpha: 0.3),
      );

  String _privacidadDescripcion(String nivel) {
    switch (nivel) {
      case 'publico':
        return 'Público · Cualquiera ve tus rutinas, bloques y retos';
      case 'amigos':
        return 'Solo amigos · Tus amigos ven tus rutinas, bloques y retos';
      default:
        return 'Privado · Solo tú ves tu actividad';
    }
  }

  String _horaCorta(String t) => t.length >= 5 ? t.substring(0, 5) : t;

  TimeOfDay? _parseHora(String? t) {
    if (t == null) return null;
    final parts = t.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  Future<void> _editarVisibilidad(BuildContext context, WidgetRef ref) async {
    final actual = usuario.nivelPrivacidad;
    final opciones = <String, (String, String, IconData)>{
      'publico': (
        'Público',
        'Cualquiera puede ver tus rutinas, bloques de estudio y retos',
        Icons.public,
      ),
      'amigos': (
        'Solo amigos',
        'Solo tus amigos pueden verlos',
        Icons.group_outlined,
      ),
      'privado': (
        'Privado',
        'Solo tú puedes verlos',
        Icons.lock_outline,
      ),
    };
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Visibilidad del perfil'),
        children: opciones.entries.map((e) {
          final sel = e.key == actual;
          final cs = Theme.of(ctx).colorScheme;
          return SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, e.key),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                    sel
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: sel ? cs.primary : cs.onSurfaceVariant),
                const SizedBox(width: 12),
                Icon(e.value.$3, size: 20, color: cs.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.value.$1,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(e.value.$2,
                          style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                                color: SVColors.onSurfaceMuted,
                              )),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
    if (result != null && result != actual && context.mounted) {
      await ref.read(bienestarRepositoryProvider).actualizarPrivacidad(result);
      ref.invalidate(perfilUsuarioProvider);
    }
  }

  Future<void> _editarModoSilencio(BuildContext context, WidgetRef ref) async {
    TimeOfDay? inicio = _parseHora(prefs.horaSilencioInicio);
    TimeOfDay? fin = _parseHora(prefs.horaSilencioFin);

    String fmt(TimeOfDay? t) => t == null
        ? '—'
        : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

    final guardar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) {
          Future<void> pick(bool esInicio) async {
            final picked = await showTimePicker(
              context: ctx,
              initialTime: (esInicio ? inicio : fin) ??
                  const TimeOfDay(hour: 22, minute: 0),
            );
            if (picked != null) {
              setD(() {
                if (esInicio) {
                  inicio = picked;
                } else {
                  fin = picked;
                }
              });
            }
          }

          return AlertDialog(
            title: const Text('Modo silencio'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'No recibirás notificaciones dentro de este intervalo.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.bedtime_outlined, size: 20),
                  title: const Text('Inicio'),
                  trailing: Text(fmt(inicio)),
                  onTap: () => pick(true),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.wb_sunny_outlined, size: 20),
                  title: const Text('Fin'),
                  trailing: Text(fmt(fin)),
                  onTap: () => pick(false),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('Cancelar')),
              TextButton(
                onPressed: () {
                  inicio = null;
                  fin = null;
                  Navigator.pop(ctx, true);
                },
                child: const Text('Desactivar'),
              ),
              FilledButton(
                onPressed: (inicio != null && fin != null)
                    ? () => Navigator.pop(ctx, true)
                    : null,
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      ),
    );

    if (guardar == true && context.mounted) {
      String? toStr(TimeOfDay? t) => t == null
          ? null
          : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
      await ref.read(bienestarRepositoryProvider).actualizarPreferencias({
        'hora_silencio_inicio': toStr(inicio),
        'hora_silencio_fin': toStr(fin),
      });
      ref.invalidate(perfilPreferenciasProvider);
    }
  }

  void _mostrarAcercaDe(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'SynaptixFit',
      applicationVersion: 'v1.0.0',
      applicationIcon: const Icon(Icons.fitness_center_rounded,
          size: 40, color: SVColors.primary),
      children: const [
        Text(
          'Tu rendimiento académico y físico en un solo lugar. '
          'Planifica, entrena y progresa.',
        ),
      ],
    );
  }
}

Widget _buildBadge(BuildContext context, String text, Color color) {
  final theme = Theme.of(context);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      text,
      style: theme.textTheme.labelSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
        fontSize: 10,
      ),
    ),
  );
}

class _SubjectRow extends ConsumerStatefulWidget {
  const _SubjectRow({required this.catalogoSubject});

  final AsignaturaCatalogoDb catalogoSubject;

  @override
  ConsumerState<_SubjectRow> createState() => _SubjectRowState();
}

class _SubjectRowState extends ConsumerState<_SubjectRow> {
  final _urlController = TextEditingController();
  Timer? _debounce;
  bool _sincronizando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializarUrl();
    });
  }

  void _inicializarUrl() {
    final asignaturaAsync =
        ref.read(asignaturaPorCatalogoProvider(widget.catalogoSubject.id));
    asignaturaAsync.whenData((asig) {
      if (asig != null && _urlController.text.isEmpty) {
        _urlController.text = asig.icsUrl ?? '';
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _urlController.dispose();
    super.dispose();
  }

  void _guardarUrl(String url) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;
      await client
          .from('asignaturas')
          .update({
            'ics_url': url,
          })
          .eq('usuario_id', user.id)
          .eq(
            'catalogo_asignatura_id',
            widget.catalogoSubject.id,
          );
    });
  }

  Future<void> _sincronizar() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Ingresa una URL de calendario');
      return;
    }

    setState(() {
      _sincronizando = true;
      _error = null;
    });

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      setState(() {
        _sincronizando = false;
        _error = 'Sesión no iniciada';
      });
      return;
    }

    final asignaturaAsync =
        ref.read(asignaturaPorCatalogoProvider(widget.catalogoSubject.id));
    var asig = asignaturaAsync.valueOrNull;

    String asignaturaId;
    if (asig != null) {
      asignaturaId = asig.id;
      await client.from('asignaturas').update({
        'ics_url': url,
      }).eq('id', asignaturaId);
    } else {
      final row = await client
          .from('asignaturas')
          .insert({
            'usuario_id': user.id,
            'nombre': widget.catalogoSubject.nombre,
            'codigo': widget.catalogoSubject.caracter,
            'catalogo_asignatura_id': widget.catalogoSubject.id,
            'creditos': widget.catalogoSubject.creditos?.toInt() ?? 6,
            'ics_url': url,
          })
          .select('id')
          .single();
      asignaturaId = row['id'] as String;
      ref.invalidate(
        asignaturaPorCatalogoProvider(widget.catalogoSubject.id),
      );
    }

    final syncService = ref.read(icsSyncServiceProvider);
    final result = await syncService.sincronizar(
      asignaturaId: asignaturaId,
      asignaturaNombre: widget.catalogoSubject.nombre,
      asignaturaCodigo: widget.catalogoSubject.caracter,
      icsUrl: url,
    );

    if (!mounted) return;

    if (result.sinCoincidencia) {
      final forzar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sin coincidencias'),
          content: Text(
            'No se encontró la asignatura "${widget.catalogoSubject.nombre}" '
            'en los eventos del calendario.\n\n'
            '¿Deseas importar todos los eventos igualmente?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Importar todos igualmente'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (forzar == true) {
        setState(() => _sincronizando = true);
        final forcedResult = await syncService.sincronizar(
          asignaturaId: asignaturaId,
          asignaturaNombre: widget.catalogoSubject.nombre,
          asignaturaCodigo: widget.catalogoSubject.caracter,
          icsUrl: url,
          forzar: true,
        );
        if (!mounted) return;
        setState(() => _sincronizando = false);
        if (forcedResult.exitoso) {
          ref.invalidate(
            asignaturaPorCatalogoProvider(widget.catalogoSubject.id),
          );
          _mostrarSnackbar(
            '${forcedResult.examenes} exámenes · '
            '${forcedResult.entregas} entregas · '
            '${forcedResult.clases} clases importados',
          );
        } else {
          setState(() => _error = forcedResult.error ?? 'Error desconocido');
        }
      } else {
        setState(() => _sincronizando = false);
      }
      return;
    }

    setState(() => _sincronizando = false);
    if (result.exitoso) {
      _mostrarSnackbar(
        '${result.examenes} exámenes · '
        '${result.entregas} entregas · '
        '${result.clases} clases importados',
      );
      ref.invalidate(asignaturaPorCatalogoProvider(widget.catalogoSubject.id));
    } else {
      setState(() => _error = result.error ?? 'Error desconocido');
    }
  }

  void _mostrarSnackbar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final m = widget.catalogoSubject;

    final asignaturaAsync = ref.watch(asignaturaPorCatalogoProvider(m.id));
    final asig = asignaturaAsync.valueOrNull;

    String estadoTexto;
    IconData? estadoIcono;
    Color estadoColor;

    if (_sincronizando) {
      estadoTexto = 'Sincronizando...';
      estadoIcono = null;
      estadoColor = cs.primary;
    } else if (_error != null) {
      estadoTexto = '✗ $_error';
      estadoIcono = Icons.error_outline;
      estadoColor = cs.error;
    } else if (asig?.ultimaSincronizacion != null) {
      final fecha = asig!.ultimaSincronizacion!;
      final ahora = DateTime.now();
      final diff = ahora.difference(fecha);
      String fechaStr;
      if (diff.inMinutes < 1) {
        fechaStr = 'ahora';
      } else if (diff.inMinutes < 60) {
        fechaStr = 'hace ${diff.inMinutes} min';
      } else if (diff.inHours < 24) {
        fechaStr = 'hace ${diff.inHours} h';
      } else {
        fechaStr = '${fecha.day}/${fecha.month}/${fecha.year} '
            '${fecha.hour.toString().padLeft(2, '0')}:'
            '${fecha.minute.toString().padLeft(2, '0')}';
      }
      estadoTexto = '✓ Sincronizado: $fechaStr';
      estadoIcono = Icons.check_circle_outline;
      estadoColor = cs.tertiary;
    } else {
      estadoTexto = 'Sin sincronizar';
      estadoIcono = Icons.sync_disabled;
      estadoColor = cs.onSurfaceVariant;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.menu_book_outlined,
                  size: 18,
                  color: cs.primary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.nombre,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (m.creditos != null)
                          _buildBadge(
                            context,
                            '${m.creditos} ECTS',
                            cs.primary,
                          ),
                        if (m.creditos != null && m.caracter != null)
                          const SizedBox(width: 6),
                        if (m.caracter != null)
                          _buildBadge(
                            context,
                            m.caracter!,
                            cs.secondaryContainer,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: TextField(
                    controller: _urlController,
                    style: theme.textTheme.bodySmall,
                    decoration: InputDecoration(
                      hintText: 'Pegar URL del calendario (.ics)',
                      hintStyle: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: 0.4),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: cs.primary.withValues(alpha: 0.5),
                        ),
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      _guardarUrl(value);
                      setState(() => _error = null);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                height: 34,
                width: 34,
                child: IconButton(
                  icon: _sincronizando
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.primary,
                          ),
                        )
                      : Icon(Icons.sync, size: 18, color: cs.primary),
                  onPressed: _sincronizando ? null : _sincronizar,
                  padding: EdgeInsets.zero,
                  tooltip: 'Sincronizar calendario',
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Row(
              children: [
                if (estadoIcono != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(estadoIcono, size: 12, color: estadoColor),
                  ),
                Expanded(
                  child: Text(
                    estadoTexto,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: estadoColor,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
