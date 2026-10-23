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
  }) = _GenerationCenterState;
}
