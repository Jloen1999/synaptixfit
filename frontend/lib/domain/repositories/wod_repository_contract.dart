import '../models/result/app_result.dart';
import '../models/result/result.dart';
import '../models/training/wod.dart';

/// WOD en el servidor (ADR 0069): plantillas, la pizarra de hoy, mis WOD y mis
/// marcas. La mejor marca la calcula el servidor.
abstract interface class WodRepositoryContract {
  /// Plantillas de ejemplo: solo códigos; el nombre lo pone la pantalla.
  Future<AppResult<List<Wod>>> listTemplates();

  /// La pizarra de hoy; con [templateCode], esa plantilla de ejemplo.
  Future<AppResult<WodBoard>> board({String? templateCode});

  Future<AppResult<Wod>> create(Wod wod);

  Future<AppResult<Wod>> update(Wod wod);

  Future<AppResult<Unit>> delete(String wodId);

  /// Guarda la marca de [wod]; si es una plantilla aún sin usar (sin id), el
  /// servidor crea mi WOD con ella.
  Future<AppResult<WodMark>> saveResult(Wod wod, WodResultDraft draft);

  Future<AppResult<List<WodMark>>> listMarks();
}
