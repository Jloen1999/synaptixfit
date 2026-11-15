import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../../domain/enums/together_enums.dart';
import '../../../../../../domain/errors/app_error.dart';
import '../../../../../../domain/models/challenges/challenge_template.dart';
import '../../../../../../domain/models/result/result.dart';
import '../../../../../../domain/models/social/together.dart';
import '../../../../../../domain/use_cases/social/together/create_friend_challenge_use_case.dart';
import '../../../../../../domain/use_cases/social/together/get_friend_challenge_templates_use_case.dart';

part 'friend_challenge_form_bloc.freezed.dart';
part 'friend_challenge_form_event.dart';
part 'friend_challenge_form_state.dart';

/// «Nuevo reto con amigos» (ADR 0044): plantilla, días (7, 10 o 14), modo
/// (juntos por defecto) y amigos. Los amigos los elige `FriendPickerBloc`.
class FriendChallengeFormBloc
    extends Bloc<FriendChallengeFormEvent, FriendChallengeFormState> {
  FriendChallengeFormBloc({required this._templates, required this._create})
    : super(const FriendChallengeFormState()) {
    on<FriendChallengeFormStarted>(_onStarted);
    on<FriendChallengeFormTemplateSelected>(
      (e, emit) => emit(state.copyWith(templateId: e.templateId)),
    );
    on<FriendChallengeFormDaysChanged>(
      (e, emit) => emit(state.copyWith(days: e.days)),
    );
    on<FriendChallengeFormModeChanged>(
      (e, emit) => emit(state.copyWith(mode: e.mode)),
    );
    on<FriendChallengeFormSubmitted>(_onSubmitted);
  }

  /// Duraciones que se ofrecen (el servidor admite de 7 a 14 días).
  static const dayOptions = [7, 10, 14];

  final GetFriendChallengeTemplatesUseCaseContract _templates;
  final CreateFriendChallengeUseCaseContract _create;

  Future<void> _onStarted(
    FriendChallengeFormStarted event,
    Emitter<FriendChallengeFormState> emit,
  ) async {
    emit(
      state.copyWith(status: FriendChallengeFormStatus.loading, error: null),
    );
    final result = await _templates();
    emit(switch (result) {
      Success(:final value) => state.copyWith(
        status: FriendChallengeFormStatus.ready,
        templates: value,
        templateId: value.isEmpty ? null : value.first.id,
      ),
      Failure(:final error) => state.copyWith(
        status: FriendChallengeFormStatus.failure,
        error: error,
      ),
    });
  }

  Future<void> _onSubmitted(
    FriendChallengeFormSubmitted event,
    Emitter<FriendChallengeFormState> emit,
  ) async {
    final templateId = state.templateId;
    if (state.saving || templateId == null || event.friendIds.isEmpty) return;
    emit(state.copyWith(saving: true, saveError: null));
    final result = await _create(
      templateId: templateId,
      days: state.days,
      mode: state.mode,
      friendIds: event.friendIds,
    );
    emit(switch (result) {
      Success(:final value) => state.copyWith(saving: false, created: value),
      Failure(:final error) => state.copyWith(saving: false, saveError: error),
    });
    emit(state.copyWith(saveError: null));
  }
}
