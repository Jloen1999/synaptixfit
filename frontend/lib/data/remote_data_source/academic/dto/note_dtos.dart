import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/visibility.dart';
import '../../../../domain/models/academic/note.dart';

part 'note_dtos.freezed.dart';
part 'note_dtos.g.dart';

@freezed
abstract class NoteDto with _$NoteDto {
  const factory NoteDto({
    required String id,
    String? subjectId,
    @Default('') String title,
    String? content,
    String? visibility,
    @Default(false) bool quickNote,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _NoteDto;

  const NoteDto._();

  factory NoteDto.fromJson(Map<String, dynamic> json) =>
      _$NoteDtoFromJson(json);

  Note toDomain() => Note(
    id: id,
    subjectId: subjectId,
    title: title,
    content: content ?? '',
    visibility: Visibility.fromApi(visibility),
    quickNote: quickNote,
    createdAt: createdAt?.toLocal(),
    updatedAt: updatedAt?.toLocal(),
  );
}

@freezed
abstract class NotePageDto with _$NotePageDto {
  const factory NotePageDto({
    @Default(<NoteDto>[]) List<NoteDto> items,
    @Default(0) int page,
    @Default(0) int totalPages,
  }) = _NotePageDto;

  factory NotePageDto.fromJson(Map<String, dynamic> json) =>
      _$NotePageDtoFromJson(json);
}

@freezed
abstract class SharedNoteDto with _$SharedNoteDto {
  const factory SharedNoteDto({
    required String id,
    required String authorId,
    @Default('') String authorName,
    String? authorAvatarUrl,
    String? subjectId,
    @Default('') String title,
    String? content,
    String? visibility,
    DateTime? updatedAt,
  }) = _SharedNoteDto;

  const SharedNoteDto._();

  factory SharedNoteDto.fromJson(Map<String, dynamic> json) =>
      _$SharedNoteDtoFromJson(json);

  SharedNote toDomain() => SharedNote(
    id: id,
    authorId: authorId,
    authorName: authorName,
    authorAvatarUrl: authorAvatarUrl,
    subjectId: subjectId,
    title: title,
    content: content ?? '',
    visibility: Visibility.fromApi(visibility),
    updatedAt: updatedAt?.toLocal(),
  );
}

@freezed
abstract class SharedNotePageDto with _$SharedNotePageDto {
  const factory SharedNotePageDto({
    @Default(<SharedNoteDto>[]) List<SharedNoteDto> items,
    @Default(0) int page,
    @Default(0) int totalPages,
  }) = _SharedNotePageDto;

  const SharedNotePageDto._();

  factory SharedNotePageDto.fromJson(Map<String, dynamic> json) =>
      _$SharedNotePageDtoFromJson(json);

  SharedNotesPage toDomain() => SharedNotesPage(
    items: items.map((n) => n.toDomain()).toList(),
    page: page,
    totalPages: totalPages,
  );
}
