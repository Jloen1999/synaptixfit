part of 'generation_center_bloc.dart';

@freezed
abstract class GenerationCenterState with _$GenerationCenterState {
  const factory GenerationCenterState({
    @Default(true) bool loading,
    AppError? error,
    @Default(<Subject>[]) List<Subject> subjects,
    String? subjectId,
    @Default(false) bool loadingSources,
    AppError? sourcesError,
    @Default(<Note>[]) List<Note> notes,

    /// Solo los archivos que la IA puede leer.
    @Default(<SubjectFile>[]) List<SubjectFile> files,
    @Default(<StudySourceRef>{}) Set<StudySourceRef> selected,
    @Default(ArtifactKind.summary) ArtifactKind kind,
    @Default(false) bool generating,
    AppError? generateError,
    StudyArtifact? artifact,
    @Default(false) bool saving,
    AppError? saveError,

    /// Apunte creado al guardar un resumen o mapa.
    String? savedNoteId,

    /// Material creado al guardar preguntas.
    String? savedMaterialId,

    /// Subiendo un archivo desde «Subir archivo».
    @Default(false) bool uploading,
    AppError? uploadError,

    /// Resultado de la última subida (cambia en cada una): la página avisa si
    /// la IA no puede leer el archivo y por eso no sale entre las fuentes.
    FileUploadOutcome? uploadOutcome,
  }) = _GenerationCenterState;
}

/// Qué pasó con el archivo subido desde el centro de generación.
enum FileUploadOutcome { readable, unreadable }
