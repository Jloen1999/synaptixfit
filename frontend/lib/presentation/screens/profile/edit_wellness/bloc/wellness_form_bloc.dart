import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/profile/activity_level.dart';
import '../../../../../domain/enums/profile/sex.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/profile/wellness_history.dart';
import '../../../../../domain/models/profile/wellness_profile.dart';
import '../../../../../domain/use_cases/profile/get_profile_summary_use_case.dart';
import '../../../../../domain/use_cases/profile/save_wellness_profile_use_case.dart';
import '../../../../../domain/use_cases/profile/suggest_goals_use_case.dart';
import '../../../../../domain/use_cases/profile/update_wellness_profile_use_case.dart';

part 'wellness_form_bloc.freezed.dart';
part 'wellness_form_event.dart';
part 'wellness_form_state.dart';

/// Formulario del perfil físico (onboarding y edición).
///
/// Si el usuario aún no tiene perfil se crea completo (PUT); si ya lo tiene se
/// edita con PATCH para conservar lo que el formulario no muestra.
class WellnessFormBloc extends Bloc<WellnessFormEvent, WellnessFormState> {
  WellnessFormBloc({
    required this._getSummary,
    required this._saveProfile,
    required this._updateProfile,
    required this._suggestGoals,
  }) : super(const WellnessFormState()) {
    on<WellnessFormStarted>(_onStarted);
    on<WellnessFormSubmitted>(_onSubmitted);
    on<WellnessFormSuggestionsRequested>(_onSuggestions);
  }

  final GetProfileSummaryUseCaseContract _getSummary;
  final SaveWellnessProfileUseCaseContract _saveProfile;
  final UpdateWellnessProfileUseCaseContract _updateProfile;
  final SuggestGoalsUseCaseContract _suggestGoals;

  Future<void> _onStarted(
    WellnessFormStarted event,
    Emitter<WellnessFormState> emit,
  ) async {
    if (!event.loadExisting) {
      emit(state.copyWith(status: WellnessFormStatus.ready));
      return;
    }
    emit(state.copyWith(status: WellnessFormStatus.loading, loadError: null));
    final result = await _getSummary();
    emit(
      result.fold(
        (summary) => state.copyWith(
          status: WellnessFormStatus.ready,
          initial: summary.wellness,
        ),
        (error) => state.copyWith(
          status: WellnessFormStatus.failure,
          loadError: error,
        ),
      ),
    );
  }

  Future<void> _onSubmitted(
    WellnessFormSubmitted event,
    Emitter<WellnessFormState> emit,
  ) async {
    emit(state.copyWith(saving: true, actionError: null, saved: null));
    final result = state.initial == null
        ? await _saveProfile(event.draft)
        : await _updateProfile(event.draft);
    emit(
      result.fold(
        (profile) =>
            state.copyWith(saving: false, initial: profile, saved: profile),
        (error) => state.copyWith(saving: false, actionError: error),
      ),
    );
  }

  Future<void> _onSuggestions(
    WellnessFormSuggestionsRequested event,
    Emitter<WellnessFormState> emit,
  ) async {
    emit(state.copyWith(suggesting: true, actionError: null));
    final result = await _suggestGoals(
      age: event.age,
      sex: event.sex,
      activityLevel: event.activityLevel,
    );
    emit(
      result.fold(
        (suggestions) =>
            state.copyWith(suggesting: false, suggestions: suggestions),
        (error) => state.copyWith(suggesting: false, actionError: error),
      ),
    );
  }
}
