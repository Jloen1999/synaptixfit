import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/utils/image_utils.dart';
import '../application/admin_provider.dart';
import 'widgets/admin_graficos_usuario.dart';
import 'widgets/admin_timeline_usuario.dart';
import 'widgets/admin_wipe_dialog.dart';

/// Detalle de usuario — Clean UI profesional con secciones expandibles.
class AdminUsuarioDetalleScreen extends ConsumerWidget {
  final String usuarioId;

  const AdminUsuarioDetalleScreen({required this.usuarioId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalleAsync = ref.watch(adminUsuarioDetalleProvider(usuarioId));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalle de Usuario'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Perfil'),
            Tab(text: 'Estadísticas'),
            Tab(text: 'Timeline'),
          ]),
        ),
        body: detalleAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text('Error: $err'),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                onPressed: () =>
                    ref.invalidate(adminUsuarioDetalleProvider(usuarioId)),
              ),
            ]),
          ),
          data: (data) => _buildTabContent(context, ref, data),
        ),
      ),
    );
  }

  Widget _buildTabContent(
      BuildContext context, WidgetRef ref, Map<String, dynamic> data) {
    return TabBarView(children: [
      _buildPerfilTab(context, ref, data),
      AdminGraficosUsuario(usuarioId: usuarioId),
      AdminTimelineUsuario(usuarioId: usuarioId),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Pestaña Perfil
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildPerfilTab(
      BuildContext context, WidgetRef ref, Map<String, dynamic> data) {
    final nombre = data['nombre_completo'] as String? ?? '—';
    final email = data['email'] as String? ?? '—';
    final avatar = data['url_avatar'] as String?;
    final rol = (data['rol'] as String?) ?? 'usuario';
    final nivel = (data['nivel'] as num?)?.toInt() ?? 1;
    final xpTotal = (data['xp_total'] as num?)?.toInt() ?? 0;
    final racha = (data['racha_actual'] as num?)?.toInt() ?? 0;
    final isShadowbanned = data['is_shadowbanned'] == true;
    final creadoEn = data['creado_en'] as String?;

    final bienestarData = data['perfil_bienestar_usuario'];
    final bienestar =
        bienestarData is Map ? bienestarData.cast<String, dynamic>() : null;
    final academicoData = data['perfil_academico_usuario'];
    final academico =
        academicoData is Map ? academicoData.cast<String, dynamic>() : null;
    final conteos = data['_conteos'] as Map<String, dynamic>? ?? {};

    final sesiones = (data['_sesiones_recientes'] as List<dynamic>?) ?? [];
    final retos = (data['_retos_recientes'] as List<dynamic>?) ?? [];
    final rutinas = (data['_rutinas_recientes'] as List<dynamic>?) ?? [];
    final insignias = (data['_insignias_recientes'] as List<dynamic>?) ?? [];

    final cs = Theme.of(context).colorScheme;
    final rolColor = rol == 'admin' ? Colors.amber.shade700 : Colors.blueGrey;
    final carrera = academico?['carrera'] as String?;
    final universidad = academico?['universidad'] as String?;
    final adherencia = data['_adherencia'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(nombre, email, avatar, rol, rolColor, carrera,
              universidad, creadoEn, cs),
          const SizedBox(height: 12),
          _buildMetricas(
              nivel, xpTotal, racha, bienestar, academico, adherencia, cs),
          const SizedBox(height: 12),
          _buildConteos(conteos, cs),
          if (sesiones.isNotEmpty ||
              retos.isNotEmpty ||
              rutinas.isNotEmpty ||
              insignias.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildActividad(sesiones, retos, rutinas, insignias, cs),
          ],
          const SizedBox(height: 12),
          _buildShadowbanToggle(context, ref, isShadowbanned),
          const SizedBox(height: 12),
          _buildExpansionConfiguracion(context, ref, nombre, email, nivel),
          const SizedBox(height: 12),
          _buildAdministracion(context, ref, nombre, email),
          const SizedBox(height: 8),
          Center(
            child: Text('ID: $usuarioId',
                style: TextStyle(
                    fontSize: 10,
                    color: cs.onSurface.withValues(alpha: 0.3),
                    fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Header — avatar + nombre + email + carrera + chip rol
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildHeader(
      String nombre,
      String email,
      String? avatar,
      String rol,
      Color rolColor,
      String? carrera,
      String? universidad,
      String? creadoEn,
      ColorScheme cs) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          ClipOval(
            child: SizedBox(
              width: 56,
              height: 56,
              child: avatar != null && avatar.isNotEmpty
                  ? Image.network(normalizarUrlAvatar(avatar),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarFallback(nombre, 24))
                  : _avatarFallback(nombre, 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(nombre,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(email,
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5)),
                    overflow: TextOverflow.ellipsis),
                if (carrera != null && carrera.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.school, size: 13, color: Colors.indigo.shade300),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                          universidad != null && universidad.isNotEmpty
                              ? '$carrera · $universidad'
                              : carrera,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.indigo.shade400),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ],
                if (creadoEn != null)
                  Text('Miembro desde ${_formatearFecha(creadoEn)}',
                      style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurface.withValues(alpha: 0.35))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: rolColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(rol.toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: rolColor,
                    letterSpacing: 0.5)),
          ),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Métricas unificadas
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildMetricas(
      int nivel,
      int xpTotal,
      int racha,
      Map<String, dynamic>? bienestar,
      Map<String, dynamic>? academico,
      Map<String, dynamic> adherencia,
      ColorScheme cs) {
    final stats = <Widget>[
      _miniStat('Nivel', '$nivel', Icons.stars_rounded, Colors.amber, cs),
      _miniStat('XP', _fmtCompacto(xpTotal), Icons.emoji_events_outlined,
          Colors.purple, cs),
      _miniStat('Racha', '$racha', Icons.local_fire_department_rounded,
          Colors.deepOrange, cs),
    ];
    if (bienestar != null && bienestar['peso_kg'] != null) {
      stats.add(_miniStat('Peso', '${bienestar['peso_kg']} kg',
          Icons.monitor_weight_outlined, Colors.teal, cs));
    }
    if (bienestar != null && bienestar['altura_cm'] != null) {
      final imc = bienestar['imc'];
      stats.add(_miniStat(
          'Altura',
          '${bienestar['altura_cm']} cm${imc != null ? ' · IMC ${(imc as num).toStringAsFixed(1)}' : ''}',
          Icons.height,
          Colors.blue,
          cs));
    }
    if (bienestar != null && bienestar['objetivo_principal'] != null) {
      stats.add(_miniStat('Objetivo', '${bienestar['objetivo_principal']}',
          Icons.flag_outlined, Colors.orange, cs));
    }
    if (bienestar != null && bienestar['nivel_actividad'] != null) {
      stats.add(_miniStat('Actividad', '${bienestar['nivel_actividad']}',
          Icons.directions_run, Colors.green, cs));
    }
    if (bienestar != null && bienestar['edad'] != null) {
      stats.add(_miniStat(
          'Edad', '${bienestar['edad']}', Icons.cake, Colors.pink, cs));
    }
    if (academico != null && academico['semestre_actual'] != null) {
      stats.add(_miniStat('Semestre', '${academico['semestre_actual']}',
          Icons.calendar_today, Colors.cyan, cs));
    }
    if (academico != null && academico['creditos_semestre_actual'] != null) {
      stats.add(_miniStat(
          'Créditos',
          '${academico['creditos_semestre_actual']}',
          Icons.credit_score,
          Colors.indigo,
          cs));
    }
    if (adherencia['porcentaje'] != null) {
      stats.add(_miniStat('Adherencia', '${adherencia['porcentaje']}%',
          Icons.trending_up, Colors.teal, cs));
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Wrap(
          spacing: 2,
          runSpacing: 8,
          alignment: WrapAlignment.spaceAround,
          children: stats,
        ),
      ),
    );
  }

  Widget _miniStat(
      String label, String value, IconData icon, Color color, ColorScheme cs) {
    return SizedBox(
      width: 78,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 17, color: color.withValues(alpha: 0.7)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface)),
        ),
        Text(label,
            style: TextStyle(
                fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4))),
      ]),
    );
  }

  String _fmtCompacto(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Conteos
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildConteos(Map<String, dynamic> conteos, ColorScheme cs) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Row(children: [
          _chipConteo(Icons.fitness_center, 'Sesiones',
              '${conteos['sesiones'] ?? 0}', Colors.green, cs),
          _chipConteo(Icons.list_alt, 'Rutinas', '${conteos['rutinas'] ?? 0}',
              Colors.blue, cs),
          _chipConteo(Icons.emoji_events, 'Retos', '${conteos['retos'] ?? 0}',
              Colors.amber, cs),
          _chipConteo(Icons.military_tech, 'Insignias',
              '${conteos['insignias'] ?? 0}', Colors.purple, cs),
        ]),
      ),
    );
  }

  Widget _chipConteo(
      IconData icon, String label, String count, Color color, ColorScheme cs) {
    return Expanded(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: color.withValues(alpha: 0.6)),
        const SizedBox(height: 2),
        Text(count,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: cs.onSurface)),
        Text(label,
            style: TextStyle(
                fontSize: 10, color: cs.onSurface.withValues(alpha: 0.4))),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Actividad reciente (EXPANDIBLE)
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildActividad(List<dynamic> sesiones, List<dynamic> retos,
      List<dynamic> rutinas, List<dynamic> insignias, ColorScheme cs) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        shape: Border(top: BorderSide.none),
        collapsedShape: Border(top: BorderSide.none),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        leading: Icon(Icons.history_rounded,
            size: 18, color: cs.onSurface.withValues(alpha: 0.5)),
        title: Text('Actividad reciente',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface)),
        children: [
          if (sesiones.isNotEmpty)
            _filaAct(
                'Sesiones',
                sesiones.take(4).toList(),
                cs,
                (s) =>
                    '${_fechaCorta(s['completada_en'])} · ${s['duracion_minutos'] ?? '?'} min'),
          if (retos.isNotEmpty)
            _chipsAct('Retos', retos.take(4).toList(), cs, Colors.amber,
                (r) => r['titulo']?.toString() ?? '-'),
          if (rutinas.isNotEmpty)
            _chipsAct('Rutinas', rutinas.take(4).toList(), cs, Colors.blue,
                (r) => r['nombre']?.toString() ?? '-'),
          if (insignias.isNotEmpty)
            _filaInsignias(insignias.take(4).toList(), cs),
        ],
      ),
    );
  }

  Widget _filaAct(String titulo, List<dynamic> items, ColorScheme cs,
      String Function(dynamic) labelFor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 56,
            child: Text(titulo,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.5)))),
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 2,
            children: items
                .map((s) => Chip(
                      label: Text(labelFor(s),
                          style: const TextStyle(fontSize: 10)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      side: BorderSide.none,
                      backgroundColor:
                          cs.surfaceContainerHighest.withValues(alpha: 0.3),
                    ))
                .toList(),
          ),
        ),
      ]),
    );
  }

  Widget _chipsAct(String titulo, List<dynamic> items, ColorScheme cs,
      Color color, String Function(dynamic) labelFor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 56,
            child: Text(titulo,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.5)))),
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 2,
            children: items
                .map((r) => Chip(
                      label: Text(labelFor(r),
                          style: const TextStyle(fontSize: 10)),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      side: BorderSide.none,
                      backgroundColor: color.withValues(alpha: 0.08),
                    ))
                .toList(),
          ),
        ),
      ]),
    );
  }

  Widget _filaInsignias(List<dynamic> items, ColorScheme cs) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
          width: 56,
          child: Text('Insignias',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.5)))),
      Expanded(
        child: Wrap(
          spacing: 4,
          runSpacing: 2,
          children: items.map<Widget>((ins) {
            final c = ins['insignias'] as Map<String, dynamic>?;
            return Chip(
              avatar: Icon(_iconoDesdeTexto(c?['icono'] as String?),
                  size: 12, color: Colors.purple.shade300),
              label: Text(c?['nombre'] ?? '-',
                  style: const TextStyle(fontSize: 10)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              side: BorderSide.none,
              backgroundColor: Colors.purple.withValues(alpha: 0.06),
            );
          }).toList(),
        ),
      ),
    ]);
  }

  String _fechaCorta(dynamic iso) {
    if (iso == null) return '—';
    try {
      final f = DateTime.parse(iso.toString());
      return '${f.day}/${f.month}';
    } catch (_) {
      return iso.toString();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Shadowban toggle
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildShadowbanToggle(
      BuildContext context, WidgetRef ref, bool isShadowbanned) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: isShadowbanned
                ? const Color(0xFF7B2D8E).withValues(alpha: 0.5)
                : Colors.grey.shade300),
      ),
      color: isShadowbanned
          ? const Color(0xFF7B2D8E).withValues(alpha: 0.03)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Icon(Icons.visibility_off_rounded,
              size: 18,
              color: isShadowbanned
                  ? const Color(0xFF7B2D8E)
                  : Colors.grey.shade500),
          const SizedBox(width: 10),
          const Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Shadowban',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text('Content visible solo para el autor. La comunidad no lo ve.',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            ]),
          ),
          Switch(
            value: isShadowbanned,
            activeColor: const Color(0xFF7B2D8E),
            onChanged: (val) async {
              await toggleShadowbanUsuario(ref, usuarioId, val);
              if (context.mounted)
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        val ? 'Shadowban activado' : 'Shadowban desactivado'),
                    backgroundColor:
                        val ? const Color(0xFF7B2D8E) : Colors.green));
            },
          ),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Configuración (EXPANDIBLE)
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildExpansionConfiguracion(BuildContext context, WidgetRef ref,
      String nombre, String email, int nivel) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.3)),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        shape: Border(top: BorderSide.none),
        collapsedShape: Border(top: BorderSide.none),
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        leading: const Icon(Icons.settings, size: 18, color: Colors.grey),
        title: const Text('Configuración',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        children: [
          _buildEditField('Nombre', nombre, Icons.person, (v) async {
            await actualizarNombreUsuario(ref, usuarioId, v);
            if (context.mounted)
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Nombre actualizado'),
                  backgroundColor: Colors.green));
          }),
          const SizedBox(height: 8),
          _buildEditField('Email', email, Icons.email, (v) async {
            if (!v.contains('@')) throw Exception('Email inválido');
            await actualizarEmailUsuario(ref, usuarioId, v);
            if (context.mounted)
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Email actualizado'),
                  backgroundColor: Colors.green));
          }),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.stars_rounded, size: 17, color: Colors.amber),
            const SizedBox(width: 8),
            const Text('Nivel:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            SizedBox(
              width: 90,
              child: DropdownButtonFormField<int>(
                initialValue: nivel.clamp(1, 999),
                isDense: true,
                decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    border: OutlineInputBorder()),
                items: List.generate(15, (i) => nivel - 7 + i)
                    .where((v) => v >= 1 && v <= 999)
                    .map((v) => DropdownMenuItem(
                        value: v,
                        child:
                            Text('$v', style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) async {
                  if (val == null) return;
                  await cambiarNivelUsuario(ref, usuarioId, val);
                  if (context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Nivel cambiado a $val'),
                        backgroundColor: Colors.green));
                },
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => _confirmarResetXp(context, ref),
              icon: const Icon(Icons.restart_alt, size: 15),
              label: const Text('Reset XP', style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildEditField(String label, String initialValue, IconData icon,
      Future<void> Function(String) onSave) {
    final controller = TextEditingController(text: initialValue);
    bool saving = false;
    return StatefulBuilder(
      builder: (ctx, setState) => Row(children: [
        Icon(icon, size: 15, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          height: 34,
          child: FilledButton.tonal(
            onPressed: saving
                ? null
                : () async {
                    setState(() => saving = true);
                    try {
                      await onSave(controller.text.trim());
                    } catch (e) {
                      if (ctx.mounted)
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red));
                    } finally {
                      setState(() => saving = false);
                    }
                  },
            child: const Icon(Icons.save, size: 16),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GDPR (EXPANDIBLE)
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildAdministracion(
      BuildContext context, WidgetRef ref, String nombre, String email) {
    const azul = Color(0xFF0D3B66);
    const rojo = Color(0xFFC0392B);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: rojo, width: 1.5),
      ),
      color: rojo.withValues(alpha: 0.03),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // ── Encabezado con ícono ──
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Row(children: [
            const Icon(Icons.admin_panel_settings, size: 20, color: rojo),
            const SizedBox(width: 8),
            Text('Administración',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface)),
          ]),
        ),
        const Divider(height: 20, thickness: 1, endIndent: 14, indent: 14),
        // ── GDPR ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(children: [
            const Icon(Icons.shield_rounded, size: 16, color: azul),
            const SizedBox(width: 8),
            Text('Cumplimiento RGPD',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: azul)),
          ]),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmarExportar(context, ref, nombre, email),
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Exportar datos (JSON)',
                  style: TextStyle(fontSize: 11)),
              style: OutlinedButton.styleFrom(
                foregroundColor: azul,
                side: const BorderSide(color: azul),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  _confirmarAnonimizar(context, ref, nombre, email),
              icon: const Icon(Icons.auto_delete_rounded, size: 16),
              label: const Text('Anonimizar (RGPD)',
                  style: TextStyle(fontSize: 11)),
              style: FilledButton.styleFrom(
                backgroundColor: azul,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
          child: Text(
            'Preserva métricas anónimas. Destruye identidad, perfiles, contenido social y auth.',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ),
        const Divider(height: 20, thickness: 1, endIndent: 14, indent: 14),
        // ── Peligro ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(children: [
            const Icon(Icons.dangerous_outlined, size: 16, color: rojo),
            const SizedBox(width: 8),
            Text('Acciones destructivas',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: rojo)),
          ]),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _confirmarWipe(context, ref, nombre),
              icon: const Icon(Icons.delete_forever, size: 16),
              label:
                  const Text('Wipe de datos', style: TextStyle(fontSize: 11)),
              style: FilledButton.styleFrom(
                backgroundColor: rojo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
          child: Text(
            'Resetea historial, nivel → 1, XP → 0, racha → 0. Conserva perfiles.',
            style: TextStyle(fontSize: 10, color: Colors.red.shade300),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _confirmarEliminar(context, ref, nombre, email),
              icon: const Icon(Icons.person_remove, size: 16, color: rojo),
              label: const Text('Eliminar usuario',
                  style: TextStyle(fontSize: 11, color: rojo)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: rojo),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
          child: Text(
            'Borra identidad, datos personales y cuenta de auth. IRREVERSIBLE.',
            style: TextStyle(fontSize: 10, color: Colors.red.shade300),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Diálogos de confirmación
  // ═══════════════════════════════════════════════════════════════════════

  void _confirmarWipe(BuildContext context, WidgetRef ref, String nombre) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFC0392B)),
          SizedBox(width: 10),
          Text('Wipe de datos — IRREVERSIBLE', style: TextStyle(fontSize: 17)),
        ]),
        content: Text(
            'Eliminarás todo el historial de $nombre conservando sus perfiles.\n\n'
            'Eliminado: sesiones, rutinas, retos, racha, historial de peso, carga académica.\n'
            'Reseteado: nivel → 1, XP → 0, racha → 0.\n'
            'Conservado: perfil de bienestar, perfil académico, asignaturas, cuenta.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_forever, size: 18),
            label: const Text('Ejecutar Wipe'),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC0392B)),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        final result = await wipeUserData(ref, usuarioId);
        if (context.mounted) {
          final ok = result['success'] == true;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ok
                ? 'Wipe completado. ${result['registros_eliminados']} registros eliminados.'
                : 'Error: ${result['error'] ?? 'Desconocido'}'),
            backgroundColor: ok ? Colors.green : Colors.red,
          ));
        }
      }
    });
  }

  void _confirmarEliminar(
      BuildContext context, WidgetRef ref, String nombre, String email) {
    final ctrl = TextEditingController();
    bool ok = false;
    showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFC0392B)),
            SizedBox(width: 10),
            Expanded(
                child: Text('Eliminar usuario — IRREVERSIBLE',
                    style: TextStyle(fontSize: 17))),
          ]),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                        'Vas a eliminar a $nombre ($email). Todo desaparece incluyendo auth.users.\n\n'
                        'Escribe ELIMINAR para confirmar:',
                        style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: ctrl,
                      decoration: const InputDecoration(
                          labelText: 'ELIMINAR', border: OutlineInputBorder()),
                      onChanged: (v) => setD(() => ok = v.trim() == 'ELIMINAR'),
                    ),
                    const SizedBox(height: 4),
                    Text('ID: $usuarioId',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade400,
                            fontFamily: 'monospace')),
                  ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            FilledButton.icon(
              onPressed: ok ? () => Navigator.pop(ctx, true) : null,
              icon: const Icon(Icons.person_remove, size: 18),
              label: const Text('Eliminar usuario'),
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFC0392B),
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    ).then((confirmed) async {
      ctrl.dispose();
      if (confirmed == true) {
        final result = await eliminarUsuario(ref, usuarioId);
        if (context.mounted) {
          final ok = result['success'] == true;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ok
                ? 'Usuario ${result['email']} eliminado.'
                : 'Error: ${result['error'] ?? 'Desconocido'}'),
            backgroundColor: ok ? Colors.green : Colors.red,
          ));
          if (ok && context.mounted) context.go('/admin');
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
            '¿Poner el XP de este usuario a 0? Pierde nivel si aplica.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await resetXpUsuario(ref, usuarioId);
              if (context.mounted)
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('XP reseteado'),
                    backgroundColor: Colors.green));
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset XP'),
          ),
        ],
      ),
    );
  }

  void _confirmarExportar(
      BuildContext context, WidgetRef ref, String nombre, String email) {
    showDialog(
      context: context,
      builder: (ctx) =>
          _ExportarDialog(usuarioId: usuarioId, nombre: nombre, email: email),
    );
  }

  void _mostrarJson(
      BuildContext context, String nombre, String email, String jsonStr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.data_object_rounded, size: 20),
          SizedBox(width: 8),
          Text('Datos exportados', style: TextStyle(fontSize: 17)),
        ]),
        content: SizedBox(
          width: 600,
          height: 500,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('$nombre ($email)',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(
                '${jsonStr.length} caracteres · ${jsonStr.split('\n').length} líneas',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300)),
                child: SelectableText(jsonStr,
                    style: const TextStyle(
                        fontSize: 11, fontFamily: 'monospace', height: 1.4)),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cerrar')),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('JSON copiado al portapapeles'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2)));
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copiar JSON'),
          ),
        ],
      ),
    );
  }

  void _confirmarAnonimizar(
      BuildContext context, WidgetRef ref, String nombre, String email) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFF0D3B66)),
          SizedBox(width: 10),
          Text('Anonimizar (RGPD)', style: TextStyle(fontSize: 17)),
        ]),
        content: Text('Anonimizarás permanentemente a $nombre ($email).\n\n'
            'Fase 1 — ANONIMIZAR: las métricas agregadas (sesiones, carga académica, '
            'gasto calórico) se preservan bajo un UUID anónimo para Business Intelligence.\n\n'
            'Fase 2 — ELIMINAR: se destruyen datos personales, perfiles, contenido social, '
            'rutinas y retos.\n\n'
            'Fase 3: se elimina la cuenta de usuarios y auth.users.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.shield_rounded, size: 18),
            label: const Text('Anonimizar'),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0D3B66)),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        final result = await anonimizarUsuario(ref, usuarioId);
        if (context.mounted) {
          final ok = result['success'] == true;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(ok
                ? 'Usuario ${result['email']} anonimizado. ${result['anonimizados']} registros preservados.'
                : 'Error: ${result['error'] ?? ''}'),
            backgroundColor: ok ? Colors.green : Colors.red,
            duration: const Duration(seconds: 4),
          ));
          if (ok && context.mounted) context.go('/admin');
        }
      }
    });
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════════

  String _formatearFecha(String iso) {
    try {
      final f = DateTime.parse(iso);
      const m = [
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
        'diciembre'
      ];
      return '${f.day} de ${m[f.month - 1]} de ${f.year}';
    } catch (_) {
      return iso;
    }
  }

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

  Widget _avatarFallback(String nombre, [double fs = 32]) {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
          style: TextStyle(fontSize: fs, fontWeight: FontWeight.w700)),
    );
  }
}

/// Dialogo de exportación con estado de carga y manejo de errores.
class _ExportarDialog extends ConsumerStatefulWidget {
  final String usuarioId;
  final String nombre;
  final String email;

  const _ExportarDialog(
      {required this.usuarioId,
      required this.nombre,
      required this.email,
      super.key});

  @override
  ConsumerState<_ExportarDialog> createState() => _ExportarDialogState();
}

class _ExportarDialogState extends ConsumerState<_ExportarDialog> {
  bool _cargando = false;
  String? _error;
  String? _jsonStr;

  Future<void> _exportar() async {
    setState(() {
      _cargando = true;
      _error = null;
      _jsonStr = null;
    });
    try {
      final result = await exportarDatosUsuario(ref, widget.usuarioId);
      if (!mounted) return;
      if (result['success'] != true) {
        setState(() {
          _cargando = false;
          _error = 'Error: ${result['error'] ?? 'Desconocido'}';
        });
        return;
      }
      setState(() {
        _cargando = false;
        _jsonStr = const JsonEncoder.withIndent('  ').convert(result['datos']);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_jsonStr != null) {
      return AlertDialog(
        title: const Text('Datos exportados', style: TextStyle(fontSize: 17)),
        content: SizedBox(
          width: 600,
          height: 500,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('${widget.nombre} (${widget.email})',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(
                '${_jsonStr!.length} car. · ${_jsonStr!.split('\n').length} líneas',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300)),
                child: SelectableText(_jsonStr!,
                    style: const TextStyle(
                        fontSize: 11, fontFamily: 'monospace', height: 1.4)),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar')),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _jsonStr!));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('JSON copiado'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2)));
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copiar JSON'),
          ),
        ],
      );
    }

    return AlertDialog(
      title:
          const Text('Exportar datos (GDPR)', style: TextStyle(fontSize: 17)),
      content: _error != null
          ? Text(_error!,
              style: const TextStyle(color: Colors.red, fontSize: 13))
          : Text('Generarás un JSON completo de ${widget.nombre}.\n'
              'Incluye perfil, métricas, sesiones, carga académica, rutinas, retos y más.'),
      actions: [
        TextButton(
            onPressed: _cargando ? null : () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton.icon(
          onPressed: _cargando ? null : _exportar,
          icon: _cargando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.download, size: 18),
          label: Text(_cargando ? 'Exportando...' : 'Exportar'),
        ),
      ],
    );
  }
}
