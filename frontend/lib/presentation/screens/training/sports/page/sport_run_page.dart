import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../domain/models/training/run.dart';
import '../../../../../domain/models/training/sport_activity.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../run_home/page/create_run_workout_sheet.dart';
import '../../training_routes.dart';
import '../../widgets/run_labels.dart';
import '../../widgets/sport_labels.dart';
import '../../widgets/training_section_bar.dart';

/// «Correr, andar o bici» (`/training/sports/run`, ADR 0068): se elige cuál
/// de los tres y se empieza a grabar con el GPS (única acción principal,
/// abajo fija), se apunta una ya hecha o se crea un entreno guiado. Sin GPS
/// ([gps] falso: web o escritorio) la acción principal es apuntarla a mano.
/// [templates] son las plantillas de entreno guiado que ya tiene «Deportes»;
/// abierta en frío no llegan y se crea desde cero.
class SportRunPage extends StatefulWidget {
  const SportRunPage({
    super.key,
    this.gps = true,
    this.templates = const [],
  });

  final bool gps;
  final List<RunWorkout> templates;

  @override
  State<SportRunPage> createState() => _SportRunPageState();
}

class _SportRunPageState extends State<SportRunPage> {
  static const _sports = [Sport.run, Sport.walk, Sport.bike];

  Sport _sport = Sport.run;

  String get _back => TrainingPaths.section(TrainingSection.run);

  void _record() => context.push(TrainingPaths.recordRun(kind: _sport.kind));

  /// Al guardarla se vuelve a «Deportes», donde queda en «Últimas actividades».
  Future<void> _log() async {
    final saved = await context.push<Object?>(
      TrainingPaths.logActivity(from: TrainingSection.run, sport: _sport),
    );
    if (saved == true && mounted) context.popOrGo(_back, true);
  }

  Future<void> _createWorkout() async {
    final code = await showCreateRunWorkoutSheet(context, widget.templates);
    if (code == null || !mounted) return;
    await context.push<Object?>(
      TrainingPaths.newRunWorkout(template: code.isEmpty ? null : code),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final muted = context.textStyles.bodyMedium?.copyWith(
      color: context.colors.onSurfaceVariant,
    );
    return Scaffold(
      appBar: AppPageBar.reading(
        leading: AppBackButton(fallback: _back),
        title: Text(l10n.sportEnduranceTitle),
      ),
      body: AppContentWidth.reading(
        child: ListView(
          padding: const EdgeInsets.all(TokensSpacing.m),
          children: [
            const SportPhotoHeader(sport: Sport.run),
            const SizedBox(height: TokensSpacing.m),
            AppAdaptiveChoice<Sport>(
              label: l10n.runKindQuestion,
              values: _sports,
              selected: _sport,
              labelOf: (s) => SportLabels.name(l10n, s),
              iconOf: (s) => RunLabels.kindIcon(s.kind),
              onChanged: (s) => setState(() => _sport = s),
            ),
            const SizedBox(height: TokensSpacing.s),
            if (widget.gps) ...[
              Text(l10n.sportRunStartHint, style: muted),
              const SizedBox(height: TokensSpacing.m),
              OutlinedButton.icon(
                onPressed: _log,
                icon: const Icon(Icons.edit_note_rounded),
                label: Text(l10n.sportLogDone),
              ),
            ] else
              AppInlineMessage(
                message: l10n.runDesktopExplain,
                tone: AppMessageTone.info,
              ),
            const SizedBox(height: TokensSpacing.l),
            AppSectionHeader(title: l10n.runWorkoutsTitle),
            Text(l10n.sportGuidedHint, style: muted),
            const SizedBox(height: TokensSpacing.s),
            FilledButton.tonalIcon(
              onPressed: _createWorkout,
              icon: const Icon(AppIcons.add),
              label: Text(l10n.runCreateWorkout),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: AppContentWidth.reading(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              TokensSpacing.m,
              TokensSpacing.s,
              TokensSpacing.m,
              TokensSpacing.m,
            ),
            child: widget.gps
                ? AppPrimaryButton(
                    label: l10n.sportRunStart,
                    icon: AppIcons.start,
                    onPressed: _record,
                  )
                : AppPrimaryButton(
                    label: l10n.sportLogDone,
                    icon: Icons.edit_note_rounded,
                    onPressed: _log,
                  ),
          ),
        ),
      ),
    );
  }
}
