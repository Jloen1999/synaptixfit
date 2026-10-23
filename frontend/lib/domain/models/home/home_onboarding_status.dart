import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_onboarding_status.freezed.dart';

/// Estado del alta del usuario (perfil físico, académico y asignaturas).
@freezed
abstract class HomeOnboardingStatus with _$HomeOnboardingStatus {
  const factory HomeOnboardingStatus({required bool completed}) =
      _HomeOnboardingStatus;
}
