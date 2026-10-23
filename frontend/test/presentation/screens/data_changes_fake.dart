import 'dart:async';

import 'package:synaptixfit/domain/enums/data_topic.dart';
import 'package:synaptixfit/domain/repositories/data_change_repository_contract.dart';
import 'package:synaptixfit/domain/use_cases/sync/watch_data_changes_use_case.dart';

/// Bus de cambios de datos para los tests de blocs de pestaña: [emit] simula
/// una escritura en otra pantalla y [useCase] es el caso de uso real, así que
/// el filtro por temas es el mismo que en la app.
class FakeDataChanges implements DataChangeRepositoryContract {
  final _controller = StreamController<Set<DataTopic>>.broadcast();

  late final WatchDataChangesUseCaseContract useCase = WatchDataChangesUseCase(
    this,
  );

  @override
  Stream<Set<DataTopic>> watch() => _controller.stream;

  void emit(Set<DataTopic> topics) => _controller.add(topics);

  Future<void> close() => _controller.close();
}

/// Deja que el bloc procese los eventos pendientes.
Future<void> pump() => Future<void>.delayed(Duration.zero);
