import 'package:freezed_annotation/freezed_annotation.dart';

part 'physical_load.freezed.dart';

/// Carga física diaria (unidades arbitrarias) de los últimos 28 días.
@freezed
abstract class PhysicalLoad with _$PhysicalLoad {
  const factory PhysicalLoad({
    required double todayLoad,
    required double maxDailyLoad,
    required double todayRatio,
    required List<DailyLoad> last28Days,
  }) = _PhysicalLoad;

  const PhysicalLoad._();

  /// Media diaria de la ventana.
  double get averageLoad => last28Days.isEmpty
      ? 0
      : last28Days.fold<double>(0, (sum, d) => sum + d.load) /
            last28Days.length;

  bool get hasData => last28Days.any((d) => d.load > 0);
}

/// Carga de un día.
@freezed
abstract class DailyLoad with _$DailyLoad {
  const factory DailyLoad({required DateTime date, required double load}) =
      _DailyLoad;
}
