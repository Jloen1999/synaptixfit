part of 'admin_reports_bloc.dart';

/// Resultado puntual de una acción de moderación.
@freezed
sealed class AdminReportsEffect with _$AdminReportsEffect {
  const factory AdminReportsEffect.dismissed() = AdminReportsDismissedEffect;

  const factory AdminReportsEffect.removed() = AdminReportsRemovedEffect;

  const factory AdminReportsEffect.failure(AppError error) =
      AdminReportsFailureEffect;
}

@freezed
abstract class AdminReportsState with _$AdminReportsState {
  const factory AdminReportsState({
    @Default(AdminStatus.initial) AdminStatus status,
    AdminReportType? type,
    @Default(0) int page,
    AdminPage<ReportedContent>? reports,

    /// Contenido sobre el que hay una acción en curso.
    String? busyId,
    AdminReportsEffect? effect,
    AppError? error,
  }) = _AdminReportsState;
}
