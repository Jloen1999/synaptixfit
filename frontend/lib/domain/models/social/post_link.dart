import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_link.freezed.dart';

/// Contenido de la app al que se refiere una publicación.
enum PostLinkKind { routine, challenge, badge, note }

/// Enlace opcional de una publicación a una rutina, reto, insignia o apunte
/// (se lee de los metadatos de la publicación). Un apunte no lleva nombre en
/// los metadatos ([name] vacío): su título ya es el texto de la publicación.
@freezed
abstract class PostLink with _$PostLink {
  const factory PostLink({
    required PostLinkKind kind,
    String? id,
    required String name,
  }) = _PostLink;
}
