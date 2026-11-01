import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../../domain/enums/friendship_list_kind.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../../domain/models/account/account.dart';
import '../../../../../domain/models/profile/profile_summary.dart';
import '../../../../../domain/use_cases/account/get_account_use_case.dart';
import '../../../../../domain/use_cases/profile/get_profile_summary_use_case.dart';
import '../../../../../domain/use_cases/social/get_friendships_use_case.dart';

part 'profile_bloc.freezed.dart';
part 'profile_event.dart';
part 'profile_state.dart';

/// Pantalla de perfil: cuenta (nivel, racha), resumen del perfil y número de
/// solicitudes de amistad pendientes (con [GetFriendshipsUseCaseContract]).
class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required this._getAccount,
    required this._getSummary,
    required this._getFriendships,
  }) : super(const ProfileState()) {
    on<ProfileStarted>((_, emit) => _load(emit, showLoading: true));
    on<ProfileRefreshed>((_, emit) => _load(emit, showLoading: false));
  }

  final GetAccountUseCaseContract _getAccount;
  final GetProfileSummaryUseCaseContract _getSummary;
  final GetFriendshipsUseCaseContract _getFriendships;

  Future<void> _load(
    Emitter<ProfileState> emit, {
    required bool showLoading,
  }) async {
    if (showLoading || state.summary == null) {
      emit(state.copyWith(status: ProfileStatus.loading, error: null));
    } else {
      emit(state.copyWith(refreshing: true, error: null));
    }
    // Solo hace falta el total de solicitudes recibidas: una página de uno.
    final (accountResult, summaryResult, requestsResult) = await (
      _getAccount(),
      _getSummary(),
      _getFriendships(kind: FriendshipListKind.received, size: 1),
    ).wait;
    final error = accountResult.errorOrNull ?? summaryResult.errorOrNull;
    if (error != null) {
      emit(
        state.copyWith(
          status: state.summary == null
              ? ProfileStatus.failure
              : ProfileStatus.ready,
          error: error,
          refreshing: false,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: ProfileStatus.ready,
        account: accountResult.valueOrNull,
        summary: summaryResult.valueOrNull,
        // Si el recuento falla no se avisa: es un extra, no impide usar el perfil.
        pendingRequests:
            requestsResult.valueOrNull?.totalItems ?? state.pendingRequests,
        error: null,
        refreshing: false,
      ),
    );
  }
}
