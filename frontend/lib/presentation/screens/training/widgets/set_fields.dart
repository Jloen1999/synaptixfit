import 'package:flutter/material.dart';

import '../../../../domain/models/training/set_fields.dart';
import '../../../extensions/context_extensions.dart';

export '../../../../domain/models/training/set_fields.dart';

/// Textos de cada campo de serie ([SetField]).
extension SetFieldLabel on SetField {
  /// Cabecera corta de la columna («Reps», «Kg», «Seg»…).
  String header(BuildContext context) {
    final l10n = context.localizations;
    return switch (this) {
      SetField.reps => l10n.trainingSetColReps,
      SetField.weight => l10n.trainingSetColKg,
      SetField.hold => l10n.trainingSetColSeconds,
      SetField.duration => l10n.trainingSetColMinutes,
      SetField.distance => l10n.trainingSetColMeters,
    };
  }

  /// Nombre completo para el lector de pantalla («repeticiones», «kilos»…).
  String spoken(BuildContext context) {
    final l10n = context.localizations;
    return switch (this) {
      SetField.reps => l10n.trainingSetFieldReps,
      SetField.weight => l10n.trainingSetFieldKg,
      SetField.hold => l10n.trainingSetFieldSeconds,
      SetField.duration => l10n.trainingSetFieldMinutes,
      SetField.distance => l10n.trainingSetFieldMeters,
    };
  }
}
