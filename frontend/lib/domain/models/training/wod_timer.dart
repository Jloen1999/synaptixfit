import 'wod.dart';

/// En qué está el cronómetro de un WOD.
enum WodPhase { work, rest, done }

/// Lo que enseña el cronómetro en un segundo dado.
class WodTick {
  const WodTick({
    required this.phase,
    required this.round,
    required this.clockSeconds,
    required this.countsDown,
    required this.elapsedSeconds,
  });

  final WodPhase phase;

  /// Ronda en curso (desde 1). En «por tiempo» y AMRAP siempre es 1: las
  /// rondas las cuenta la persona.
  final int round;

  /// La cifra grande: lo que va (cuenta hacia delante) o lo que queda.
  final int clockSeconds;
  final bool countsDown;
  final int elapsedSeconds;

  bool get done => phase == WodPhase.done;

  /// Cambia solo con la fase o la ronda: es lo único que se anuncia al
  /// lector, nunca cada segundo.
  (WodPhase, int) get announceKey => (phase, round);
}

/// Fases del cronómetro de un WOD según su formato (ADR 0069). Pura: recibe
/// los segundos activos (sin pausas) y dice qué toca.
///
/// - Por tiempo: cuenta hacia delante; con límite, termina al llegar a él.
/// - AMRAP: cuenta atrás desde el límite.
/// - EMOM: cuenta atrás de cada minuto, una ronda por minuto.
/// - Tabata: 8 rondas de 20 s de trabajo y 10 s de descanso.
class WodTimer {
  const WodTimer({required this.format, this.timeCapSeconds});

  factory WodTimer.of(Wod wod) =>
      WodTimer(format: wod.format, timeCapSeconds: wod.timeCapSeconds);

  static const tabataWorkSeconds = 20;
  static const tabataRestSeconds = 10;
  static const tabataRounds = 8;
  static const emomRoundSeconds = 60;

  final WodFormat format;
  final int? timeCapSeconds;

  /// Cuánto dura como mucho; nulo en «por tiempo» sin límite.
  int? get totalSeconds => switch (format) {
    WodFormat.tabata => tabataRounds * (tabataWorkSeconds + tabataRestSeconds),
    _ => timeCapSeconds,
  };

  /// Rondas que marca el propio reloj (EMOM y Tabata).
  int? get totalRounds => switch (format) {
    WodFormat.tabata => tabataRounds,
    WodFormat.emom =>
      timeCapSeconds == null ? null : timeCapSeconds! ~/ emomRoundSeconds,
    _ => null,
  };

  WodTick at(int elapsedSeconds) {
    final total = totalSeconds;
    final elapsed = elapsedSeconds < 0 ? 0 : elapsedSeconds;
    if (total != null && elapsed >= total) {
      return WodTick(
        phase: WodPhase.done,
        round: totalRounds ?? 1,
        clockSeconds: format == WodFormat.forTime ? total : 0,
        countsDown: format != WodFormat.forTime,
        elapsedSeconds: total,
      );
    }
    switch (format) {
      case WodFormat.forTime:
        return WodTick(
          phase: WodPhase.work,
          round: 1,
          clockSeconds: elapsed,
          countsDown: false,
          elapsedSeconds: elapsed,
        );
      case WodFormat.amrap:
        return WodTick(
          phase: WodPhase.work,
          round: 1,
          // Sin límite (no debería pasar: el servidor lo exige) cuenta hacia
          // delante en vez de inventar uno.
          clockSeconds: total == null ? elapsed : total - elapsed,
          countsDown: total != null,
          elapsedSeconds: elapsed,
        );
      case WodFormat.emom:
        return WodTick(
          phase: WodPhase.work,
          round: elapsed ~/ emomRoundSeconds + 1,
          clockSeconds: emomRoundSeconds - elapsed % emomRoundSeconds,
          countsDown: true,
          elapsedSeconds: elapsed,
        );
      case WodFormat.tabata:
        const cycle = tabataWorkSeconds + tabataRestSeconds;
        final inCycle = elapsed % cycle;
        final working = inCycle < tabataWorkSeconds;
        return WodTick(
          phase: working ? WodPhase.work : WodPhase.rest,
          round: elapsed ~/ cycle + 1,
          clockSeconds: working ? tabataWorkSeconds - inCycle : cycle - inCycle,
          countsDown: true,
          elapsedSeconds: elapsed,
        );
    }
  }
}
