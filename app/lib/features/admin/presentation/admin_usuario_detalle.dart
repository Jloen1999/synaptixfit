import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/admin_provider.dart';
import 'widgets/admin_wipe_dialog.dart';

/// Pantalla de detalle de un usuario desde el panel de administración.
///
/// Muestra datos de perfil, bienestar, académico y conteos de actividad,
/// junto con un botón de wipe de datos.
class AdminUsuarioDetalleScreen extends ConsumerWidget {
  final String usuarioId;

  const AdminUsuarioDetalleScreen({
    required this.usuarioId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalleAsync = ref.watch(adminUsuarioDetalleProvider(usuarioId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Usuario'),
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
        data: (data) => _buildContent(context, ref, data),
      ),
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
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: avatar != null && avatar.isNotEmpty
                  ? NetworkImage(avatar)
                  : null,
              child: avatar == null || avatar.isEmpty
                  ? Text(
                      nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
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
