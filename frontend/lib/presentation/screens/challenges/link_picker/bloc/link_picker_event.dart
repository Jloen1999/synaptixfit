part of 'link_picker_bloc.dart';

@freezed
sealed class LinkPickerEvent with _$LinkPickerEvent {
  /// Carga las entregas y exámenes que vencen en el periodo del reto
  /// ([from]-[to]), filtrados por [subjectId] si se indica.
  const factory LinkPickerEvent.started({
    String? subjectId,
    DateTime? from,
    DateTime? to,
  }) = LinkPickerStarted;
}
