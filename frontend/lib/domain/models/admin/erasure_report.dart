import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/admin/admin_erasure_mode.dart';

part 'erasure_report.freezed.dart';

/// Informe de un borrado de datos (vaciar, anonimizar o eliminar).
@freezed
abstract class ErasureReport with _$ErasureReport {
  const factory ErasureReport({
    required String userId,
    required AdminErasureMode mode,
    required int deletedRecords,
    required int storedFiles,
    required int failedFileDeletions,
  }) = _ErasureReport;
}
