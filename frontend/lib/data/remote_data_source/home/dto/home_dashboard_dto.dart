import '../../../../domain/enums/item_time_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/cognitive_level.dart';
import '../../../../domain/enums/home_acwr_zone.dart';
import '../../../../domain/enums/home_banner_type.dart';
import '../../../../domain/enums/home_event_kind.dart';
import '../../../../domain/enums/home_event_type.dart';
import '../../../../domain/enums/planner_enums.dart';
import '../../../../domain/enums/training_enums.dart';
import '../../../../domain/models/home/home_dashboard.dart';

part 'home_dashboard_dto.freezed.dart';
part 'home_dashboard_dto.g.dart';

/// Respuesta de `GET /api/v1/dashboard`.
///
/// Nota: el OpenAPI generado documenta mal `week` y `activeChallenges` (colisión
/// de nombres de esquema); estos DTOs siguen los records reales del backend.
@freezed
abstract class HomeDashboardDto with _$HomeDashboardDto {
  const factory HomeDashboardDto({
    required HomeGreetingDto greeting,
    required HomeTodayDto today,
    HomeWeekDto? week,
    HomeCognitiveDto? cognitive,
    HomeCrossRegulationDto? crossRegulation,
    HomeWellbeingDto? wellbeing,
    HomeNextTrainingDayDto? nextTrainingDay,
    @Default(<HomeChallengeDto>[]) List<HomeChallengeDto> activeChallenges,
    @Default(<HomePlanDayDto>[]) List<HomePlanDayDto> planWeek,
    @Default(<HomeTodayEventDto>[]) List<HomeTodayEventDto> todayEvents,
    HomeBannerDto? banner,
    HomeNextDeadlineDto? nextDeadline,
  }) = _HomeDashboardDto;

  const HomeDashboardDto._();

  factory HomeDashboardDto.fromJson(Map<String, dynamic> json) =>
      _$HomeDashboardDtoFromJson(json);

  HomeDashboard toDomain() => HomeDashboard(
    greeting: greeting.toDomain(),
    today: today.toDomain(),
    week: (week ?? const HomeWeekDto()).toDomain(),
    cognitive: (cognitive ?? const HomeCognitiveDto()).toDomain(),
    crossRegulation: (crossRegulation ?? const HomeCrossRegulationDto())
        .toDomain(),
    wellbeing: (wellbeing ?? const HomeWellbeingDto()).toDomain(),
    nextTrainingDay: nextTrainingDay?.toDomain(),
    activeChallenges: activeChallenges.map((c) => c.toDomain()).toList(),
    planWeek: planWeek.map((d) => d.toDomain()).toList(),
    todayEvents: todayEvents.map((e) => e.toDomain()).toList(),
    banner: (banner ?? const HomeBannerDto()).toDomain(),
    nextDeadline: nextDeadline?.toDomain(),
  );
}

/// Cuenta atrás de «Tu día» (`nextDeadline`, ADR 0039).
@freezed
abstract class HomeNextDeadlineDto with _$HomeNextDeadlineDto {
  const factory HomeNextDeadlineDto({
    required String id,
    @Default('') String title,
    String? type,
    required String dueAt,
    String? subjectName,
  }) = _HomeNextDeadlineDto;

  const HomeNextDeadlineDto._();

  factory HomeNextDeadlineDto.fromJson(Map<String, dynamic> json) =>
      _$HomeNextDeadlineDtoFromJson(json);

  HomeNextDeadline toDomain() => HomeNextDeadline(
    id: id,
    title: title,
    type: DeadlineType.fromApi(type),
    dueAt: DateTime.parse(dueAt).toLocal(),
    subjectName: subjectName,
  );
}

@freezed
abstract class HomeGreetingDto with _$HomeGreetingDto {
  const factory HomeGreetingDto({
    @Default('') String fullName,
    String? avatarUrl,
    @Default(1) int level,
    @Default(0) int levelXp,
    @Default(0) int levelThreshold,
    @Default(0) int streak,
    @Default(false) bool birthday,
  }) = _HomeGreetingDto;

  const HomeGreetingDto._();

  factory HomeGreetingDto.fromJson(Map<String, dynamic> json) =>
      _$HomeGreetingDtoFromJson(json);

  HomeGreeting toDomain() => HomeGreeting(
    fullName: fullName,
    avatarUrl: avatarUrl,
    level: level,
    levelXp: levelXp,
    levelThreshold: levelThreshold,
    streak: streak,
    birthday: birthday,
  );
}

@freezed
abstract class HomeTodayDto with _$HomeTodayDto {
  const factory HomeTodayDto({
    @Default(0) double trainingCalories,
    @Default(0) double studyCalories,
    @Default(0) double totalCalories,
    @Default(0) int sessions,
    @Default(0) int trainingMinutes,
    @Default(0) int studyMinutesCompleted,
    @Default(0) int studyMinutesPlanned,
  }) = _HomeTodayDto;

  const HomeTodayDto._();

  factory HomeTodayDto.fromJson(Map<String, dynamic> json) =>
      _$HomeTodayDtoFromJson(json);

  HomeTodayKpis toDomain() => HomeTodayKpis(
    trainingCalories: trainingCalories,
    studyCalories: studyCalories,
    totalCalories: totalCalories,
    sessions: sessions,
    trainingMinutes: trainingMinutes,
    studyMinutesCompleted: studyMinutesCompleted,
    studyMinutesPlanned: studyMinutesPlanned,
  );
}

@freezed
abstract class HomeWeekDto with _$HomeWeekDto {
  const factory HomeWeekDto({
    @Default(0) int sessions,
    int? plannedSessions,
    @Default(0) int trainingMinutes,
    @Default(0) double trainingCalories,
    @Default(0) int studyMinutesCompleted,
  }) = _HomeWeekDto;

  const HomeWeekDto._();

  factory HomeWeekDto.fromJson(Map<String, dynamic> json) =>
      _$HomeWeekDtoFromJson(json);

  HomeWeekKpis toDomain() => HomeWeekKpis(
    sessions: sessions,
    plannedSessions: plannedSessions,
    trainingMinutes: trainingMinutes,
    trainingCalories: trainingCalories,
    studyMinutesCompleted: studyMinutesCompleted,
  );
}

@freezed
abstract class HomeCognitiveDto with _$HomeCognitiveDto {
  const factory HomeCognitiveDto({
    @Default(0) double cognitiveLoad,
    @Default(1) double attentionCapacity,
    @Default(0) int lastBlockMinutes,
    String? loadLevel,
    String? attentionLevel,
  }) = _HomeCognitiveDto;

  const HomeCognitiveDto._();

  factory HomeCognitiveDto.fromJson(Map<String, dynamic> json) =>
      _$HomeCognitiveDtoFromJson(json);

  HomeCognitiveState toDomain() => HomeCognitiveState(
    cognitiveLoad: cognitiveLoad.clamp(0, 1).toDouble(),
    attentionCapacity: attentionCapacity.clamp(0, 1).toDouble(),
    lastBlockMinutes: lastBlockMinutes,
    loadLevel: CognitiveLevel.fromApi(loadLevel),
    attentionLevel: CognitiveLevel.fromApi(attentionLevel),
  );
}

@freezed
abstract class HomeCrossRegulationDto with _$HomeCrossRegulationDto {
  const factory HomeCrossRegulationDto({
    double? acwr,
    String? zone,
    @Default(0) int maxStudyMinutes,
    @Default(52) int focusMinutes,
    @Default(17) int focusBreakMinutes,
  }) = _HomeCrossRegulationDto;

  const HomeCrossRegulationDto._();

  factory HomeCrossRegulationDto.fromJson(Map<String, dynamic> json) =>
      _$HomeCrossRegulationDtoFromJson(json);

  HomeCrossRegulation toDomain() => HomeCrossRegulation(
    acwr: acwr,
    zone: HomeAcwrZone.fromApi(zone),
    maxStudyMinutes: maxStudyMinutes,
    focusMinutes: focusMinutes,
    focusBreakMinutes: focusBreakMinutes,
  );
}

@freezed
abstract class HomeWellbeingDto with _$HomeWellbeingDto {
  const factory HomeWellbeingDto({
    @Default(false) bool checkInDone,
    int? fatigueScore,
    HomeScoreDto? energy,
    HomeScoreDto? adherence,
  }) = _HomeWellbeingDto;

  const HomeWellbeingDto._();

  factory HomeWellbeingDto.fromJson(Map<String, dynamic> json) =>
      _$HomeWellbeingDtoFromJson(json);

  HomeWellbeing toDomain() => HomeWellbeing(
    checkInDone: checkInDone,
    fatigueScore: fatigueScore,
    energyScore: energy?.score,
    adherenceScore: adherence?.score,
  );
}

/// Bloque con puntuación (energía o adherencia); solo interesa `score`.
@freezed
abstract class HomeScoreDto with _$HomeScoreDto {
  const factory HomeScoreDto({double? score}) = _HomeScoreDto;

  factory HomeScoreDto.fromJson(Map<String, dynamic> json) =>
      _$HomeScoreDtoFromJson(json);
}

@freezed
abstract class HomeNextTrainingDayDto with _$HomeNextTrainingDayDto {
  const factory HomeNextTrainingDayDto({
    required String routineId,
    @Default('') String routineName,
    @Default('') String dayId,
    @Default(1) int weekNumber,
    @Default(1) int totalWeeks,
    @Default(1) int dayNumber,
    String? dayName,
    String? status,
    String? scheduledDate,
    @Default(false) bool overdue,
    @Default(1) int sessionOfWeek,
    @Default(1) int sessionsInWeek,
    String? staleSessionId,
    @Default(0) int exerciseCount,
    @Default(0) int totalDays,
    @Default(0) int completedDays,
    @Default(0) int skippedDays,
    String? coverImageUrl,
    String? coverModality,
    @Default(0) int estimatedMinutes,
  }) = _HomeNextTrainingDayDto;

  const HomeNextTrainingDayDto._();

  factory HomeNextTrainingDayDto.fromJson(Map<String, dynamic> json) =>
      _$HomeNextTrainingDayDtoFromJson(json);

  HomeNextTrainingDay toDomain() => HomeNextTrainingDay(
    routineId: routineId,
    routineName: routineName,
    dayId: dayId,
    weekNumber: weekNumber,
    totalWeeks: totalWeeks,
    dayNumber: dayNumber,
    dayName: (dayName?.trim().isEmpty ?? true) ? null : dayName,
    inProgress: status == 'IN_PROGRESS',
    scheduledDate: _localDate(scheduledDate),
    overdue: overdue,
    sessionOfWeek: sessionOfWeek,
    sessionsInWeek: sessionsInWeek,
    staleSessionId: staleSessionId,
    exerciseCount: exerciseCount,
    totalDays: totalDays,
    completedDays: completedDays,
    skippedDays: skippedDays,
    coverImageUrl: (coverImageUrl?.trim().isEmpty ?? true)
        ? null
        : coverImageUrl,
    coverModality: coverModality == null
        ? null
        : Modality.fromApi(coverModality),
    estimatedMinutes: estimatedMinutes,
  );
}

/// Fecha sin hora de la API (`yyyy-MM-dd`) como medianoche local.
DateTime? _localDate(String? value) {
  final parsed = value == null ? null : DateTime.tryParse(value);
  return parsed == null
      ? null
      : DateTime(parsed.year, parsed.month, parsed.day);
}

@freezed
abstract class HomeChallengeDto with _$HomeChallengeDto {
  const factory HomeChallengeDto({
    required String id,
    @Default('') String title,
    String? type,
    DateTime? endsAt,
    @Default(0) double progress,
    @Default(0) int currentStreak,
  }) = _HomeChallengeDto;

  const HomeChallengeDto._();

  factory HomeChallengeDto.fromJson(Map<String, dynamic> json) =>
      _$HomeChallengeDtoFromJson(json);

  HomeChallenge toDomain() => HomeChallenge(
    id: id,
    title: title,
    academic: type == 'ACADEMIC',
    endsAt: endsAt?.toLocal(),
    progress: progress.clamp(0, 100).toDouble(),
    currentStreak: currentStreak,
  );
}

@freezed
abstract class HomePlanDayDto with _$HomePlanDayDto {
  const factory HomePlanDayDto({
    required DateTime date,
    @Default(0) int planned,
    @Default(0) int completed,
    @Default(0) int missed,
  }) = _HomePlanDayDto;

  const HomePlanDayDto._();

  factory HomePlanDayDto.fromJson(Map<String, dynamic> json) =>
      _$HomePlanDayDtoFromJson(json);

  HomePlanDay toDomain() => HomePlanDay(
    date: date,
    planned: planned,
    completed: completed,
    missed: missed,
  );
}

@freezed
abstract class HomeTodayEventDto with _$HomeTodayEventDto {
  const factory HomeTodayEventDto({
    required String id,
    String? kind,
    String? type,
    @Default('') String title,
    DateTime? start,
    DateTime? end,
    @Default(false) bool completed,
    String? subjectName,
    String? status,
    String? routineId,
    String? routineDayId,
    @Default(<HomeTaskMentionDto>[]) List<HomeTaskMentionDto> tasks,
    @Default(false) bool tracksPhysicalLoad,
  }) = _HomeTodayEventDto;

  const HomeTodayEventDto._();

  factory HomeTodayEventDto.fromJson(Map<String, dynamic> json) =>
      _$HomeTodayEventDtoFromJson(json);

  HomeTodayEvent toDomain() => HomeTodayEvent(
    id: id,
    kind: HomeEventKind.fromApi(kind),
    type: HomeEventType.fromApi(type),
    title: title,
    start: start?.toLocal(),
    end: end?.toLocal(),
    completed: completed,
    subjectName: subjectName,
    status: ItemTimeStatus.fromApi(status),
    routineId: routineId,
    routineDayId: routineDayId,
    tasks: tasks.map((t) => t.toDomain()).toList(),
    tracksPhysicalLoad: tracksPhysicalLoad,
  );
}

/// Tarea de reto que avanza con un evento de hoy (`tasks` de cada evento).
@freezed
abstract class HomeTaskMentionDto with _$HomeTaskMentionDto {
  const factory HomeTaskMentionDto({
    required String challengeId,
    @Default('') String challengeTitle,
    String? title,
  }) = _HomeTaskMentionDto;

  const HomeTaskMentionDto._();

  factory HomeTaskMentionDto.fromJson(Map<String, dynamic> json) =>
      _$HomeTaskMentionDtoFromJson(json);

  HomeTaskMention toDomain() => HomeTaskMention(
    challengeId: challengeId,
    challengeTitle: challengeTitle,
    title: title,
  );
}

@freezed
abstract class HomeBannerDto with _$HomeBannerDto {
  const factory HomeBannerDto({
    String? type,
    @Default(<String, num>{}) Map<String, num> params,
    @Default(<String, String>{}) Map<String, String> labels,
  }) = _HomeBannerDto;

  const HomeBannerDto._();

  factory HomeBannerDto.fromJson(Map<String, dynamic> json) =>
      _$HomeBannerDtoFromJson(json);

  HomeSmartBanner toDomain() => HomeSmartBanner(
    type: HomeBannerType.fromApi(type),
    params: params,
    labels: labels,
  );
}
