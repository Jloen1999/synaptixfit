import 'package:flutter/material.dart';

import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';

/// Explica, al empezar una sesión, que el cronómetro ya corre (ADR 0030).
/// Devuelve (empezar, no volver a explicarlo).
///
/// La casilla se lee de [ClockIntroSheet.hide] y no del resultado: cerrar la
/// hoja con «atrás» o deslizándola devuelve `null`, y antes eso olvidaba la
/// casilla (fallo 7: al pausar, salir y volver se explicaba otra vez).
Future<(bool, bool)> showClockIntroSheet(
  BuildContext context, {
  required int? minutes,
}) async {
  final hide = ValueNotifier(false);
  try {
    final start = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      isDismissible: false,
      builder: (_) => ClockIntroSheet(minutes: minutes, hide: hide),
    );
    return (start ?? true, hide.value);
  } finally {
    hide.dispose();
  }
}

/// Hoja con los tres puntos del cronómetro y la casilla «No volver a
/// explicarlo»; la abre [showClockIntroSheet].
class ClockIntroSheet extends StatefulWidget {
  const ClockIntroSheet({super.key, required this.minutes, required this.hide});

  final int? minutes;

  /// «No volver a explicarlo», al momento de marcarla.
  final ValueNotifier<bool> hide;

  @override
  State<ClockIntroSheet> createState() => _ClockIntroSheetState();
}

class _ClockIntroSheetState extends State<ClockIntroSheet> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    Widget point(int n, String text) => Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppStepBadge(number: n),
          const SizedBox(width: TokensSpacing.s),
          Expanded(child: Text(text)),
        ],
      ),
    );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          TokensSpacing.l,
          0,
          TokensSpacing.l,
          TokensSpacing.l,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.trainingClockIntroTitle,
                style: context.textStyles.titleLarge,
              ),
            ),
            if (widget.minutes case final m? when m > 0) ...[
              const SizedBox(height: TokensSpacing.s),
              Align(
                alignment: AlignmentDirectional.centerStart,
                // Neutra: es una estimación (el naranja es el tiempo real).
                child: AppPill(
                  label: l10n.trainingClockIntroEstimate(m),
                  icon: Icons.schedule_rounded,
                ),
              ),
            ],
            const SizedBox(height: TokensSpacing.m),
            point(1, l10n.trainingClockIntroPoint1),
            point(2, l10n.trainingClockIntroPoint2),
            point(3, l10n.trainingClockIntroPoint3),
            AppFocusOutline(
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: widget.hide.value,
                onChanged: (v) =>
                    setState(() => widget.hide.value = v ?? false),
                title: Text(l10n.trainingClockIntroHide),
              ),
            ),
            const SizedBox(height: TokensSpacing.s),
            AppPrimaryButton(
              label: l10n.trainingClockIntroStart,
              // El cronómetro ya corre: el botón confirma, no arranca nada.
              icon: Icons.check_rounded,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: TokensSpacing.xs),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.trainingClockIntroNotYet),
            ),
          ],
        ),
      ),
    );
  }
}
