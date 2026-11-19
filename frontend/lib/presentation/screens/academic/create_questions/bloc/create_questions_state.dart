part of 'create_questions_bloc.dart';

/// Apunte o archivo de la asignatura del que se pueden crear preguntas.
@freezed
abstract class QuestionSourceOption with _$QuestionSourceOption {
  const factory QuestionSourceOption({
    required StudySourceType type,
    required String id,
    required String title,
  }) = _QuestionSourceOption;
}

/// Hoja «Crear preguntas» y su revisión (ADR 0058). Las opciones del
/// documento y de las que ya tienes solo salen cuando aplican.
@freezed
abstract class CreateQuestionsState with _$CreateQuestionsState {
  const factory CreateQuestionsState({
    /// Asignatura (si se abrió desde Resumen › Practicar): permite elegir y
    /// cambiar de apunte.
    String? subjectId,
    @Default(false) bool loadingSources,
    AppError? sourcesError,
    @Default(<QuestionSourceOption>[]) List<QuestionSourceOption> sources,

    /// Se está eligiendo el apunte (lista de apuntes y archivos).
    @Default(false) bool choosingSource,

    String? materialId,
    String? title,
    @Default(false) bool preparing,
    AppError? prepareError,

    /// Preguntas que ya tiene el material.
    @Default(0) int existingCount,
    @Default(false) bool scanning,
    AppError? scanError,
    DocumentQuestionScan? scan,

    @Default(QuestionFormat.mixed) QuestionFormat format,
    @Default(QuestionCount.initial) int count,
    @Default(DocumentQuestionUse.mix) DocumentQuestionUse documentUse,
    @Default(BankUpdateMode.add) BankUpdateMode mode,

    /// Preguntas del documento en revisión (con las respuestas cambiadas) y
    /// cuáles se usan (por posición).
    @Default(<DocumentQuestion>[]) List<DocumentQuestion> reviewed,
    @Default(<int>{}) Set<int> used,

    /// Sube cada vez que hay que abrir la revisión.
    @Default(0) int reviewRequest,

    @Default(false) bool saving,
    AppError? saveError,

    /// Banco guardado: la hoja se cierra con él.
    QuestionBank? saved,
  }) = _CreateQuestionsState;

  const CreateQuestionsState._();

  List<DocumentQuestion> get documentQuestions =>
      scan?.questions ?? const <DocumentQuestion>[];

  int get usableDocumentCount =>
      documentQuestions.where((q) => q.usable).length;

  /// «Tu apunte ya trae N preguntas»: solo si alguna se puede usar.
  bool get showsDocumentChoice => usableDocumentCount > 0;

  /// «Ya tienes N de este apunte»: solo si ya hay preguntas.
  bool get showsModeChoice => existingCount > 0;

  /// Se usan preguntas del documento: antes de guardar se revisan.
  bool get usesDocument =>
      showsDocumentChoice && documentUse != DocumentQuestionUse.none;

  /// El tipo y la cantidad no aplican si solo se usan las del documento.
  bool get asksNewQuestions =>
      !usesDocument || documentUse == DocumentQuestionUse.mix;

  bool get ready => materialId != null && !preparing && prepareError == null;

  int get usedCount => used.length;

  /// Nuevas que se crearán según lo marcado en la revisión (o sin ella).
  int get newCount => usesDocument
      ? QuestionCount.newQuestions(
          use: documentUse,
          total: count,
          fromDocument: usedCount,
        )
      : count;

  /// Total que se guardará.
  int get totalToSave => (usesDocument ? usedCount : 0) + newCount;

  /// Modo efectivo: sin preguntas previas da igual; se manda «añadir».
  BankUpdateMode get effectiveMode =>
      showsModeChoice ? mode : BankUpdateMode.add;
}
