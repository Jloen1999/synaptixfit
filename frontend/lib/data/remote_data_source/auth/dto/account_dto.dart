import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../domain/enums/usage_focus.dart';
import '../../../../domain/enums/user_role.dart';
import '../../../../domain/enums/visibility.dart';
import '../../../../domain/models/account/account.dart';

part 'account_dto.freezed.dart';
part 'account_dto.g.dart';

@freezed
abstract class AccountDto with _$AccountDto {
  const factory AccountDto({
    required String id,
    required String email,
    required String fullName,
    String? avatarUrl,
    required int level,
    required int levelXp,
    required int levelThreshold,
    required int streak,
    required String privacy,
    required String role,
    required bool hasPassword,
    required bool googleLinked,
    String? usageFocus,
    @Default(true) bool usageFocusChosen,
  }) = _AccountDto;

  const AccountDto._();

  factory AccountDto.fromJson(Map<String, dynamic> json) =>
      _$AccountDtoFromJson(json);

  Account toDomain() => Account(
    id: id,
    email: email,
    fullName: fullName,
    avatarUrl: avatarUrl,
    level: level,
    levelXp: levelXp,
    levelThreshold: levelThreshold,
    streak: streak,
    privacy: Visibility.fromApi(privacy),
    role: UserRole.fromApi(role),
    hasPassword: hasPassword,
    googleLinked: googleLinked,
    usageFocus: UsageFocus.fromApi(usageFocus),
    usageFocusChosen: usageFocusChosen,
  );
}
