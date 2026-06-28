import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../application/selector_asignaturas_provider.dart';
import '../../perfil/application/perfil_provider.dart';

class SelectorAsignaturasScreen extends ConsumerStatefulWidget {
  final bool esOnboarding;
  const SelectorAsignaturasScreen({super.key, this.esOnboarding = false});

  @override
  ConsumerState<SelectorAsignaturasScreen> createState() =>
      _SelectorAsignaturasScreenState();
}

class _SelectorAsignaturasScreenState
    extends ConsumerState<SelectorAsignaturasScreen>
    with TickerProviderStateMixin {
  TabController? _tabController;
  final _busqueda = TextEditingController();
  String _filtro = '';

  Map<String, bool> _seleccion = {};
  List<AsignaturaSeleccion> _items = [];
  bool _cargado = false;
  bool _guardando = false;

  @override
  void dispose() {
    _tabController?.dispose();
    _busqueda.dispose();
    super.dispose();
  }

  void _inicializarSeleccion(
      List<AsignaturaSeleccion> items, PerfilAcademicoDb? perfil) {
    if (_cargado) return;
    _items = items;
    _seleccion = {};
    for (final item in items) {
      if (widget.esOnboarding && !item.seleccionada && perfil != null) {
        final coincide = item.catalogo.curso == perfil.cursoActual &&
            item.catalogo.semestre == perfil.semestreEnCurso;
        _seleccion[item.catalogo.id] = coincide;
      } else {
        _seleccion[item.catalogo.id] = item.seleccionada;
      }
    }
    _cargado = true;
  }

  List<int> _getCursos() {
    final cursos = _items
        .where(
            (i) => i.catalogo.curso != null && (i.catalogo.semestre ?? 0) > 0)
        .map((i) => i.catalogo.curso!)
        .toSet()
        .toList()
      ..sort();
    return cursos;
  }

  bool _tieneOptativas() => _items.any((i) => (i.catalogo.semestre ?? 0) == 0);

  List<AsignaturaSeleccion> _filtrar(List<AsignaturaSeleccion> list) {
    if (_filtro.isEmpty) return list;
    final lower = _filtro.toLowerCase();
    return list
        .where((i) => i.catalogo.nombre.toLowerCase().contains(lower))
        .toList();
  }

  int get _totalSeleccionadas => _seleccion.values.where((v) => v).length;

  double get _totalCreditos {
    double total = 0;
    for (final item in _items) {
      if (_seleccion[item.catalogo.id] == true) {
        total += item.catalogo.creditos ?? 0;
      }
    }
    return total;
  }

  void _toggleItem(String catalogoId) {
    setState(() {
      _seleccion[catalogoId] = !(_seleccion[catalogoId] ?? false);
    });
  }

  void _toggleGrupo(List<AsignaturaSeleccion> grupo, bool activar) {
    setState(() {
      for (final item in grupo) {
        _seleccion[item.catalogo.id] = activar;
      }
    });
  }

  Future<void> _confirmar() async {
    setState(() => _guardando = true);

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return;

    await client
        .from('asignaturas')
        .update({'archivado': true}).eq('usuario_id', user.id);

    for (final item in _items) {
      final deseado = _seleccion[item.catalogo.id] ?? false;
      if (deseado) {
        await toggleAsignatura(item: item, activar: true);
      }
    }

    if (!mounted) return;
    invalidarProviders(ref);

    if (widget.esOnboarding) {
      context.go('/onboarding/cuenta');
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(selectorAsignaturasProvider);
    final perfilAsync = ref.watch(perfilAcademicoProvider);
    final tema = Theme.of(context);
    final cs = tema.colorScheme;

    return dataAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Mis asignaturas')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Mis asignaturas')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (items) {
        final perfil = perfilAsync.valueOrNull;
        _inicializarSeleccion(items, perfil);

        final cursos = _getCursos();
        final tieneOpt = _tieneOptativas();
        final tabCount = cursos.length + (tieneOpt ? 1 : 0);

        if (_tabController == null || _tabController!.length != tabCount) {
          _tabController?.dispose();
          _tabController = TabController(length: tabCount, vsync: this);
        }

        return Scaffold(
          appBar: AppBar(
            leading: widget.esOnboarding
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.pop(),
                  ),
            title: const Text('Selecciona tus asignaturas'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: TabBar(
                controller: _tabController,
                isScrollable: tabCount > 4,
                tabs: [
                  for (final c in cursos) Tab(text: '$c°'),
                  if (tieneOpt) const Tab(text: 'Optativas'),
                ],
              ),
            ),
          ),
          body: Column(
            children: [
              _buildResumen(cs, tema),
              _buildBuscador(cs, tema),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    for (final c in cursos) _buildCursoTab(c),
                    if (tieneOpt) _buildOptativasTab(),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton.icon(
                onPressed: _guardando ? null : _confirmar,
                icon: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _guardando
                      ? 'Guardando...'
                      : 'Confirmar selección ($_totalSeleccionadas asig.)',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResumen(ColorScheme cs, ThemeData tema) {
    final creditos = _totalCreditos;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.school_outlined, color: cs.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_totalSeleccionadas asignaturas seleccionadas',
                  style: tema.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                if (creditos > 0)
                  Text(
                    '${creditos.toStringAsFixed(creditos.truncateToDouble() == creditos ? 0 : 1)} ECTS',
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuscador(ColorScheme cs, ThemeData tema) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SizedBox(
        height: 40,
        child: TextField(
          controller: _busqueda,
          style: tema.textTheme.bodySmall,
          decoration: InputDecoration(
            hintText: 'Buscar asignatura...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _filtro.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _busqueda.clear();
                      setState(() => _filtro = '');
                    },
                  )
                : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
            isDense: true,
          ),
          onChanged: (v) => setState(() => _filtro = v),
        ),
      ),
    );
  }

  Widget _buildCursoTab(int curso) {
    final delCurso = _items
        .where(
            (i) => i.catalogo.curso == curso && (i.catalogo.semestre ?? 0) > 0)
        .toList();
    final semestres = delCurso.map((i) => i.catalogo.semestre!).toSet().toList()
      ..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        for (final sem in semestres) ...[
          _buildGrupoSemestre(
            'Semestre $sem',
            delCurso.where((i) => i.catalogo.semestre == sem).toList(),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildOptativasTab() {
    final optativas =
        _items.where((i) => (i.catalogo.semestre ?? 0) == 0).toList();
    final filtradas = _filtrar(optativas);

    final todasSel = filtradas.isNotEmpty &&
        filtradas.every((i) => _seleccion[i.catalogo.id] == true);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        if (filtradas.length > 1)
          _buildHeaderGrupo(
            'Optativas / Transversales',
            filtradas,
            todasSel,
          ),
        for (final item in filtradas) _buildAsignaturaCard(item),
      ],
    );
  }

  Widget _buildGrupoSemestre(String titulo, List<AsignaturaSeleccion> grupo) {
    final filtrados = _filtrar(grupo);
    if (filtrados.isEmpty) return const SizedBox.shrink();

    final todasSel = filtrados.every((i) => _seleccion[i.catalogo.id] == true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderGrupo(titulo, filtrados, todasSel),
        for (final item in filtrados) _buildAsignaturaCard(item),
      ],
    );
  }

  Widget _buildHeaderGrupo(
      String titulo, List<AsignaturaSeleccion> grupo, bool todasSel) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Row(
        children: [
          Text(
            titulo,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurfaceVariant,
                ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _toggleGrupo(grupo, !todasSel),
            icon: Icon(
              todasSel ? Icons.deselect : Icons.select_all,
              size: 16,
            ),
            label: Text(
              todasSel ? 'Quitar todas' : 'Seleccionar todas',
              style: const TextStyle(fontSize: 12),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAsignaturaCard(AsignaturaSeleccion item) {
    final cs = Theme.of(context).colorScheme;
    final tema = Theme.of(context);
    final sel = _seleccion[item.catalogo.id] ?? false;
    final cat = item.catalogo;

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: sel
              ? cs.primary.withValues(alpha: 0.5)
              : cs.outlineVariant.withValues(alpha: 0.3),
          width: sel ? 1.5 : 1,
        ),
      ),
      color: sel
          ? cs.primaryContainer.withValues(alpha: 0.15)
          : cs.surfaceContainerLowest,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _toggleItem(cat.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  sel ? Icons.check_circle_rounded : Icons.circle_outlined,
                  key: ValueKey(sel),
                  color: sel ? cs.primary : cs.outlineVariant,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.nombre,
                      style: tema.textTheme.bodyMedium?.copyWith(
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        color: sel ? cs.onSurface : cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (cat.caracter != null)
                          _chip(cat.caracter!, cs.secondaryContainer,
                              cs.onSecondaryContainer),
                        if (cat.creditos != null) ...[
                          const SizedBox(width: 6),
                          _chip(
                            '${cat.creditos!.toStringAsFixed(cat.creditos!.truncateToDouble() == cat.creditos! ? 0 : 1)} ECTS',
                            cs.tertiaryContainer,
                            cs.onTertiaryContainer,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
