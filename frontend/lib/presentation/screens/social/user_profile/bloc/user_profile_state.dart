part of 'user_profile_bloc.dart';

@freezed
abstract class UserProfileState with _$UserProfileState {
  const factory UserProfileState({
    @Default('') String userId,
    @Default(SocialLoadStatus.loading) SocialLoadStatus status,
    PublicProfile? profile,
    @Default(<Post>[]) List<Post> posts,
    @Default(0) int postsPage,
    @Default(false) bool hasMorePosts,
    @Default(false) bool loadingMorePosts,

    /// Error al cargar las publicaciones (el perfil sí se cargó).
    AppError? postsError,

    /// Apuntes que comparte conmigo (los primeros) y si hay más.
    @Default(<SharedNoteSummary>[]) List<SharedNoteSummary> notes,
    @Default(false) bool hasMoreNotes,
    AppError? notesError,

    /// Acción de relación en curso.
    @Default(false) bool busy,
    @Default(false) bool refreshing,
    AppError? error,
    SocialFeedback? feedback,
  }) = _UserProfileState;
}
