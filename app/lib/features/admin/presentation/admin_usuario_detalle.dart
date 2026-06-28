import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/utils/image_utils.dart';
import '../application/admin_provider.dart';
import 'widgets/admin_graficos_usuario.dart';
import 'widgets/admin_timeline_usuario.dart';
import 'widgets/admin_wipe_dialog.dart';

/// Pantalla de detalle de un usuario desde el panel de administración.
///
/// Muestra datos de perfil, bienestar, académico, conteos de actividad,
/// actividad reciente y un bloque de configuración de usuario. Incluye
/// un TabBar interno con tres sub-pestañas: Perfil, Estadísticas y Timeline.
class AdminUsuarioDetalleScreen extends ConsumerWidget {
  final String usuarioId;

  const AdminUsuarioDetalleScreen({
    required this.usuarioId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalleAsync = ref.watch(adminUsuarioDetalleProvider(usuarioId));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalle de Usuario'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Perfil'),
              Tab(text: 'Estadísticas'),
              Tab(text: 'Timeline'),
            ],
          ),
        ),
        body: detalleAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text('Error: $err'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  onPressed: () =>
                      ref.invalidate(adminUsuarioDetalleProvider(usuarioId)),
                ),
              ],
            ),
          ),
          data: (data) => _buildTabContent(context, ref, data),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> data,
  ) {
    return TabBarView(
      children: [
        // Tab 0: Perfil
        _buildContent(context, ref, data),
        // Tab 1: Estadísticas
        AdminGraficosUsuario(usuarioId: usuarioId),
        // Tab 2: Timeline
        AdminTimelineUsuario(usuarioId: usuarioId),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> data,
  ) {
    final nombre = data['nombre_completo'] as String? ?? '—';
    final email = data['email'] as String? ?? '—';
    final avatar = data['url_avatar'] as String?;
    final rol = (data['rol'] as String?) ?? 'usuario';
    final nivel = (data['nivel'] as num?)?.toInt() ?? 1;
    final xpTotal = (data['xp_total'] as num?)?.toInt() ?? 0;
    final racha = (data['racha_actual'] as num?)?.toInt() ?? 0;
    final creadoEn = data['creado_en'] as String?;

    final perfilBienestar =
        data['perfil_bienestar_usuario'] as Map<String, dynamic>?;
    final perfilAcademico =
        data['perfil_academico_usuario'] as Map<String, dynamic>?;
    final conteos = data['_conteos'] as Map<String, dynamic>? ?? {};

    // Datos de actividad reciente (Tarea 3b)
    final sesionesRecientes =
        (data['_sesiones_recientes'] as List<dynamic>?) ?? [];
    final retosRecientes = (data['_retos_recientes'] as List<dynamic>?) ?? [];
    final insigniasRecientes =
        (data['_insignias_recientes'] as List<dynamic>?) ?? [];
    final rutinasRecientes =
        (data['_rutinas_recientes'] as List<dynamic>?) ?? [];

    final rolColor = rol == 'admin' ? Colors.amber.shade700 : Colors.blueGrey;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──
          _buildHeader(nombre, email, avatar, rol, rolColor, creadoEn),
          const SizedBox(height: 20),

          // ── Cards de perfil ──
          _buildPerfilCard(nivel, xpTotal, racha),
          const SizedBox(height: 12),

          if (perfilBienestar != null) ...[
            _buildBienestarCard(perfilBienestar),
            const SizedBox(height: 12),
          ],

          if (perfilAcademico != null) ...[
            _buildAcademicoCard(perfilAcademico),
            const SizedBox(height: 12),
          ],

          // ── Conteos ──
          _buildConteosCard(conteos),
          const SizedBox(height: 20),

          // ── Actividad reciente (Tarea 3b) ──
          if (sesionesRecientes.isNotEmpty) ...[
            _buildSesionesRecientes(sesionesRecientes),
            const SizedBox(height: 12),
          ],

          if (retosRecientes.isNotEmpty) ...[
            _buildRetosRecientes(retosRecientes),
            const SizedBox(height: 12),
          ],

          if (rutinasRecientes.isNotEmpty) ...[
            _buildRutinasRecientes(rutinasRecientes),
            const SizedBox(height: 12),
          ],

          if (insigniasRecientes.isNotEmpty) ...[
            _buildInsigniasRecientes(insigniasRecientes),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 8),

          // ── Bloque de configuración (Tarea 3c) ──
          _buildConfiguracionUsuario(context, ref, nombre, email, nivel),

          const SizedBox(height: 12),

          // ── Botón de wipe ──
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              onPressed: () => _confirmarWipe(context, ref, nombre),
              icon: const Icon(Icons.delete_forever),
              label: const Text('Eliminar todos los datos (Wipe)'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Botón de eliminación permanente (Tarea 2d) ──
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _confirmarEliminar(context, ref, nombre, email),
              icon: const Icon(Icons.person_remove, color: Colors.red),
              label: const Text('Eliminar usuario permanentemente',
                  style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),
          Center(
            child: Text(
              'ID: $usuarioId',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Header
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildHeader(
    String nombre,
    String email,
    String? avatar,
    String rol,
    Color rolColor,
    String? creadoEn,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ClipOval(
              child: SizedBox(
                width: 80,
                height: 80,
                child: avatar != null && avatar.isNotEmpty
                    ? Image.network(
                        normalizarUrlAvatar(avatar),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarFallback(nombre),
                      )
                    : _avatarFallback(nombre),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              nombre,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: rolColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                rol.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: rolColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (creadoEn != null) ...[
              const SizedBox(height: 8),
              Text(
                'Miembro desde ${_formatearFecha(creadoEn)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Cards de perfil básico
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildPerfilCard(int nivel, int xpTotal, int racha) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, size: 20, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Perfil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _StatItem(
                    icon: Icons.stars_rounded,
                    label: 'Nivel',
                    value: '$nivel',
                    color: Colors.amber),
                _StatItem(
                    icon: Icons.emoji_events_outlined,
                    label: 'XP',
                    value: '$xpTotal',
                    color: Colors.purple),
                _StatItem(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Racha',
                    value: '$racha',
                    color: Colors.deepOrange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBienestarCard(Map<String, dynamic> perfil) {
    final peso = perfil['peso_kg'];
    final altura = perfil['altura_cm'];
    final objetivo = perfil['objetivo_principal'];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.favorite, size: 20, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Bienestar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                if (peso != null)
                  _StatItem(
                      icon: Icons.monitor_weight_outlined,
                      label: 'Peso',
                      value: '$peso kg',
                      color: Colors.teal),
                if (altura != null)
                  _StatItem(
                      icon: Icons.height,
                      label: 'Altura',
                      value: '$altura cm',
                      color: Colors.blue),
                if (objetivo != null)
                  _StatItem(
                      icon: Icons.flag_outlined,
                      label: 'Objetivo',
                      value: '$objetivo',
                      color: Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicoCard(Map<String, dynamic> perfil) {
    final carrera = perfil['carrera'];
    final semestre = perfil['semestre_actual'];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.school, size: 20, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Académico',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 24,
              runSpacing: 8,
              children: [
                if (carrera != null)
                  _StatItem(
                      icon: Icons.book,
                      label: 'Carrera',
                      value: '$carrera',
                      color: Colors.deepPurple),
                if (semestre != null)
                  _StatItem(
                      icon: Icons.calendar_today,
                      label: 'Semestre',
                      value: '$semestre',
                      color: Colors.cyan),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConteosCard(Map<String, dynamic> conteos) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics, size: 20, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Actividad',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _StatItem(
                    icon: Icons.fitness_center,
                    label: 'Sesiones',
                    value: '${conteos['sesiones'] ?? 0}',
                    color: Colors.green),
                _StatItem(
                    icon: Icons.list_alt,
                    label: 'Rutinas',
                    value: '${conteos['rutinas'] ?? 0}',
                    color: Colors.blue),
                _StatItem(
                    icon: Icons.emoji_events,
                    label: 'Retos',
                    value: '${conteos['retos'] ?? 0}',
                    color: Colors.amber),
                _StatItem(
                    icon: Icons.military_tech,
                    label: 'Insignias',
                    value: '${conteos['insignias'] ?? 0}',
                    color: Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Actividad reciente (Tarea 3b)
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildSesionesRecientes(List<dynamic> sesiones) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.fitness_center, size: 20, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Últimas sesiones',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...sesiones.take(5).map((s) {
              final fecha = s['completada_en'] as String?;
              final duracion = s['duracion_minutos'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fecha != null ? _formatearFecha(fecha) : '—',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      '${duracion ?? '?'} min',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRetosRecientes(List<dynamic> retos) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emoji_events, size: 20, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Retos completados',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: retos.take(5).map<Widget>((r) {
                return Chip(
                  avatar: const Icon(Icons.check_circle,
                      size: 14, color: Colors.amber),
                  label: Text(
                    r['titulo'] as String? ?? '—',
                    style: const TextStyle(fontSize: 11),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.amber.withValues(alpha: 0.1),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRutinasRecientes(List<dynamic> rutinas) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.list_alt, size: 20, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Rutinas activas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: rutinas.take(5).map<Widget>((r) {
                return Chip(
                  avatar: const Icon(Icons.fitness_center,
                      size: 14, color: Colors.blue),
                  label: Text(
                    r['nombre'] as String? ?? '—',
                    style: const TextStyle(fontSize: 11),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsigniasRecientes(List<dynamic> insignias) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.military_tech, size: 20, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Insignias obtenidas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: insignias.take(5).map<Widget>((ins) {
                final catalogo = ins['insignias'] as Map<String, dynamic>?;
                final nombreInsignia = catalogo?['nombre'] as String? ?? '—';
                final iconoInsignia = catalogo?['icono'] as String?;
                return Chip(
                  avatar: Icon(
                    _iconoDesdeTexto(iconoInsignia),
                    size: 14,
                    color: Colors.purple,
                  ),
                  label: Text(
                    nombreInsignia,
                    style: const TextStyle(fontSize: 11),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.purple.withValues(alpha: 0.1),
                  side: BorderSide.none,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Configuración de usuario (Tarea 3c)
  // ───────────────────────────────────────────────────────────────────────────

  Widget _buildConfiguracionUsuario(
    BuildContext context,
    WidgetRef ref,
    String nombre,
    String email,
    int nivel,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.settings, size: 20, color: Colors.indigo),
                SizedBox(width: 8),
                Text(
                  'Configuración de usuario',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Editar nombre
            _buildConfigField(
              label: 'Nombre completo',
              initialValue: nombre,
              icon: Icons.person,
              hintText: 'Nuevo nombre',
              onSave: (nuevoValor) async {
                await actualizarNombreUsuario(ref, usuarioId, nuevoValor);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nombre actualizado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 10),

            // Editar email
            _buildConfigField(
              label: 'Email',
              initialValue: email,
              icon: Icons.email,
              hintText: 'Nuevo email',
              onSave: (nuevoValor) async {
                if (!nuevoValor.contains('@')) {
                  throw Exception('Email inválido');
                }
                await actualizarEmailUsuario(ref, usuarioId, nuevoValor);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email actualizado'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 10),

            // Cambiar nivel
            Row(
              children: [
                const Icon(Icons.stars_rounded, size: 18, color: Colors.amber),
                const SizedBox(width: 8),
                const Text('Nivel: ',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<int>(
                    initialValue: nivel.clamp(1, 999),
                    isDense: true,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      border: OutlineInputBorder(),
                    ),
                    items: List.generate(
                      15,
                      (i) => nivel - 7 + i,
                    )
                        .where((v) => v >= 1 && v <= 999)
                        .map((v) => DropdownMenuItem(
                              value: v,
                              child: Text('$v',
                                  style: const TextStyle(fontSize: 14)),
                            ))
                        .toList(),
                    onChanged: (val) async {
                      if (val == null) return;
                      try {
                        await cambiarNivelUsuario(ref, usuarioId, val);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Nivel cambiado a $val'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Reset XP
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _confirmarResetXp(context, ref),
                icon: const Icon(Icons.restart_alt,
                    size: 16, color: Colors.orange),
                label: const Text('Reset XP a 0',
                    style: TextStyle(color: Colors.orange)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Campo de configuración con botón de guardar inline.
  Widget _buildConfigField({
    required String label,
    required String initialValue,
    required IconData icon,
    required String hintText,
    required Future<void> Function(String) onSave,
  }) {
    final controller = TextEditingController(text: initialValue);
    bool saving = false;

    return StatefulBuilder(
      builder: (context, setLocalState) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                hintText: hintText,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: FilledButton.tonalIcon(
              onPressed: saving
                  ? null
                  : () async {
                      setLocalState(() => saving = true);
                      try {
                        await onSave(controller.text.trim());
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        setLocalState(() => saving = false);
                      }
                    },
              icon: const Icon(Icons.save, size: 16),
              label: const Text('Guardar', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Diálogos de confirmación
  // ───────────────────────────────────────────────────────────────────────────

  void _confirmarWipe(
    BuildContext context,
    WidgetRef ref,
    String nombre,
  ) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AdminWipeDialog(
        nombreUsuario: nombre,
        usuarioId: usuarioId,
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          final result = await wipeUserData(ref, usuarioId);
          if (context.mounted) {
            final success = result['success'] == true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Wipe completado. ${result['registros_eliminados']} registros eliminados.'
                      : 'Error: ${result['error'] ?? 'Desconocido'}',
                ),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al ejecutar wipe: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    });
  }

  void _confirmarEliminar(
    BuildContext context,
    WidgetRef ref,
    String nombre,
    String email,
  ) {
    final confirmController = TextEditingController();
    bool confirmado = false;

    showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 10),
              Expanded(
                child: Text('Eliminar usuario permanentemente',
                    style: TextStyle(fontSize: 17)),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Vas a eliminar permanentemente a $nombre ($email).\n\n'
                    'Esta acción es IRREVERSIBLE. Se eliminarán:\n'
                    '• Todos los datos personales\n'
                    '• Historial de entrenamiento\n'
                    '• Rutinas, retos e insignias\n'
                    '• Interacciones sociales\n'
                    '• Apuntes y horarios\n\n'
                    'Escribe ELIMINAR para confirmar:',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    decoration: const InputDecoration(
                      labelText: 'ELIMINAR',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit),
                    ),
                    onChanged: (val) => setDialogState(
                        () => confirmado = val.trim() == 'ELIMINAR'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ID: $usuarioId',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: confirmado ? () => Navigator.pop(ctx, true) : null,
              icon: const Icon(Icons.person_remove, size: 18),
              label: const Text('Eliminar usuario'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ).then((confirmed) async {
      confirmController.dispose();
      if (confirmed == true) {
        try {
          final result = await eliminarUsuario(ref, usuarioId);
          if (context.mounted) {
            final success = result['success'] == true;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Usuario ${result['email']} eliminado permanentemente.'
                      : 'Error: ${result['error'] ?? 'Desconocido'}',
                ),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
            if (success && context.mounted) {
              context.go('/admin');
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al eliminar usuario: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    });
  }

  void _confirmarResetXp(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset XP'),
        content: const Text(
            '¿Estás seguro de que quieres resetear el XP de este usuario a 0?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await resetXpUsuario(ref, usuarioId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('XP reseteado a 0'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset XP'),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Helpers
  // ───────────────────────────────────────────────────────────────────────────

  String _formatearFecha(String iso) {
    try {
      final fecha = DateTime.parse(iso);
      final meses = [
        'enero',
        'febrero',
        'marzo',
        'abril',
        'mayo',
        'junio',
        'julio',
        'agosto',
        'septiembre',
        'octubre',
        'noviembre',
        'diciembre',
      ];
      return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
    } catch (_) {
      return iso;
    }
  }

  /// Mapea un nombre de icono textual a un [IconData] de Material Icons.
  IconData _iconoDesdeTexto(String? texto) {
    if (texto == null) return Icons.military_tech;
    switch (texto) {
      case 'star':
        return Icons.star;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'school':
        return Icons.school;
      case 'psychology':
        return Icons.psychology;
      case 'timer':
        return Icons.timer;
      case 'groups':
        return Icons.groups;
      case 'thumb_up':
        return Icons.thumb_up;
      default:
        return Icons.military_tech;
    }
  }

  Widget _avatarFallback(String nombre) {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Text(
        nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Widget reutilizable para mostrar una estadística individual.
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
