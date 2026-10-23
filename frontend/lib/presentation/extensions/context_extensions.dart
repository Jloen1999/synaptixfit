import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/gen_l10n/app_localizations.dart';
import '../theme/tokens.g.dart';
import '../theme/app_palette.dart';

extension AppContext on BuildContext {
  AppLocalizations get localizations => AppLocalizations.of(this);

  ColorScheme get colors => Theme.of(this).colorScheme;

  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;

  TextTheme get textStyles => Theme.of(this).textTheme;

  /// [size] escalado con el tamaño de texto del sistema. Para alturas fijas
  /// que contienen texto (listas horizontales, barras): así no se cortan al
  /// 200 % (WCAG 1.4.4).
  double scaled(double size) => MediaQuery.textScalerOf(this).scale(size);

  /// El usuario ha pedido reducir el movimiento en su sistema.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);

  /// [duration] o cero si hay que reducir el movimiento (WCAG 2.3.3).
  Duration motion(Duration duration) => reduceMotion ? Duration.zero : duration;

  void showSnack(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Aviso tras borrar algo con «Deshacer». El cierre del aviso decide: con
  /// la acción se deshace ([onUndo]); por tiempo, al taparlo otro aviso o al
  /// descartarlo, se confirma ([onCommit]). Con lector de pantalla el aviso no
  /// se cierra solo, así que no hay prisa (WCAG 2.2.1).
  void showUndoSnack(
    String message, {
    required VoidCallback onUndo,
    required VoidCallback onCommit,
  }) {
    final messenger = ScaffoldMessenger.of(this)..hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: TokensDuration.undoWindow,
        action: SnackBarAction(
          label: localizations.commonUndo,
          onPressed: onUndo,
        ),
      ),
    );
    unawaited(
      controller.closed.then((reason) {
        if (reason != SnackBarClosedReason.action) onCommit();
      }),
    );
  }
}
