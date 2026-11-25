part of 'material_share_bloc.dart';

/// Las formas de compartir un material y «Descargar» (ADR 0064).
enum MaterialShareAction { friend, everyone, wall, outside, download }

/// Lo que acaba de pasar, para el aviso con «dónde queda» y «Ver».
@freezed
abstract class MaterialShareResult with _$MaterialShareResult {
  const factory MaterialShareResult({
    required MaterialShareAction action,
    required String materialId,

    /// A quién se pasó («Con un amigo»).
    String? friendName,

    /// Cómo quedó el apunte («Para todos», «En el muro»).
    Visibility? visibility,

    /// Ya estaba en el muro.
    @Default(false) bool alreadyShared,

    /// El archivo que se guardó o se mandó.
    String? fileName,

    /// `false` si la persona cerró el menú o el «Guardar como» sin terminar.
    @Default(true) bool completed,
  }) = _MaterialShareResult;
}

@freezed
abstract class MaterialShareState with _$MaterialShareState {
  const factory MaterialShareState({
    /// Lo que se está haciendo (una cosa a la vez).
    MaterialShareAction? running,
    MaterialShareResult? result,
    AppError? error,

    /// Lo que falló (acción y material), para «Reintentar».
    MaterialShareEvent? retry,

    /// Sube con cada resultado o error: el aviso sale aunque se repita.
    @Default(0) int seq,
  }) = _MaterialShareState;
}
