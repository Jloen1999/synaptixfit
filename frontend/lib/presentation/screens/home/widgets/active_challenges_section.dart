import 'package:flutter/material.dart';

import '../../../../domain/models/home/home_dashboard.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Retos activos (máximo 3) con su progreso.
class ActiveChallengesSection extends StatelessWidget {
  const ActiveChallengesSection({
    super.key,
    required this.challenges,
    required this.onOpen,
    required this.onSeeAll,
    required this.onCreate,
    this.now,
  });

  static const maxVisible = 3;

  final List<HomeChallenge> challenges;
  final ValueChanged<HomeChallenge> onOpen;
  final VoidCallback onSeeAll;
  final VoidCallback onCreate;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final visible = challenges.take(maxVisible).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionHeader(
          title: l10n.homeChallengesTitle,
          actionLabel: challenges.isEmpty ? null : l10n.commonSeeAll,
          onAction: onSeeAll,
        ),
        if (visible.isEmpty)
          AppCard(
            child: AppEmptyState.compact(
              icon: Icons.flag_outlined,
              title: l10n.homeChallengesEmptyTitle,
              message: l10n.homeChallengesEmptyMessage,
              action: AppSecondaryButton(
                label: l10n.homeChallengesCreate,
                icon: const Icon(AppIcons.add),
                onPressed: onCreate,
              ),
            ),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: TokensSpacing.xs),
            child: Column(
              children: [
                for (final challenge in visible)
                  _ChallengeTile(
                    challenge: challenge,
                    now: now ?? DateTime.now(),
                    onTap: () => onOpen(challenge),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Fila de un reto activo, como la tarjeta de Retos en pequeño: cuándo
/// (bloque de fecha y «Termina mañana», en aviso si es hoy o mañana), qué
/// (título) y cuánto (barra en el acento del tipo con el %). Sin fecha de fin,
/// el bloque muestra el icono del tipo.
class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({
    required this.challenge,
    required this.now,
    required this.onTap,
  });

  final HomeChallenge challenge;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final typeColor = challenge.academic
        ? context.palette.study
        : context.colors.secondary;
    final endsAt = challenge.endsAt;
    final daysLeft = endsAt == null ? null : AppDueDates.daysUntil(endsAt, now);
    final soon = endsAt != null && AppDueDates.isSoon(endsAt, now);
    final blockColor = soon ? context.palette.warning : typeColor;
    final progress = challenge.progress.round();
    final typeLabel = challenge.academic
        ? l10n.homeChallengeAcademic
        : l10n.homeChallengeFitness;

    return AppCardTapArea(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: TokensSpacing.m,
        vertical: TokensSpacing.s,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = AppDateBlock.sideBySide(context, constraints.maxWidth);
          final block = endsAt == null
              ? AppDateBlock(
                  caption: typeLabel,
                  icon: challenge.academic
                      ? Icons.school_outlined
                      : Icons.fitness_center_rounded,
                  color: typeColor,
                  compact: !side,
                )
              : AppDateBlock.due(
                  context,
                  due: endsAt,
                  now: now,
                  color: blockColor,
                  compact: !side,
                );
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sin fecha de fin, el tipo ya lo dice el bloque: no se repite.
              if (daysLeft != null) ...[
                Text(
                  // Si ya pasó (p. ej. por la zona horaria), lo mismo que
                  // dice el bloque de al lado: «Venció el 2 nov».
                  daysLeft < 0
                      ? AppDueDates.text(context, endsAt!, now)
                      : l10n.homeChallengeEndsIn(daysLeft),
                  style: context.textStyles.labelLarge?.copyWith(
                    color: soon
                        ? context.palette.warning
                        : context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: TokensSpacing.xxs),
              ],
              Text(
                challenge.title,
                style: context.textStyles.titleSmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: TokensSpacing.s),
              AppCycleProgress(
                progress: challenge.progress / 100,
                label: l10n.homeChallengeProgress(progress),
                color: typeColor,
              ),
            ],
          );
          final chevron = Icon(
            AppIcons.next,
            color: context.colors.onSurfaceVariant,
          );
          if (!side) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: block),
                    const Spacer(),
                    chevron,
                  ],
                ),
                const SizedBox(height: TokensSpacing.s),
                content,
              ],
            );
          }
          return Row(
            children: [
              block,
              const SizedBox(width: TokensSpacing.m),
              Expanded(child: content),
              const SizedBox(width: TokensSpacing.s),
              chevron,
            ],
          );
        },
      ),
    );
  }
}
