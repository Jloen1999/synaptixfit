import '../../domain/enums/data_topic.dart';
import '../../domain/repositories/data_change_repository_contract.dart';
import '../remote_data_source/api/data_change_interceptor.dart';

/// Implementa [DataChangeRepositoryContract] con los avisos de
/// [DataChangeInterceptor].
class DataChangeRepository implements DataChangeRepositoryContract {
  const DataChangeRepository(this._interceptor);

  final DataChangeInterceptor _interceptor;

  @override
  Stream<Set<DataTopic>> watch() => _interceptor.changes;
}
