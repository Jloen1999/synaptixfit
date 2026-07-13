import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/design_system/sv_colors.dart';
import '../../../core/design_system/sv_shapes.dart';
import '../../../core/design_system/sv_typography.dart';
import '../../../features/perfil/application/perfil_provider.dart';
import '../../../shared/models/db_models.dart';
import '../application/asignaturas_provider.dart';
import '../application/catalogo_provider.dart';
import '../infrastructure/ics_sync_service.dart';
import 'widgets/asignatura_card.dart';
import 'widgets/escanear_horario_boton.dart';

class AcademicScreen extends ConsumerWidget {
  const AcademicScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asignaturasAsync = ref.watch(asignaturasActivasProvider);
    final perfilAsync = ref.watch(perfilAcademicoProvider);
    final p = perfilAsync.valueOrNull;
    final activas = asignaturasAsync.valueOrNull ?? [];
    final carreraDataAsync = ref.watch(carreraConAsignaturasProvider);
    final carreraData = carreraDataAsync.valueOrNull ?? [];

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
      if (cat?.curso != null)
        cursoCount[cat!.curso!] = (cursoCount[cat.curso!] ?? 0) + 1;
    }
    final cursosOrdenados = cursoCount.keys.toList()..sort();

    return Scaffold(
      backgroundColor: SVColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              onPlanSemanal: () => context.push('/academico/planificar'),
              onAjustes: () => _mostrarCentroDeControl(context, ref),
            ),
            if (p != null)
              _SemestreBar(
                  p: p,
                  cursosOrdenados: cursosOrdenados,
                  cursoCount: cursoCount),
            _IcsRow(ref: ref),
            const EscanearHorarioBoton(),
            const SizedBox(height: 4),
            Expanded(
              child: asignaturasAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => _MensajeCentral(
                    icono: Icons.error_outline,
                    titulo: 'No se pudieron cargar las asignaturas',
                    subtitulo: '$err'),
                data: (asignaturas) {
                  if (asignaturas.isEmpty) {
                    return const _MensajeCentral(
                        icono: Icons.menu_book_outlined,
                        titulo: 'Aún no tienes asignaturas',
                        subtitulo:
                            'Usa el botón de ajustes para configurar tu semestre y añadir asignaturas.');
                  }
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(asignaturasActivasProvider);
                      await ref.read(asignaturasActivasProvider.future);
                    },
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.55),
                      itemCount: asignaturas.length,
                      itemBuilder: (context, index) {
                        final a = asignaturas[index];
                        return AsignaturaCard(
                            asignatura: a,
                            onTap: () => context.push(
                                '/academico/asignatura/${a.id}',
                                extra: a));
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SemestreBar extends StatelessWidget {
  const _SemestreBar(
      {required this.p,
      required this.cursosOrdenados,
      required this.cursoCount});
  final PerfilAcademicoDb p;
  final List<int> cursosOrdenados;
  final Map<int, int> cursoCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: SVColors.primary.withValues(alpha: 0.08),
                borderRadius: SVShapes.pill),
            child: Text('${p.semestreEnCurso}° Semestre',
                style: const TextStyle(
                    color: SVColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
          if (p.carrera != null && p.carrera!.isNotEmpty) ...[
            const SizedBox(width: 8),
            Flexible(
                child: Text(p.carrera!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: SVColors.onSurfaceMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500))),
          ],
          if (cursosOrdenados.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        ...cursosOrdenados.map((c) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                    color: SVColors.surfaceContainer,
                                    borderRadius: SVShapes.pill),
                                child: Text(
                                    '${c}° Curso · ${cursoCount[c]} asig.',
                                    style: const TextStyle(
                                        color: SVColors.onSurfaceVariant,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600)),
                              ),
                            )),
                        const SizedBox(width: 20),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        width: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            colors: [
                              SVColors.background,
                              SVColors.background.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _IcsRow extends ConsumerStatefulWidget {
  const _IcsRow({required this.ref});
  final WidgetRef ref;
  @override
  ConsumerState<_IcsRow> createState() => _IcsRowState();
}

class _IcsRowState extends ConsumerState<_IcsRow> {
  final _ctrl = TextEditingController();
  bool _sincronizando = false;
  String? _result;
  String? _error;

  Future<void> _sync() async {
    final url = _ctrl.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Ingresa la URL');
      return;
    }
    setState(() {
      _sincronizando = true;
      _error = null;
      _result = null;
    });
    try {
      final service = ref.read(icsSyncServiceProvider);
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final r = await service.sincronizar(
          asignaturaId: user.id,
          asignaturaNombre: 'Calendario',
          asignaturaCodigo: 'ICS',
          icsUrl: url);
      if (r.exitoso) {
        setState(() => _result =
            '${r.examenes} exámenes · ${r.entregas} entregas · ${r.clases} clases');
        ref.invalidate(asignaturasActivasProvider);
      } else {
        setState(() => _error = r.error ?? 'Error al sincronizar');
      }
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _sincronizando = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
      child: Row(children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                isCollapsed: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                border: OutlineInputBorder(
                    borderRadius: SVShapes.standard,
                    borderSide: BorderSide(color: SVColors.outlineVariant)),
                hintText: 'URL del calendario (.ics)',
                hintStyle: TextStyle(color: SVColors.outline, fontSize: 12),
                prefixIcon: Icon(Icons.calendar_today_outlined,
                    size: 16, color: SVColors.outline),
                prefixIconConstraints: BoxConstraints(minWidth: 32),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          height: 36,
          child: FilledButton.icon(
            onPressed: _sincronizando ? null : _sync,
            icon: _sincronizando
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: SVColors.onPrimary))
                : const Icon(Icons.sync, size: 16),
            label: const Text('Sinc', style: TextStyle(fontSize: 12)),
            style: FilledButton.styleFrom(
                elevation: 0,
                backgroundColor: SVColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: const RoundedRectangleBorder(
                    borderRadius: SVShapes.standard)),
          ),
        ),
        if (_result != null || _error != null) ...[
          const SizedBox(width: 6),
          Flexible(
              child: Text(_result ?? _error ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _error != null
                          ? SVColors.error
                          : const Color(0xFF2E7D32)))),
        ],
      ]),
    );
  }
}

void _mostrarCentroDeControl(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: SVColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => _CentroDeControlSheet(ref: ref),
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.onPlanSemanal, required this.onAjustes});
  final VoidCallback onPlanSemanal, onAjustes;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 10),
      child: Row(children: [
        Expanded(
            child: Text('Académico',
                style: SVTypography.headlineMedium.copyWith(
                    color: SVColors.onSurface,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5))),
        Material(
            color: SVColors.surfaceContainerLow,
            borderRadius: SVShapes.standard12,
            child: InkWell(
                borderRadius: SVShapes.standard12,
                onTap: onAjustes,
                child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.settings_outlined,
                        color: SVColors.onSurfaceVariant, size: 22)))),
        const SizedBox(width: 8),
        Material(
            color: SVColors.surfaceContainerLow,
            borderRadius: SVShapes.standard12,
            child: InkWell(
                borderRadius: SVShapes.standard12,
                onTap: onPlanSemanal,
                child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.calendar_month_outlined,
                        color: SVColors.onSurfaceVariant, size: 22)))),
      ]),
    );
  }
}

class _CentroDeControlSheet extends ConsumerStatefulWidget {
  const _CentroDeControlSheet({required this.ref});
  final WidgetRef ref;
  @override
  ConsumerState<_CentroDeControlSheet> createState() =>
      _CentroDeControlSheetState();
}

class _CentroDeControlSheetState extends ConsumerState<_CentroDeControlSheet> {
  final _inicioCtrl = TextEditingController(),
      _finCtrl = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final perfil = ref.read(perfilAcademicoProvider).valueOrNull;
    if (perfil?.fechaInicioClases != null)
      _inicioCtrl.text =
          DateFormat('dd/MM/yyyy').format(perfil!.fechaInicioClases!);
    if (perfil?.fechaFinClases != null)
      _finCtrl.text = DateFormat('dd/MM/yyyy').format(perfil!.fechaFinClases!);
  }

  Future<void> _pickFecha(TextEditingController c) async {
    final f = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        locale: const Locale('es'));
    if (f != null) c.text = DateFormat('dd/MM/yyyy').format(f);
  }

  Future<void> _guardarFechas() async {
    final c = Supabase.instance.client;
    final u = c.auth.currentUser;
    if (u == null) return;
    final ini = DateFormat('dd/MM/yyyy').tryParse(_inicioCtrl.text);
    final fin = DateFormat('dd/MM/yyyy').tryParse(_finCtrl.text);
    final ex = await c
        .from('perfil_academico_usuario')
        .select('id')
        .eq('usuario_id', u.id)
        .maybeSingle();
    if (ex != null) {
      await c.from('perfil_academico_usuario').update({
        if (ini != null)
          'fecha_inicio_clases': ini.toIso8601String().substring(0, 10),
        if (fin != null)
          'fecha_fin_clases': fin.toIso8601String().substring(0, 10),
      }).eq('usuario_id', u.id);
    }
    ref.invalidate(perfilAcademicoProvider);
  }

  Future<void> _selSemestre(int a) async {
    final ops = List.generate(12, (i) => i + 1);
    final s = await showDialog<int>(
        context: context,
        builder: (ctx) => SimpleDialog(
            title: const Text('Semestre'),
            children: ops
                .map((s) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, s),
                    child: Text('$s° Semestre',
                        style: TextStyle(
                            fontWeight:
                                s == a ? FontWeight.w800 : FontWeight.w400))))
                .toList()));
    if (s == null) return;
    final c = Supabase.instance.client;
    final u = c.auth.currentUser;
    if (u == null) return;
    final ex = await c
        .from('perfil_academico_usuario')
        .select('id')
        .eq('usuario_id', u.id)
        .maybeSingle();
    if (ex != null)
      await c
          .from('perfil_academico_usuario')
          .update({'semestre_actual': s}).eq('usuario_id', u.id);
    ref.invalidate(perfilAcademicoProvider);
  }

  Future<void> _selUni() async {
    final unis = ref.read(universidadesProvider).valueOrNull ?? [];
    if (unis.isEmpty) return;
    final uni = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
            title: const Text('Universidad'),
            children: unis
                .map((u) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, u.id),
                    child: Text(u.nombre)))
                .toList()));
    if (uni == null) return;
    final c = Supabase.instance.client;
    final u = c.auth.currentUser;
    if (u == null) return;
    final ex = await c
        .from('perfil_academico_usuario')
        .select('id')
        .eq('usuario_id', u.id)
        .maybeSingle();
    if (ex != null)
      await c
          .from('perfil_academico_usuario')
          .update({'universidad': uni}).eq('usuario_id', u.id);
    ref.invalidate(perfilAcademicoProvider);
    setState(() {});
  }

  Future<void> _selCarrera(String uniId) async {
    final carrs =
        ref.read(carrerasPorUniversidadProvider(uniId)).valueOrNull ?? [];
    if (carrs.isEmpty) return;
    final carr = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
            title: const Text('Carrera'),
            children: carrs
                .map((c) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, c.nombre),
                    child: Text(c.nombre)))
                .toList()));
    if (carr == null) return;
    final cl = Supabase.instance.client;
    final u = cl.auth.currentUser;
    if (u == null) return;
    final ex = await cl
        .from('perfil_academico_usuario')
        .select('id')
        .eq('usuario_id', u.id)
        .maybeSingle();
    if (ex != null)
      await cl
          .from('perfil_academico_usuario')
          .update({'carrera': carr}).eq('usuario_id', u.id);
    ref.invalidate(perfilAcademicoProvider);
    setState(() {});
  }

  @override
  void dispose() {
    _inicioCtrl.dispose();
    _finCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(perfilAcademicoProvider);
    final p = perfilAsync.valueOrNull;
    final activas = ref.watch(asignaturasActivasProvider).valueOrNull ?? [];
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollCtrl) {
        return ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: SVColors.outlineVariant,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Centro de Control',
                  style: TextStyle(
                      color: SVColors.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              _bloque('Fechas del Semestre'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                    color: SVColors.surfaceContainer,
                    borderRadius: SVShapes.standard12),
                child: Column(children: [
                  Row(children: [
                    Expanded(
                        child: TextField(
                            controller: _inicioCtrl,
                            readOnly: true,
                            decoration: const InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                hintText: 'Inicio',
                                hintStyle: TextStyle(
                                    color: SVColors.onSurfaceMuted,
                                    fontSize: 13)),
                            onTap: () => _pickFecha(_inicioCtrl))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: TextField(
                            controller: _finCtrl,
                            readOnly: true,
                            decoration: const InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                hintText: 'Fin',
                                hintStyle: TextStyle(
                                    color: SVColors.onSurfaceMuted,
                                    fontSize: 13)),
                            onTap: () => _pickFecha(_finCtrl))),
                    const SizedBox(width: 10),
                    FilledButton(
                        onPressed: _guardarFechas,
                        style: FilledButton.styleFrom(
                            elevation: 0,
                            backgroundColor: SVColors.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            shape: const RoundedRectangleBorder(
                                borderRadius: SVShapes.standard)),
                        child: const Text('Guardar',
                            style: TextStyle(fontSize: 12))),
                  ]),
                ]),
              ),
              const SizedBox(height: 20),
              _bloque('Curso y Semestre'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                    color: SVColors.surfaceContainer,
                    borderRadius: SVShapes.standard12),
                child: Column(children: [
                  _fila(
                      Icons.calendar_today_outlined,
                      'Semestre',
                      p != null ? '${p.semestreEnCurso}° Semestre' : '—',
                      () => _selSemestre(p?.semestreEnCurso ?? 1)),
                  const SizedBox(height: 8),
                  _fila(Icons.account_balance_outlined, 'Universidad',
                      p?.universidad ?? 'Sin definir', () => _selUni()),
                  const SizedBox(height: 8),
                  _fila(Icons.school_outlined, 'Carrera',
                      p?.carrera ?? 'Sin definir', () {
                    if (p?.universidad != null && p!.universidad!.isNotEmpty)
                      _selCarrera(p.universidad!);
                  }),
                ]),
              ),
              const SizedBox(height: 20),
              _bloque('Mis Asignaturas'),
              const SizedBox(height: 8),
              SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/perfil/asignaturas/selector');
                    },
                    style: OutlinedButton.styleFrom(
                        foregroundColor: SVColors.primary,
                        side: BorderSide(
                            color: SVColors.primary.withValues(alpha: 0.3)),
                        shape: const RoundedRectangleBorder(
                            borderRadius: SVShapes.standard12)),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(
                        'Gestionar asignaturas${activas.isNotEmpty ? ' (${activas.length})' : ''}'),
                  )),
            ]);
      },
    );
  }

  Widget _bloque(String t) => Text(t,
      style: const TextStyle(
          color: SVColors.onSurface,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3));
  Widget _fila(IconData ic, String label, String val, VoidCallback? onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: SVShapes.standard,
        child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(children: [
              Icon(ic, size: 15, color: SVColors.onSurfaceMuted),
              const SizedBox(width: 8),
              Text('$label: ',
                  style: const TextStyle(
                      color: SVColors.onSurfaceMuted, fontSize: 13)),
              Expanded(
                  child: Text(val,
                      style: const TextStyle(
                          color: SVColors.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600))),
              if (onTap != null)
                const Icon(Icons.edit_outlined,
                    size: 14, color: SVColors.outline),
            ])),
      );
}

class _MensajeCentral extends StatelessWidget {
  const _MensajeCentral(
      {required this.icono, required this.titulo, required this.subtitulo});
  final IconData icono;
  final String titulo, subtitulo;
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icono, size: 52, color: SVColors.outlineVariant),
              const SizedBox(height: 16),
              Text(titulo,
                  textAlign: TextAlign.center,
                  style: SVTypography.titleMedium.copyWith(
                      color: SVColors.onSurface, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(subtitulo,
                  textAlign: TextAlign.center,
                  style: SVTypography.bodyMedium
                      .copyWith(color: SVColors.onSurfaceMuted)),
            ])));
  }
}
