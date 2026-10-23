import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/enums/data_topic.dart';
import '../../domain/use_cases/sync/watch_data_changes_use_case.dart';

/// Refresco entre pestañas (ADR 0010): el bloc de una pestaña se suscribe a
/// [WatchDataChangesUseCaseContract] y, cuando otra pantalla cambia alguno de
/// sus [DataTopic], se envía a sí mismo su evento de recarga silenciosa. La
/// suscripción vive y muere con el bloc, no con un widget.
mixin DataChangeRefreshMixin<E, S> on Bloc<E, S> {
  StreamSubscription<Set<DataTopic>>? _dataChanges;

  /// Empieza a escuchar (una sola vez aunque `started` se repita).
  void watchDataChanges(
    WatchDataChangesUseCaseContract watch, {
    required Set<DataTopic> topics,
    required E onChanged,
  }) {
    _dataChanges ??= watch(topics: topics).listen((_) {
      if (!isClosed) add(onChanged);
    });
  }

  @override
  Future<void> close() async {
    await _dataChanges?.cancel();
    return super.close();
  }
}
