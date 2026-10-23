part of 'link_picker_bloc.dart';

@freezed
sealed class LinkPickerEvent with _$LinkPickerEvent {
  /// Carga entregas y bloques (filtrados por [subjectId] si se indica).
  const factory LinkPickerEvent.started({String? subjectId}) =
      LinkPickerStarted;
}
