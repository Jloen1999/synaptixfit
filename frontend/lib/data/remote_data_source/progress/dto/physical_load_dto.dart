import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/models/progress/physical_load.dart';

part 'physical_load_dto.freezed.dart';
part 'physical_load_dto.g.dart';

/// `PhysicalLoadResponse`.
@freezed
abstract class PhysicalLoadDto with _$PhysicalLoadDto {
  const factory PhysicalLoadDto({
    @Default(0) double todayLoad,
    @Default(0) double maxDailyLoad,
    @Default(0) double todayRatio,
    @Default(<DailyLoadDto>[]) List<DailyLoadDto> last28Days,
  }) = _PhysicalLoadDto;

  const PhysicalLoadDto._();

  factory PhysicalLoadDto.fromJson(Map<String, dynamic> json) =>
      _$PhysicalLoadDtoFromJson(json);

  PhysicalLoad toDomain() => PhysicalLoad(
    todayLoad: todayLoad,
    maxDailyLoad: maxDailyLoad,
    todayRatio: todayRatio,
    last28Days: (last28Days.map((d) => d.toDomain()).toList()
      ..sort((a, b) => a.date.compareTo(b.date))),
  );
}

@freezed
abstract class DailyLoadDto with _$DailyLoadDto {
  const factory DailyLoadDto({required String date, @Default(0) double load}) =
      _DailyLoadDto;

  const DailyLoadDto._();

  factory DailyLoadDto.fromJson(Map<String, dynamic> json) =>
      _$DailyLoadDtoFromJson(json);

  DailyLoad toDomain() {
    final d = DateTime.parse(date);
    return DailyLoad(date: DateTime(d.year, d.month, d.day), load: load);
  }
}
