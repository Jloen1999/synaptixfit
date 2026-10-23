import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/models/social/social_user.dart';

part 'social_user_dto.freezed.dart';
part 'social_user_dto.g.dart';

/// Autor de publicación/comentario (`AuthorResponse`) o usuario de una
/// amistad (`SocialUserResponse`, que añade el nivel).
@freezed
abstract class SocialUserDto with _$SocialUserDto {
  const factory SocialUserDto({
    required String id,
    @Default('') String fullName,
    String? avatarUrl,
    int? level,
  }) = _SocialUserDto;

  const SocialUserDto._();

  factory SocialUserDto.fromJson(Map<String, dynamic> json) =>
      _$SocialUserDtoFromJson(json);

  SocialUser toDomain() => SocialUser(
    id: id,
    fullName: fullName,
    avatarUrl: avatarUrl,
    level: level,
  );
}
