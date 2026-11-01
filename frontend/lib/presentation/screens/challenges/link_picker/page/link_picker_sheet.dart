import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/challenges/challenge_references.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/challenge_labels.dart';
import '../bloc/link_picker_bloc.dart';

/// Hoja para vincular un reto o tarea a una entrega o examen que venza dentro
/// del periodo del reto ([from]-[to]).
Future<ChallengeLinkOption?> showLinkPickerSheet(
  BuildContext context, {
  String? subjectId,
  DateTime? from,
  DateTime? to,
}) {
  return showModalBottomSheet<ChallengeLinkOption>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => BlocProvider(
      create: (_) => getIt<LinkPickerBloc>()
        ..add(
          LinkPickerEvent.started(subjectId: subjectId, from: from, to: to),
        ),
      child: _LinkPickerView(subjectId: subjectId, from: from, to: to),
    ),
  );
}

/// Texto visible de una opción de vínculo.
String challengeLinkOptionLabel(BuildContext context, ChallengeLinkOption o) {
  final title = o.title.trim().isEmpty ? o.type.label(context) : o.title;
  return context.localizations.challengesFeedbackJoin(
    title,
    ChallengeFormats.dateTime(o.at),
  );
}

class _LinkPickerView extends StatelessWidget {
  const _LinkPickerView({this.subjectId, this.from, this.to});

  final String? subjectId;
  final DateTime? from;
  final DateTime? to;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocBuilder<LinkPickerBloc, LinkPickerState>(
      builder: (context, state) {
        Widget tile(ChallengeLinkOption o) => AppFocusOutline(
          child: ListTile(
            leading: Icon(o.type.icon, color: context.colors.tertiary),
            title: Text(
              o.title.trim().isEmpty ? o.type.label(context) : o.title,
            ),
            subtitle: Text(
              l10n.challengesFeedbackJoin(
                o.type.label(context),
                ChallengeFormats.dateTime(o.at),
              ),
            ),
            onTap: () => Navigator.pop(context, o),
          ),
        );
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(
              TokensSpacing.l,
              0,
              TokensSpacing.l,
              TokensSpacing.l,
            ),
            children: [
              Text(
                l10n.challengesLinkTitle,
                style: context.textStyles.titleLarge,
              ),
              const SizedBox(height: TokensSpacing.m),
              ...switch (state.status) {
                LinkPickerStatus.loading => const [
                  AppSkeletonGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppSkeleton(height: 56),
                        SizedBox(height: TokensSpacing.s),
                        AppSkeleton(height: 56),
                      ],
                    ),
                  ),
                ],
                LinkPickerStatus.failure => [
                  AppErrorView(
                    error: state.error!,
                    onRetry: () => context.read<LinkPickerBloc>().add(
                      LinkPickerEvent.started(
                        subjectId: subjectId,
                        from: from,
                        to: to,
                      ),
                    ),
                  ),
                ],
                LinkPickerStatus.ready when state.options.isEmpty => [
                  AppEmptyState(
                    icon: Icons.event_busy_outlined,
                    title: l10n.challengesLinkEmpty,
                    message: l10n.challengesLinkEmptyPeriod,
                  ),
                ],
                LinkPickerStatus.ready => [
                  AppSectionHeader(title: l10n.challengesLinkDeadlines),
                  ...state.options.map(tile),
                ],
              },
            ],
          ),
        );
      },
    );
  }
}
