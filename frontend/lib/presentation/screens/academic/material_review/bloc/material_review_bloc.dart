import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/study_material.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/use_cases/academic/get_review_history_use_case.dart';
import '../../../../../domain/use_cases/academic/get_review_preview_use_case.dart';
import '../../../../../domain/use_cases/academic/get_study_material_use_case.dart';
import '../../../../../domain/use_cases/academic/review_study_material_use_case.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';

part 'material_review_bloc.freezed.dart';
part 'material_review_event.dart';
part 'material_review_state.dart';

/// Repaso espaciado de un material: autoevaluación 0-5 con el intervalo que
/// resulta de cada nivel e historial de repasos.
class MaterialReviewBloc
    extends Bloc<MaterialReviewEvent, MaterialReviewState> {
  MaterialReviewBloc({
    required this._getMaterial,
    required this._getPreview,
    required this._getHistory,
    required this._review,
    required this._getAccount,
  }) : super(const MaterialReviewState()) {
    on<MaterialReviewStarted>(_onStarted);
    on<MaterialReviewQualitySubmitted>(_onSubmitted);
  }

  final GetStudyMaterialUseCaseContract _getMaterial;
  final GetReviewPreviewUseCaseContract _getPreview;
  final GetReviewHistoryUseCaseContract _getHistory;
  final ReviewStudyMaterialUseCaseContract _review;
  final GetAccountUseCaseContract _getAccount;

  Future<void> _onStarted(
    MaterialReviewStarted event,
    Emitter<MaterialReviewState> emit,
  ) async {
    emit(
      state.copyWith(
        materialId: event.materialId,
        loading: true,
        error: null,
        outcome: null,
      ),
    );
    final (material, preview, history) = await (
      _getMaterial(event.materialId),
      _getPreview(event.materialId),
      _getHistory(event.materialId),
    ).wait;
    final error = material.errorOrNull ?? preview.errorOrNull;
    emit(
      error != null
          ? state.copyWith(loading: false, error: error)
          : state.copyWith(
              loading: false,
              material: material.valueOrNull,
              preview: preview.valueOrNull,
              history: history.valueOrNull ?? const [],
            ),
    );
  }

  Future<void> _onSubmitted(
    MaterialReviewQualitySubmitted event,
    Emitter<MaterialReviewState> emit,
  ) async {
    emit(state.copyWith(submitting: true, actionError: null));
    final result = await _review(state.materialId, event.quality);
    switch (result.errorOrNull) {
      case final AppError error:
        emit(state.copyWith(submitting: false, actionError: error));
        return;
      case null:
        break;
    }
    final outcome = result.valueOrNull!;
    emit(
      state.copyWith(
        submitting: false,
        outcome: outcome,
        material: outcome.material,
        history: [?outcome.review, ...state.history],
      ),
    );
    // Si el repaso dio XP, refresca la cuenta para el nivel global.
    if (outcome.xpAwarded <= 0) return;
    final account = await _getAccount();
    if (account.valueOrNull case final Account a) {
      emit(state.copyWith(updatedAccount: a));
    }
  }
}
