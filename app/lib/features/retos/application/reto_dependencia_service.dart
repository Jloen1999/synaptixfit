import '../../../shared/models/db_models.dart';
import '../domain/reto_grafo_dto.dart';
import '../domain/reto_condicion_dto.dart';

class RetoDependenciaService {
  const RetoDependenciaService();

  GrafoReto construirGrafo(List<HitoRetoDb> hitos) {
    final nodos = <NodoHito>[];
    final aristas = <AristaDependencia>[];

    final idAHito = <String, HitoRetoDb>{};
    for (final h in hitos) {
      idAHito[h.id] = h;
    }

    for (final h in hitos) {
      final estadoHito = _estadoDesdeDb(h.estado);

      nodos.add(NodoHito(
        hitoId: h.id,
        titulo: h.titulo,
        estado: estadoHito,
        porcentajePeso: h.porcentajePeso,
        estaCompletado: h.estaCompletado,
      ));

      for (final depId in h.dependencias) {
        aristas.add(AristaDependencia(
          desdeHitoId: depId,
          haciaHitoId: h.id,
          condicion: _condicionDesdeDb(h.tipoCondicion),
          condicionN: h.condicionN,
        ));
      }
    }

    _asignarProfundidades(nodos, aristas);

    return GrafoReto(
      retoId: hitos.isNotEmpty ? hitos.first.retoId : '',
      nodos: nodos,
      aristas: aristas,
    );
  }

  void _asignarProfundidades(
      List<NodoHito> nodos, List<AristaDependencia> aristas) {
    final tieneDependencia = <String, bool>{};
    for (final a in aristas) {
      tieneDependencia[a.haciaHitoId] = true;
    }

    final visitados = <String, int>{};

    int dfs(String id) {
      if (visitados.containsKey(id)) return visitados[id]!;
      final deps = aristas.where((a) => a.haciaHitoId == id).toList();
      if (deps.isEmpty) {
        visitados[id] = 0;
        return 0;
      }
      var maxProf = 0;
      for (final a in deps) {
        final p = dfs(a.desdeHitoId) + 1;
        if (p > maxProf) maxProf = p;
      }
      visitados[id] = maxProf;
      return maxProf;
    }

    for (final n in nodos) {
      visitados[n.hitoId] = dfs(n.hitoId);
    }

    for (var i = 0; i < nodos.length; i++) {
      nodos[i] = NodoHito(
        hitoId: nodos[i].hitoId,
        titulo: nodos[i].titulo,
        estado: nodos[i].estado,
        porcentajePeso: nodos[i].porcentajePeso,
        estaCompletado: nodos[i].estaCompletado,
        profundidad: visitados[nodos[i].hitoId] ?? 0,
      );
    }
  }

  bool detectarCiclos(GrafoReto grafo) {
    final adj = <String, List<String>>{};
    for (final n in grafo.nodos) {
      adj[n.hitoId] = [];
    }
    for (final a in grafo.aristas) {
      adj[a.haciaHitoId]?.add(a.desdeHitoId);
    }

    const kBlanco = 0;
    const kGris = 1;
    const kNegro = 2;
    final color = <String, int>{};

    bool dfs(String u) {
      color[u] = kGris;
      for (final v in adj[u] ?? []) {
        if ((color[v] ?? kBlanco) == kGris) return true;
        if ((color[v] ?? kBlanco) == kBlanco && dfs(v)) return true;
      }
      color[u] = kNegro;
      return false;
    }

    for (final n in grafo.nodos) {
      if ((color[n.hitoId] ?? kBlanco) == kBlanco) {
        if (dfs(n.hitoId)) return true;
      }
    }
    return false;
  }

  String? validarDependencias(List<HitoRetoDb> hitos) {
    final idsValidos = hitos.map((h) => h.id).toSet();
    for (final h in hitos) {
      for (final depId in h.dependencias) {
        if (!idsValidos.contains(depId)) {
          return 'El hito "${h.titulo}" depende de un hito inexistente';
        }
        if (depId == h.id) {
          return 'El hito "${h.titulo}" no puede depender de si mismo';
        }
      }
      if (h.tipoCondicion == 'X_OF_Y' && h.condicionN < 1) {
        return 'X_OF_Y requiere al menos 1 hito completado';
      }
      if (h.tipoCondicion == 'X_OF_Y' && h.condicionN > h.dependencias.length) {
        return 'X_OF_Y no puede requerir mas hitos de los que depende';
      }
    }
    return null;
  }
}

EstadoHito _estadoDesdeDb(String dbValue) {
  return switch (dbValue) {
    'bloqueado' => EstadoHito.bloqueado,
    'disponible' => EstadoHito.disponible,
    'en_progreso' => EstadoHito.enProgreso,
    'completado' => EstadoHito.completado,
    _ => EstadoHito.bloqueado,
  };
}

TipoCondicion _condicionDesdeDb(String dbValue) {
  return switch (dbValue) {
    'AND' => TipoCondicion.AND,
    'OR' => TipoCondicion.OR,
    'X_OF_Y' => TipoCondicion.X_OF_Y,
    _ => TipoCondicion.AND,
  };
}
