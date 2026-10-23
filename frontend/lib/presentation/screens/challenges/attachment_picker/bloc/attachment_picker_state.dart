part of 'attachment_picker_bloc.dart';

enum AttachmentPickerStatus { loading, ready, failure }

@freezed
abstract class AttachmentPickerState with _$AttachmentPickerState {
  const factory AttachmentPickerState({
    @Default(AttachmentPickerStatus.loading) AttachmentPickerStatus status,
    @Default(<ChallengeSubjectOption>[]) List<ChallengeSubjectOption> subjects,
    String? subjectId,
    @Default(ChallengeAttachmentOptions()) ChallengeAttachmentOptions options,
    AppError? error,
  }) = _AttachmentPickerState;
}
