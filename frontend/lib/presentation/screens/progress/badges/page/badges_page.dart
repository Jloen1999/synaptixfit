import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/badge_category.dart';
import '../../../../../domain/errors/app_error.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../progress_routes.dart';
import '../../widgets/badge_detail_sheet.dart';
import '../../widgets/badge_tile.dart';
import '../../widgets/progress_labels.dart';
import '../bloc/badges_bloc.dart';

/// Progreso › Insignias: cuántas llevas y el catálogo con filtro por
/// categoría. Es un apartado de la pestaña, sin barra propia.
class BadgesPage extends StatelessWidget {
  const BadgesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BadgesBloc>()..add(const BadgesEvent.started()),
      child: const _BadgesView(),
    );
  }
}

class _BadgesView extends StatelessWidget with ErrorsMessageMixin {
  const _BadgesView();

  Future<void> _refresh(BuildContext context) {
    final bloc = context.read<BadgesBloc>()..add(const BadgesEvent.started());
    return bloc.stream.firstWhere((s) => s.status != BadgesStatus.loading);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<BadgesBloc, BadgesState>(
      listenWhen: (_, current) => current.feedback != null,
      listener: (context, state) {
        // Compartir dice dónde queda la publicación y lleva allí.
        if (state.feedback is BadgesShared) {
          context.showActionSnack(
            l10n.progressBadgeShared,
            actionLabel: l10n.commonView,
            onAction: () => context.push(ProgressExternalPaths.socialWall),
          );
          return;
        }
        final message = switch (state.feedback) {
          BadgesVisibilityChanged(:final visible) =>
            visible
                ? l10n.progressBadgeShownDone
                : l10n.progressBadgeHiddenDone,
          BadgesShared() => null,
          BadgesActionFailed(:final error) => errorMessage(context, error),
          null => null,
        };
        if (message != null) context.showSnack(message);
      },
      builder: (context, state) {
        return switch (state.status) {
          BadgesStatus.loading => const _GridSkeleton(),
          BadgesStatus.failure => AppErrorView(
            error: state.error ?? const AppError.unknown(),
            onRetry: () =>
                context.read<BadgesBloc>().add(const BadgesEvent.started()),
          ),
          BadgesStatus.loaded =>
            state.badges.isEmpty
                ? AppEmptyState(
                    icon: Icons.military_tech_outlined,
                    title: l10n.progressBadgeCatalogEmpty,
                    action: AppSecondaryButton(
                      label: l10n.commonRetry,
                      onPressed: () => context.read<BadgesBloc>().add(
                        const BadgesEvent.started(),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _refresh(context),
                    child: _BadgesContent(state: state),
                  ),
        };
      },
    );
  }
}

class _BadgesContent extends StatelessWidget {
  const _BadgesContent({required this.state});

  final BadgesState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final badges = state.filtered;
    // El servidor solo envía las insignias de los ámbitos que la persona usa:
    // los filtros muestran las categorías que han llegado.
    final categories = [
      for (final c in BadgeCategory.values)
        if (state.badges.any((b) => b.category == c)) c,
    ];
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: TokensLayout.contentMaxWidth,
        ),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  TokensSpacing.m,
                  TokensSpacing.m,
                  TokensSpacing.m,
                  0,
                ),
                child: Text(
                  l10n.progressBadgeSummary(
                    state.earnedCount,
                    state.badges.length,
                  ),
                  style: context.textStyles.labelLarge?.copyWith(
                    color: context.palette.accent,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: context.scaled(64),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: TokensSpacing.m,
                    vertical: TokensSpacing.s,
                  ),
                  children: [
                    for (final category in <BadgeCategory?>[
                      null,
                      ...categories,
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: TokensSpacing.s),
                        child: ChoiceChip(
                          avatar: Icon(badgeCategoryIcon(category), size: 18),
                          label: Text(l10n.badgeCategory(category)),
                          selected: state.category == category,
                          showCheckmark: false,
                          onSelected: (_) => context.read<BadgesBloc>().add(
                            BadgesEvent.categorySelected(category),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (badges.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AppEmptyState(
                  icon: badgeCategoryIcon(state.category),
                  title: l10n.progressBadgeCategoryEmpty,
                  action: AppSecondaryButton(
                    label: l10n.progressBadgeCategoryAll,
                    onPressed: () => context.read<BadgesBloc>().add(
                      const BadgesEvent.categorySelected(null),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  TokensSpacing.m,
                  0,
                  TokensSpacing.m,
                  TokensSpacing.l,
                ),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.crossAxisExtent;
                    final columns = width >= 720
                        ? 4
                        : width >= 520
                        ? 3
                        : 2;
                    return SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: TokensSpacing.s,
                        crossAxisSpacing: TokensSpacing.s,
                        mainAxisExtent: 224,
                      ),
                      itemCount: badges.length,
                      itemBuilder: (context, index) => BadgeTile(
                        badge: badges[index],
                        onTap: () =>
                            showBadgeDetailSheet(context, badges[index]),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppSkeletonGroup(
      child: GridView.builder(
        padding: const EdgeInsets.all(TokensSpacing.m),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: TokensSpacing.s,
          crossAxisSpacing: TokensSpacing.s,
          mainAxisExtent: 224,
        ),
        itemCount: 6,
        itemBuilder: (_, _) => const AppSkeleton(height: 224),
      ),
    );
  }
}
