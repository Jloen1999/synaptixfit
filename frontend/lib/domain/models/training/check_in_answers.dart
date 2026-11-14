import 'package:freezed_annotation/freezed_annotation.dart';

part 'check_in_answers.freezed.dart';

/// Sentido de una escala 1-5 del registro diario. En pantalla todas van igual
/// (a la derecha, lo mejor: ADR 0039), pero el servidor guarda las de siempre:
/// en sueño y energía 5 es lo mejor; en agujetas y estrés, 1.
enum CheckInScale {
  higherIsBetter,
  lowerIsBetter;

  /// Valores de la escala de peor a mejor (de izquierda a derecha).
  List<int> get worstToBest =>
      this == higherIsBetter ? const [1, 2, 3, 4, 5] : const [5, 4, 3, 2, 1];

  /// Las tres respuestas de un toque, de peor a mejor: los extremos y el centro.
  List<int> get threeWorstToBest =>
      this == higherIsBetter ? const [1, 3, 5] : const [5, 3, 1];

  /// La respuesta de un toque que se marca para un valor guardado (un registro
  /// antiguo puede traer un 2 o un 4: se marca la más cercana).
  static int? snap(int? value) => switch (value) {
    null => null,
    <= 2 => 1,
    3 => 3,
    _ => 5,
  };
}

/// Las tres preguntas de un toque de «¿Qué tal estás hoy?» y su escala.
enum CheckInQuestion {
  sleep(CheckInScale.higherIsBetter),
  energy(CheckInScale.higherIsBetter),
  soreness(CheckInScale.lowerIsBetter);

  const CheckInQuestion(this.scale);

  final CheckInScale scale;
}

/// Respuestas dadas a las tres preguntas (las que faltan no están). Guarda la
/// regla de los tres toques en un solo sitio: la usan los blocs de la tarjeta
/// de Gimnasio y de la pantalla del registro.
@freezed
abstract class CheckInAnswers with _$CheckInAnswers {
  const factory CheckInAnswers({
    @Default(<CheckInQuestion, int>{}) Map<CheckInQuestion, int> values,
  }) = _CheckInAnswers;

  const CheckInAnswers._();

  /// Las tres contestadas (un registro ya guardado hoy).
  factory CheckInAnswers.all({
    required int sleep,
    required int energy,
    required int soreness,
  }) => CheckInAnswers(
    values: {
      CheckInQuestion.sleep: sleep,
      CheckInQuestion.energy: energy,
      CheckInQuestion.soreness: soreness,
    },
  );

  int? operator [](CheckInQuestion question) => values[question];

  bool get complete => values.length == CheckInQuestion.values.length;

  CheckInAnswers withAnswer(CheckInQuestion question, int value) =>
      CheckInAnswers(values: {...values, question: value});

  /// La primera vez del día y sin los detalles abiertos, la respuesta que
  /// completa las tres guarda sola (avisado antes de contestar). Al cambiar un
  /// registro ya hecho, o con detalles, se guarda con «Guardar».
  static bool savesOnLastAnswer({
    required bool loggedToday,
    required bool withDetails,
  }) => !loggedToday && !withDetails;
}
