import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/academic/quiz.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/use_cases/academic/export_flashcards_to_anki_use_case.dart';
import '../../../../../domain/use_cases/academic/get_question_bank_use_case.dart';
import '../../../../../domain/use_cases/academic/get_study_material_use_case.dart';
import '../../../../../domain/use_cases/academic/review_flashcards_use_case.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';

part 'flashcards_bloc.freezed.dart';
part 'flashcards_event.dart';
part 'flashcards_state.dart';

/// Flashcards con las preguntas del banco: el usuario clasifica cada tarjeta
/// como dominada, dudosa o fallada y al final se registra la ronda.
class FlashcardsBloc extends Bloc<FlashcardsEvent, FlashcardsState> {
  FlashcardsBloc({
    required this._getBank,
    required this._getMaterial,
    required this._reviewFlashcards,
    required this._exportAnki,
    required this._getAccount,
  }) : super(const FlashcardsState()) {
    on<FlashcardsStarted>(_onStarted);
    on<FlashcardsFlipped>(
      (_, emit) => emit(state.copyWith(flipped: !state.flipped)),
    );
    on<FlashcardsRated>(_onRated);
    on<FlashcardsRestarted>(
      (_, emit) => emit(
        state.copyWith(
          index: 0,
          flipped: false,
          ratings: const [],
          result: null,
          actionError: null,
        ),
      ),
    );
    on<FlashcardsSubmitRetried>((_, emit) => _submit(emit));
    on<FlashcardsAnkiExportRequested>(_onAnkiExport);
  }

  final GetQuestionBankUseCaseContract _getBank;
  final GetStudyMaterialUseCaseContract _getMaterial;
  final ReviewFlashcardsUseCaseContract _reviewFlashcards;
  final ExportFlashcardsToAnkiUseCaseContract _exportAnki;
  final GetAccountUseCaseContract _getAccount;

  Future<void> _onStarted(
    FlashcardsStarted event,
    Emitter<FlashcardsState> emit,
  ) async {
    emit(
      state.copyWith(materialId: event.materialId, loading: true, error: null),
    );
    final (result, material) = await (
      _getBank(event.materialId),
      _getMaterial(event.materialId),
    ).wait;
    // El título solo da nombre al mazo de Anki: si falla, se usa uno genérico.
    final base = state.copyWith(deckName: material.valueOrNull?.title);
    emit(
      result.fold(
        (bank) => bank == null || bank.questions.isEmpty
            ? base.copyWith(
                loading: false,
                error: const AppError.business('QUIZ_BANK_EMPTY'),
              )
            : base.copyWith(loading: false, cards: bank.questions),
        (error) => base.copyWith(loading: false, error: error),
      ),
    );
  }

  Future<void> _onRated(
    FlashcardsRated event,
    Emitter<FlashcardsState> emit,
  ) async {
    if (state.finished) return;
    final ratings = [...state.ratings, event.rating];
    emit(
      state.copyWith(ratings: ratings, index: state.index + 1, flipped: false),
    );
    if (state.finished) await _submit(emit);
  }

  Future<void> _onAnkiExport(
    FlashcardsAnkiExportRequested event,
    Emitter<FlashcardsState> emit,
  ) async {
    if (state.exportingAnki || state.cards.isEmpty) return;
    emit(state.copyWith(exportingAnki: true, actionError: null));
    final result = await _exportAnki(
      deck: state.deckName ?? event.fallbackDeck,
      cards: state.cards,
    );
    emit(
      result.fold(
        (saved) => state.copyWith(
          exportingAnki: false,
          ankiExports: saved ? state.ankiExports + 1 : state.ankiExports,
        ),
        (error) => state.copyWith(exportingAnki: false, actionError: error),
      ),
    );
  }

  Future<void> _submit(Emitter<FlashcardsState> emit) async {
    emit(state.copyWith(submitting: true, actionError: null));
    final result = await _reviewFlashcards(
      state.materialId,
      mastered: state.count(FlashcardRating.mastered),
      doubtful: state.count(FlashcardRating.doubtful),
      failed: state.count(FlashcardRating.failed),
    );
    switch (result.errorOrNull) {
      case final AppError error:
        emit(state.copyWith(submitting: false, actionError: error));
        return;
      case null:
        break;
    }
    emit(state.copyWith(submitting: false, result: result.valueOrNull));
    if ((result.valueOrNull?.xpAwarded ?? 0) > 0) {
      final account = await _getAccount();
      if (account.valueOrNull case final Account a) {
        emit(state.copyWith(updatedAccount: a));
      }
    }
  }
}
