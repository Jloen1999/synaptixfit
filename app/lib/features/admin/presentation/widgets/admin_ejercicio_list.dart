import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/admin_ejercicio_provider.dart';
import '../../domain/admin_ejercicio_dto.dart';
import 'admin_ejercicio_card.dart';
import 'admin_paginacion_bar.dart';

/// Listado paginado del catálogo de ejercicios con búsqueda.
///
/// Permite al administrador buscar ejercicios por nombre, navegar entre páginas,
/// activar/desactivar ejercicios y editar sus campos.
class AdminEjercicioList extends ConsumerStatefulWidget {
  const AdminEjercicioList({super.key});

  @override
  ConsumerState<AdminEjercicioList> createState() => _AdminEjercicioListState();
}

class _AdminEjercicioListState extends ConsumerState<AdminEjercicioList> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  int _pagina = 0;
  String _query = '';
  static const int _itemsPorPagina = 30;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _query = _searchController.text.trim();
          _pagina = 0;
        });
      }
    });
  }

  void _showEditDialog(AdminEjercicio ejercicio) {
    final nombreCtrl = TextEditingController(text: ejercicio.nombre);
    final dificultadCtrl =
        TextEditingController(text: ejercicio.dificultad ?? '');
    final modalidadCtrl =
        TextEditingController(text: ejercicio.modalidadEntrenamiento ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar ejercicio'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Nombre', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: dificultadCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Dificultad',
                      border: OutlineInputBorder(),
                      hintText: 'principiante, intermedio, avanzado')),
              const SizedBox(height: 12),
              TextField(
                  controller: modalidadCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Modalidad de entrenamiento',
                      border: OutlineInputBorder(),
                      hintText: 'fuerza, hipertrofia...')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () {
                nombreCtrl.dispose();
                dificultadCtrl.dispose();
                modalidadCtrl.dispose();
                Navigator.pop(ctx);
              },
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              nombreCtrl.dispose();
              dificultadCtrl.dispose();
              modalidadCtrl.dispose();
              try {
                await actualizarEjercicio(
                  ref,
                  id: ejercicio.id,
                  nombre: nombreCtrl.text.trim().isNotEmpty
                      ? nombreCtrl.text.trim()
                      : null,
                  dificultad: dificultadCtrl.text.trim().isNotEmpty
                      ? dificultadCtrl.text.trim()
                      : null,
                  modalidadEntrenamiento: modalidadCtrl.text.trim().isNotEmpty
                      ? modalidadCtrl.text.trim()
                      : null,
                );
              } catch (_) {}
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ejerciciosAsync =
        ref.watch(adminEjerciciosProvider((page: _pagina, query: _query)));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar ejercicio por nombre...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        if (mounted) {
                          setState(() {
                            _query = '';
                            _pagina = 0;
                          });
                        }
                      })
                  : null,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
            ),
          ),
        ),
        Expanded(
          child: ejerciciosAsync.when(
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
                      onPressed: () => ref.invalidate(adminEjerciciosProvider(
                          (page: _pagina, query: _query)))),
                ],
              ),
            ),
            data: (ejercicios) {
              if (ejercicios.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fitness_center,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                          _query.isNotEmpty
                              ? 'Sin resultados para "$_query"'
                              : 'No hay ejercicios en el catálogo',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 16)),
                    ],
                  ),
                );
              }

              final totalPaginas = ejercicios.length >= _itemsPorPagina
                  ? _pagina + 2
                  : _pagina + 1;

              return Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async => ref.invalidate(
                          adminEjerciciosProvider(
                              (page: _pagina, query: _query))),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: ejercicios.length,
                        itemBuilder: (context, index) {
                          final ej = ejercicios[index];
                          return AdminEjercicioCard(
                            ejercicio: ej,
                            onToggle: (val) async {
                              try {
                                await toggleEjercicioActivo(ref,
                                    id: ej.id, nombre: ej.nombre, activo: val);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(val
                                              ? 'Ejercicio activado'
                                              : 'Ejercicio desactivado'),
                                          backgroundColor: Colors.green));
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red));
                                }
                              }
                            },
                            onEdit: () => _showEditDialog(ej),
                          );
                        },
                      ),
                    ),
                  ),
                  AdminPaginacionBar(
                      paginaActual: _pagina,
                      totalPaginas: totalPaginas,
                      onPageChanged: (p) => setState(() => _pagina = p)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
