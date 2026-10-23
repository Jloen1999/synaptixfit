import 'package:freezed_annotation/freezed_annotation.dart';

part 'social_user.freezed.dart';

/// Usuario tal como se muestra en el módulo social (autor, amigo…).
@freezed
abstract class SocialUser with _$SocialUser {
  const factory SocialUser({
    required String id,
    required String fullName,
    String? avatarUrl,
    int? level,
  }) = _SocialUser;
}
