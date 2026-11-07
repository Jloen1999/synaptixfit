import 'package:flutter/material.dart';

import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';

/// Ayuda breve: algunos móviles cortan el GPS con la pantalla apagada para
/// ahorrar batería. Tres pasos sencillos y qué notarás si pasa.
Future<void> showRunBatterySheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) {
        final l10n = sheet.localizations;
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.runBatteryTitle,
                    style: sheet.textStyles.titleLarge,
                  ),
                ),
                const SizedBox(height: TokensSpacing.s),
                Text(l10n.runBatteryIntro),
                const SizedBox(height: TokensSpacing.m),
                point(1, l10n.runBatteryStep1),
                point(2, l10n.runBatteryStep2),
                point(3, l10n.runBatteryStep3),
                const SizedBox(height: TokensSpacing.s),
                AppPrimaryButton(
                  label: l10n.runBatteryOk,
                  icon: Icons.check_rounded,
                  onPressed: () => Navigator.of(sheet).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
