import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_link.freezed.dart';

/// Contenido de la app al que se refiere una publicación.
enum PostLinkKind { routine, challenge, badge }

/// Enlace opcional de una publicación a una rutina, reto o insignia
/// (se lee de los metadatos de la publicación).
@freezed
abstract class PostLink with _$PostLink {
  const factory PostLink({
    required PostLinkKind kind,
    String? id,
    required String name,
  }) = _PostLink;
}
