import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/profile/catalog.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../catalog_picker/page/catalog_picker_sheet.dart';
import '../../widgets/profile_layout.dart';
import '../bloc/degrees_bloc.dart';

/// Carreras vinculadas (`/profile/degrees`).
class DegreesPage extends StatelessWidget {
  const DegreesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DegreesBloc>()..add(const DegreesEvent.started()),
      child: const _DegreesView(),
    );
  }
}

class _DegreesView extends StatelessWidget with ErrorsMessageMixin {
  const _DegreesView();

  Future<void> _link(BuildContext context) async {
    final bloc = context.read<DegreesBloc>();
    final degree = await showCatalogDegreePicker(context);
    if (degree != null) bloc.add(DegreesEvent.linkRequested(degree));
  }

  Future<void> _confirmUnlink(BuildContext context, UserDegree item) async {
    final l10n = context.localizations;
    final bloc = context.read<DegreesBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.profileDegreesUnlinkTitle),
        content: Text(l10n.profileDegreesUnlinkMessage(item.degree.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: dialogContext.colors.error,
              foregroundColor: dialogContext.colors.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.profileDegreesUnlinkAction),
          ),
        ],
      ),
    );
    if (ok ?? false) bloc.add(DegreesEvent.unlinkRequested(item.degree.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Scaffold(
      appBar: AppPageBar.reading(title: Text(l10n.profileDegreesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _link(context),
        icon: const Icon(AppIcons.add),
        label: Text(l10n.profileDegreesLinkAction),
      ),
      body: BlocConsumer<DegreesBloc, DegreesState>(
        listenWhen: (a, b) =>
            a.outcome != b.outcome || a.actionError != b.actionError,
        listener: (context, state) {
          if (state.actionError case final error?) {
            context.showSnack(errorMessage(context, error));
          } else if (state.outcome case final outcome?) {
            context.showSnack(
              outcome == DegreesOutcome.linked
                  ? l10n.profileDegreesLinked
                  : l10n.profileDegreesUnlinked,
            );
          }
        },
        builder: (context, state) {
          final bloc = context.read<DegreesBloc>();
          switch (state.status) {
            case DegreesStatus.loading:
              return const AppSkeletonGroup(
                child: ProfileScrollBody(
                  children: [
                    AppSkeleton(height: 72),
                    SizedBox(height: TokensSpacing.s),
                    AppSkeleton(height: 72),
                  ],
                ),
              );
            case DegreesStatus.failure:
              return AppErrorView(
                error: state.error!,
                onRetry: () => bloc.add(const DegreesEvent.started()),
              );
            case DegreesStatus.ready:
              if (state.degrees.isEmpty) {
                return AppEmptyState(
                  icon: Icons.workspace_premium_outlined,
                  title: l10n.profileDegreesEmptyTitle,
                  message: l10n.profileDegreesEmptyMessage,
                  action: AppPrimaryButton(
                    label: l10n.profileDegreesLinkAction,
                    icon: AppIcons.add,
                    onPressed: () => _link(context),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => bloc.add(const DegreesEvent.started()),
                child: ProfileScrollBody(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    if (state.busy) const LinearProgressIndicator(),
                    Text(
                      l10n.profileDegreesHint,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: TokensSpacing.m),
                    for (final item in state.degrees)
                      Padding(
                        padding: const EdgeInsets.only(bottom: TokensSpacing.s),
                        child: _DegreeCard(
                          item: item,
                          onUnlink: state.busy
                              ? null
                              : () => _confirmUnlink(context, item),
                        ),
                      ),
                    const SizedBox(height: TokensSpacing.xxl),
                  ],
                ),
              );
          }
        },
      ),
    );
  }
}

class _DegreeCard extends StatelessWidget {
  const _DegreeCard({required this.item, required this.onUnlink});

  final UserDegree item;
  final VoidCallback? onUnlink;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final degree = item.degree;
    final details = [
      ?degree.universityName,
      ?degree.centerName,
      if (degree.totalCredits != null)
        l10n.profileDegreeCredits(degree.totalCredits!),
    ].join(' · ');
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.school_rounded, color: context.palette.study),
          const SizedBox(width: TokensSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(degree.name, style: context.textStyles.titleSmall),
                if (details.isNotEmpty)
                  Text(
                    details,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                if (item.linkedAt != null)
                  Text(
                    l10n.profileDegreeLinkedAt(
                      DateFormat.yMMMd().format(item.linkedAt!),
                    ),
                    style: context.textStyles.labelSmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          // Con texto: el icono de «enlace roto» no se entiende solo.
          TextButton(
            onPressed: onUnlink,
            child: Text(l10n.profileDegreesUnlinkAction),
          ),
        ],
      ),
    );
  }
}
