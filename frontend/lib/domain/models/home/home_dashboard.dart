import '../../enums/item_time_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../enums/home_acwr_zone.dart';
import '../../enums/home_banner_type.dart';
import '../../enums/home_event_kind.dart';
import '../../enums/home_event_type.dart';

part 'home_dashboard.freezed.dart';

/// Resumen completo de la pestaña Inicio (`GET /api/v1/dashboard`).
@freezed
abstract class HomeDashboard with _$HomeDashboard {
  const factory HomeDashboard({
    required HomeGreeting greeting,
    required HomeTodayKpis today,
    required HomeWeekKpis week,
    required HomeCognitiveState cognitive,
    required HomeCrossRegulation crossRegulation,
    required HomeWellbeing wellbeing,
    HomeNextTrainingDay? nextTrainingDay,
    @Default(<HomeChallenge>[]) List<HomeChallenge> activeChallenges,
    @Default(<HomePlanDay>[]) List<HomePlanDay> planWeek,
    @Default(<HomeTodayEvent>[]) List<HomeTodayEvent> todayEvents,
    required HomeSmartBanner banner,
  }) = _HomeDashboard;
}

/// Cabecera: nombre, avatar, nivel y racha.
@freezed
abstract class HomeGreeting with _$HomeGreeting {
  const factory HomeGreeting({
    required String fullName,
    String? avatarUrl,
    required int level,
    required int levelXp,
    required int levelThreshold,
    required int streak,
  }) = _HomeGreeting;
}

/// Indicadores de hoy.
@freezed
abstract class HomeTodayKpis with _$HomeTodayKpis {
  const factory HomeTodayKpis({
    required double trainingCalories,
    required double studyCalories,
    required double totalCalories,
    required int sessions,
    required int trainingMinutes,
    required int studyMinutesCompleted,
    required int studyMinutesPlanned,
  }) = _HomeTodayKpis;
}

/// Indicadores de la semana en curso.
@freezed
abstract class HomeWeekKpis with _$HomeWeekKpis {
  const factory HomeWeekKpis({
    required int sessions,
    int? plannedSessions,
    required int trainingMinutes,
    required double trainingCalories,
    required int studyMinutesCompleted,
  }) = _HomeWeekKpis;
}

/// Estado cognitivo: carga y capacidad atencional, ambas entre 0 y 1.
@freezed
abstract class HomeCognitiveState with _$HomeCognitiveState {
  const factory HomeCognitiveState({
    required double cognitiveLoad,
    required double attentionCapacity,
    required int lastBlockMinutes,
  }) = _HomeCognitiveState;
}

/// Regulación cruzada: ACWR, su zona y el estudio máximo recomendado.
@freezed
abstract class HomeCrossRegulation with _$HomeCrossRegulation {
  const factory HomeCrossRegulation({
    double? acwr,
    required HomeAcwrZone zone,
    required int maxStudyMinutes,

    /// Bloque y pausa del Pomodoro de hoy (los mismos que propone el Pomodoro).
    required int focusMinutes,
    required int focusBreakMinutes,
  }) = _HomeCrossRegulation;
}

/// Bienestar de hoy. La energía (0-100) es nula sin check-in.
@freezed
abstract class HomeWellbeing with _$HomeWellbeing {
  const factory HomeWellbeing({
    required bool checkInDone,
    int? fatigueScore,
    double? energyScore,
    double? adherenceScore,
  }) = _HomeWellbeing;
}

/// Próximo día de entrenamiento de la rutina activa.
@freezed
abstract class HomeNextTrainingDay with _$HomeNextTrainingDay {
  const factory HomeNextTrainingDay({
    required String routineId,
    required String routineName,
    required String dayId,
    required int weekNumber,
    required int dayNumber,
    String? dayName,
    required bool inProgress,
  }) = _HomeNextTrainingDay;
}

/// Reto activo con su progreso (0-100).
@freezed
abstract class HomeChallenge with _$HomeChallenge {
  const factory HomeChallenge({
    required String id,
    required String title,
    required bool academic,
    DateTime? endsAt,
    required double progress,
    required int currentStreak,
  }) = _HomeChallenge;
}

/// Bloques planificados y completados de un día de la semana del plan.
@freezed
abstract class HomePlanDay with _$HomePlanDay {
  const factory HomePlanDay({
    required DateTime date,
    required int planned,
    required int completed,

    /// Bloques del día que pasaron sin hacerse.
    @Default(0) int missed,
  }) = _HomePlanDay;
}

/// Evento de hoy: bloque del calendario o entrega/examen (sin fin).
@freezed
abstract class HomeTodayEvent with _$HomeTodayEvent {
  const factory HomeTodayEvent({
    required String id,
    required HomeEventKind kind,
    required HomeEventType type,
    required String title,
    DateTime? start,
    DateTime? end,
    required bool completed,
    String? subjectName,

    /// Pendiente, en curso, hecho o no hecho/vencido.
    @Default(ItemTimeStatus.upcoming) ItemTimeStatus status,
  }) = _HomeTodayEvent;
}

/// Banner inteligente: el cliente redacta el texto a partir del tipo y sus parámetros.
@freezed
abstract class HomeSmartBanner with _$HomeSmartBanner {
  const factory HomeSmartBanner({
    required HomeBannerType type,
    @Default(<String, num>{}) Map<String, num> params,

    /// Textos del usuario que el aviso cita (p. ej. el bloque sin hacer).
    @Default(<String, String>{}) Map<String, String> labels,
  }) = _HomeSmartBanner;

  const HomeSmartBanner._();

  /// Parámetro numérico (0 si falta).
  num param(String key) => params[key] ?? 0;
}
