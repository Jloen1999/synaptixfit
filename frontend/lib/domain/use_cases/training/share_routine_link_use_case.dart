import '../../models/result/app_result.dart';
import '../../models/result/result.dart';
import '../../models/training/routine_share.dart';
import '../../repositories/routine_repository_contract.dart';
import '../../repositories/share_repository_contract.dart';

/// Crea un enlace para copiar la rutina y abre el menú de compartir del
/// sistema con [message] y la dirección (ADR 0043). El enlace queda creado
/// aunque se cierre el menú sin compartir.
abstract interface class ShareRoutineLinkUseCaseContract {
  Future<AppResult<RoutineShareLink>> call(
    String routineId, {
    required String message,
  });
}

class ShareRoutineLinkUseCase implements ShareRoutineLinkUseCaseContract {
  const ShareRoutineLinkUseCase(this._routines, this._share);

  final RoutineRepositoryContract _routines;
  final ShareRepositoryContract _share;

  @override
  Future<AppResult<RoutineShareLink>> call(
    String routineId, {
    required String message,
  }) async {
    final created = await _routines.createShareLink(routineId);
    if (created case Success(:final value)) {
      await _share.shareText(text: '$message\n${value.url}');
    }
    return created;
  }
}
