import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/db_models.dart';
import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../application/asignaturas_provider.dart';

class GestionAsignaturasScreen extends ConsumerStatefulWidget {
  const GestionAsignaturasScreen({super.key});

  @override
  ConsumerState<GestionAsignaturasScreen> createState() =>
      _GestionAsignaturasScreenState();
}

class _GestionAsignaturasScreenState
    extends ConsumerState<GestionAsignaturasScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _busquedaCtrl = TextEditingController();
  final _focusBusqueda = FocusNode();
  List<CatalogoAsignaturaDb> _resultados = [];
  bool _buscando = false;
  bool _mostrandoResultados = false;
  Set<String> _nuevasIds = {};
  bool _extraLeido = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _busquedaCtrl.dispose();
    _focusBusqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_extraLeido) {
      _extraLeido = true;
      final extra =
          GoRouterState.of(context).extra as Map<String, dynamic>?;
      if (extra != null && extra.containsKey('nuevasIds')) {
        _nuevasIds = (extra['nuevasIds'] as List)
            .map((e) => e.toString())
            .toSet();
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) setState(() => _nuevasIds = {});
        });
      }
    }
    return FeatureScaffold(
      title: 'Asignaturas',
      backPath: '/academico',
      actions: [
        IconButton(
          icon: const Icon(Icons.assignment_ind),
          tooltip: 'Cargar desde plan de carrera',
          onPressed: () => context.push('/academico/configuracion'),
        ),
      ],
      floatingActionButton: null,
      child: Column(
        children: [
          _buildSearchBar(),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Activas'),
              Tab(text: 'Archivadas'),
            ],
          ),
          Expanded(
            child: _mostrandoResultados
                ? _buildResultadosCatalogo()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _ListaAsignaturas(
                        provider: asignaturasActivasProvider,
                        onEdit: _mostrarDialogoEditar,
                        onArchive: (a) => _confirmarArchivar(a, true),
                        onDelete: _confirmarEliminar,
                        emptyLabel: 'Busca y añade asignaturas desde el catálogo.',
                        nuevasIds: _nuevasIds,
                      ),
                      _ListaAsignaturas(
                        provider: asignaturasArchivadasProvider,
                        onEdit: _mostrarDialogoEditar,
                        onArchive: (a) => _confirmarArchivar(a, false),
                        onDelete: _confirmarEliminar,
                        emptyLabel: 'No tienes asignaturas archivadas.',
                        nuevasIds: const {},
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: SearchBar(
        controller: _busquedaCtrl,
        focusNode: _focusBusqueda,
        hintText: 'Buscar asignatura en el catálogo...',
        leading: _buscando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(2),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : const Icon(Icons.search, size: 20),
        trailing: _mostrandoResultados
            ? [
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    _busquedaCtrl.clear();
                    setState(() {
                      _mostrandoResultados = false;
                      _resultados = [];
                    });
                    _focusBusqueda.unfocus();
                  },
                ),
              ]
            : _busquedaCtrl.text.isNotEmpty
                ? [
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _busquedaCtrl.clear();
                        setState(() => _resultados = []);
                      },
                    ),
                  ]
                : null,
        onChanged: (_) => _buscarCatalogo(),
        onSubmitted: (_) {
          if (_resultados.isNotEmpty && !_mostrandoResultados) {
            setState(() => _mostrandoResultados = true);
          }
        },
        onTapOutside: (_) => _focusBusqueda.unfocus(),
        elevation: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return 2;
          return 0;
        }),
      ),
    );
  }

  Widget _buildResultadosCatalogo() {
    if (_buscando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_resultados.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'Sin resultados',
        message: 'Prueba con otro término de búsqueda.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: _resultados.length,
      itemBuilder: (context, index) {
        final a = _resultados[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: const Icon(Icons.library_books_outlined, size: 22),
            title: Text(a.nombre, style: const TextStyle(fontSize: 14)),
            subtitle: Text(
              [
                if (a.caracter != null) a.caracter,
                if (a.curso != null) 'Curso ${a.curso}',
                if (a.creditos != null) '${a.creditos} ECTS',
              ].join(' · '),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: FilledButton.tonalIcon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Añadir', style: TextStyle(fontSize: 12)),
              onPressed: () => _agregarDesdeCatalogo(a),
            ),
          ),
        );
      },
    );
  }

  Future<void> _buscarCatalogo() async {
    final q = _busquedaCtrl.text.trim().toLowerCase();
    if (q.length < 2) {
      setState(() {
        _resultados = [];
        _mostrandoResultados = false;
      });
      return;
    }
    if (!_buscando) setState(() => _buscando = true);

    final client = Supabase.instance.client;
    final data = await client
        .from('catalogo_asignaturas')
        .select('*')
        .ilike('nombre', '%$q%')
        .limit(10);

    if (!mounted) return;
    setState(() {
      _resultados =
          (data as List).map((e) => CatalogoAsignaturaDb.fromMap(e)).toList();
      _buscando = false;
    });
  }

  Future<void> _agregarDesdeCatalogo(CatalogoAsignaturaDb a) async {
    final activas = ref.read(asignaturasActivasProvider).valueOrNull ?? [];
    final existe = activas
        .any((ea) => ea.nombre.toLowerCase() == a.nombre.toLowerCase());
    if (existe) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('«${a.nombre}» ya está en tu lista.')),
        );
      }
      return;
    }

    final codigo = a.caracter != null && a.curso != null
        ? '${a.caracter!.substring(0, 3)}-${a.curso}S${a.semestre ?? 1}'
        : null;
    final descripcion = [
      if (a.curso != null) 'Curso ${a.curso}',
      if (a.semestre != null) 'Sem ${a.semestre}',
      if (a.caracter != null) a.caracter,
      if (a.creditos != null) '${a.creditos} ECTS',
    ].join(' · ');

    await crearAsignatura(
      nombre: a.nombre,
      codigo: codigo,
      descripcion: descripcion.isNotEmpty ? descripcion : null,
    );

    _invalidarProviders();
    _busquedaCtrl.clear();
    setState(() {
      _resultados = [];
      _mostrandoResultados = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('«${a.nombre}» añadida.')),
      );
    }
  }

  void _mostrarDialogoEditar(AsignaturaDb asignatura) {
    showDialog(
      context: context,
      builder: (ctx) => _AsignaturaEditDialog(asignatura: asignatura),
    ).then((_) => _invalidarProviders());
  }

  void _confirmarArchivar(AsignaturaDb a, bool archivar) {
    final accion = archivar ? 'archivar' : 'desarchivar';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text('${archivar ? "Archivar" : "Desarchivar"} asignatura'),
        content: Text('¿$accion «${a.nombre}»? '
            '${archivar ? "No se eliminará el historial." : ""}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await archivarAsignatura(a.id, archivar);
              _invalidarProviders();
            },
            child: Text(archivar ? 'Archivar' : 'Desarchivar'),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(AsignaturaDb a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar asignatura'),
        content: Text(
            '¿Eliminar definitivamente «${a.nombre}»? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await eliminarAsignatura(a.id);
              _invalidarProviders();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _invalidarProviders() {
    ref.invalidate(asignaturasActivasProvider);
    ref.invalidate(asignaturasArchivadasProvider);
  }
}

class _ListaAsignaturas extends ConsumerWidget {
  const _ListaAsignaturas({
    required this.provider,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
    required this.emptyLabel,
    required this.nuevasIds,
  });

  final AutoDisposeFutureProvider<List<AsignaturaDb>> provider;
  final void Function(AsignaturaDb) onEdit;
  final void Function(AsignaturaDb) onArchive;
  final void Function(AsignaturaDb) onDelete;
  final String emptyLabel;
  final Set<String> nuevasIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (asignaturas) {
        if (asignaturas.isEmpty) {
          return EmptyState(
            icon: Icons.school_outlined,
            title: 'Sin asignaturas',
            message: emptyLabel,
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(provider);
            return ref.read(provider.future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: asignaturas.length,
            itemBuilder: (context, index) {
              final a = asignaturas[index];
              return _AsignaturaTile(
                asignatura: a,
                onEdit: () => onEdit(a),
                onArchive: () => onArchive(a),
                onDelete: () => onDelete(a),
                esNueva: nuevasIds.contains(a.id),
              );
            },
          ),
        );
      },
    );
  }
}

class _AsignaturaTile extends StatelessWidget {
  const _AsignaturaTile({
    required this.asignatura,
    required this.onEdit,
    required this.onArchive,
    required this.onDelete,
    this.esNueva = false,
  });

  final AsignaturaDb asignatura;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final bool esNueva;

  @override
  Widget build(BuildContext context) {
    final esArchivada = asignatura.archivado;
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(
        begin: esNueva
            ? Colors.blue.withValues(alpha: 0.12)
            : Colors.transparent,
        end: Colors.transparent,
      ),
      duration: const Duration(seconds: 3),
      builder: (context, color, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: child,
        );
      },
      child: Card(
        margin: EdgeInsets.zero,
        child: ListTile(
        onTap: () => _mostrarDetalle(context),
        leading: Icon(
          esArchivada ? Icons.archive_outlined : Icons.book_outlined,
          color: esArchivada ? Colors.grey : null,
        ),
        title: Text(
          asignatura.nombre,
          style: TextStyle(
            decoration: esArchivada ? TextDecoration.lineThrough : null,
            color: esArchivada ? Colors.grey : null,
          ),
        ),
        subtitle: _buildSubtitle(),
        isThreeLine: _hasSubtitle().$1 || _hasSubtitle().$2,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
              case 'archive':
                onArchive();
              case 'delete':
                onDelete();
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(
              value: 'archive',
              child: Text(esArchivada ? 'Desarchivar' : 'Archivar'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    ),
    );
  }

  void _mostrarDetalle(BuildContext context) {
    final a = asignatura;

    Future<CatalogoAsignaturaDb?> fetchCatalogo() async {
      if (a.catalogoAsignaturaId == null) return null;
      final client = Supabase.instance.client;
      final data = await client
          .from('catalogo_asignaturas')
          .select()
          .eq('id', a.catalogoAsignaturaId!)
          .maybeSingle();
      if (data == null) return null;
      return CatalogoAsignaturaDb.fromMap(data);
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return FutureBuilder<CatalogoAsignaturaDb?>(
          future: fetchCatalogo(),
          builder: (context, snap) {
            final catalogo = snap.data;
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        a.archivado
                            ? Icons.archive_outlined
                            : Icons.book_outlined,
                        size: 22,
                        color: a.archivado ? Colors.grey : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          a.nombre,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                decoration: a.archivado
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (a.codigo?.isNotEmpty ?? false) ...[
                    _buildDetailRow(
                        Icons.tag, 'Código', a.codigo!),
                    const SizedBox(height: 8),
                  ],
                  if (a.docente?.isNotEmpty ?? false) ...[
                    _buildDetailRow(
                        Icons.person_outline, 'Docente', a.docente!),
                    const SizedBox(height: 8),
                  ],
                  if (catalogo != null) ...[
                    if (catalogo.curso != null) ...[
                      _buildDetailRow(Icons.school, 'Curso',
                          '${catalogo.curso}º'),
                      const SizedBox(height: 8),
                    ],
                    if (catalogo.semestre != null) ...[
                      _buildDetailRow(Icons.calendar_month,
                          'Semestre', '${catalogo.semestre}'),
                      const SizedBox(height: 8),
                    ],
                    if (catalogo.caracter != null &&
                        catalogo.caracter!.isNotEmpty) ...[
                      _buildDetailRow(Icons.label_outline, 'Carácter',
                          catalogo.caracter!),
                      const SizedBox(height: 8),
                    ],
                    if (catalogo.creditos != null) ...[
                      _buildDetailRow(Icons.stars, 'Créditos',
                          '${catalogo.creditos} ECTS'),
                      const SizedBox(height: 8),
                    ],
                  ],
                  if (catalogo == null &&
                      (a.descripcion?.isNotEmpty ?? false)) ...[
                    _buildDetailRow(Icons.description_outlined,
                        'Descripción', a.descripcion!),
                    const SizedBox(height: 8),
                  ],
                  _buildDetailRow(Icons.calendar_today, 'Creada',
                      DateFormat('dd/MM/yyyy').format(a.creadoEn)),
                  const SizedBox(height: 8),
                  _buildDetailRow(Icons.info_outline, 'Estado',
                      a.archivado ? 'Archivada' : 'Activa'),
                  if (a.catalogoAsignaturaId != null &&
                      catalogo == null &&
                      snap.connectionState == ConnectionState.waiting) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildDetailRow(
      IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w500)),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }

  (bool, bool) _hasSubtitle() {
    return (
      (asignatura.codigo?.isNotEmpty ?? false) ||
          (asignatura.docente?.isNotEmpty ?? false),
      (asignatura.descripcion?.isNotEmpty ?? false),
    );
  }

  Widget? _buildSubtitle() {
    final partes = <String>[];
    if (asignatura.codigo?.isNotEmpty ?? false) partes.add(asignatura.codigo!);
    if (asignatura.docente?.isNotEmpty ?? false) {
      partes.add(asignatura.docente!);
    }

    if (partes.isEmpty && asignatura.descripcion?.isNotEmpty != true) {
      return null;
    }

    final codigoDocente = partes.join(' · ');
    final desc = asignatura.descripcion;

    if (codigoDocente.isEmpty) {
      return Text(desc!, maxLines: 1, overflow: TextOverflow.ellipsis);
    }
    if (desc == null || desc.isEmpty) {
      return Text(codigoDocente);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(codigoDocente),
        Text(desc, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

class _AsignaturaEditDialog extends ConsumerStatefulWidget {
  const _AsignaturaEditDialog({required this.asignatura});

  final AsignaturaDb asignatura;

  @override
  ConsumerState<_AsignaturaEditDialog> createState() =>
      _AsignaturaEditDialogState();
}

class _AsignaturaEditDialogState
    extends ConsumerState<_AsignaturaEditDialog> {
  late final _nombreCtrl = TextEditingController(
    text: widget.asignatura.nombre,
  );
  late final _codigoCtrl = TextEditingController(
    text: widget.asignatura.codigo ?? '',
  );
  late final _docenteCtrl = TextEditingController(
    text: widget.asignatura.docente ?? '',
  );
  late final _descripcionCtrl = TextEditingController(
    text: widget.asignatura.descripcion ?? '',
  );

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _codigoCtrl.dispose();
    _docenteCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.length < 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El nombre debe tener al menos 2 caracteres.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    await actualizarAsignatura(
      id: widget.asignatura.id,
      nombre: nombre,
      codigo: _codigoCtrl.text.trim().isEmpty
          ? null
          : _codigoCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim().isEmpty
          ? null
          : _descripcionCtrl.text.trim(),
      docente: _docenteCtrl.text.trim().isEmpty
          ? null
          : _docenteCtrl.text.trim(),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar asignatura'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nombreCtrl,
              textCapitalization: TextCapitalization.sentences,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nombre *',
                hintText: 'ej: Álgebra Lineal',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codigoCtrl,
              decoration: const InputDecoration(
                labelText: 'Código (opcional)',
                hintText: 'ej: MAT-101',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _docenteCtrl,
              decoration: const InputDecoration(
                labelText: 'Docente (opcional)',
                hintText: 'ej: Dr. García',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descripcionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                hintText: 'Notas, temario u horario',
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
