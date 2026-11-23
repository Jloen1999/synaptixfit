part of 'quick_check_in_bloc.dart';

@freezed
abstract class QuickCheckInState with _$QuickCheckInState {
  const factory QuickCheckInState({
    @Default(true) bool loading,

    /// Adaptación de hoy y si ya hay registro (nula hasta cargar).
    TodayAdaptation? adaptation,

    /// Preguntando de nuevo aunque ya estuviera hecho.
    @Default(false) bool editing,
    @Default(false) bool sending,

    /// Se acaba de enviar: la explicación se anuncia al lector solo entonces,
    /// no cada vez que se abre Rutinas con el registro ya hecho.
    @Default(false) bool justSent,

    /// Cuándo se guardó el registro desde esta tarjeta: «Guardado hoy a las
    /// 9:41» se queda a la vista (ADR 0062). Nulo si no se ha guardado aquí.
    DateTime? savedAt,

    /// Lo guardado desde esta tarjeta: el registro de hoy cuenta como hecho
    /// aunque luego falle la lectura de la adaptación, y «Cambiar» parte de
    /// ello si esa lectura no lo trae.
    QuickCheckIn? saved,

    /// Lo contestado en las tres preguntas.
    @Default(CheckInAnswers()) CheckInAnswers answers,

    /// Sube cada vez que toca guardar solo (regla de los tres toques): la
    /// tarjeta pide antes el permiso de datos de salud y envía.
    @Default(0) int saveRequest,

    /// No se pudo leer la adaptación de hoy (al entrar o tras guardar): se
    /// dice con «Reintentar», que la vuelve a leer.
    AppError? loadError,

    /// Se está volviendo a leer tras «Reintentar».
    @Default(false) bool reloading,

    /// No se pudo guardar el registro: se dice con «Reintentar», que guarda.
    AppError? saveError,
  }) = _QuickCheckInState;

  const QuickCheckInState._();

  /// Registro de hoy hecho: lo dice el servidor o se acaba de guardar aquí.
  bool get doneToday => saved != null || (adaptation?.checkInDone ?? false);

  /// Enseñar las tres preguntas (no hay registro hoy o se quiere cambiar).
  bool get asking => editing || !doneToday;
}
