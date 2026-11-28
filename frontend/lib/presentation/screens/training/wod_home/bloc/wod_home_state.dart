part of 'wod_home_bloc.dart';

enum WodHomeStatus { loading, ready, failure }

@freezed
abstract class WodHomeState with _$WodHomeState {
  const factory WodHomeState({
    @Default(WodHomeStatus.loading) WodHomeStatus status,
    AppError? error,
    WodBoard? board,
    @Default(<Wod>[]) List<Wod> templates,
    @Default(<WodMark>[]) List<WodMark> marks,

    /// Plantilla de ejemplo elegida a mano; nula = la que diga el servidor.
    String? templateCode,
    @Default(WodDivision.rx) WodDivision division,
    @Default(false) bool saving,

    /// Marca recién guardada: la página la anuncia una vez.
    WodMark? saved,
    AppError? actionError,
  }) = _WodHomeState;
}
