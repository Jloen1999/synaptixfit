import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/models/planner/calendar_feed.dart';
import '../../../../../domain/models/planner/planner_ai.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../planner_routes.dart';
import '../bloc/calendar_sync_bloc.dart';

/// Sincronizar calendarios (`/planner/calendar-sync`): ver el planificador en
/// Google, Apple u Outlook con un enlace secreto e importar exámenes y
/// entregas del calendario del Campus Virtual.
class CalendarSyncPage extends StatelessWidget {
  const CalendarSyncPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<CalendarSyncBloc>()..add(const CalendarSyncEvent.started()),
    child: const _CalendarSyncView(),
  );
}

class _CalendarSyncView extends StatelessWidget with ErrorsMessageMixin {
  const _CalendarSyncView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<CalendarSyncBloc, CalendarSyncState>(
      listenWhen: (a, b) =>
          a.actionErrorId != b.actionErrorId && b.actionError != null,
      listener: (context, state) =>
          context.showSnack(errorMessage(context, state.actionError!)),
      builder: (context, state) => Scaffold(
        appBar: AppPageBar.reading(title: Text(l10n.plannerSyncTitle)),
        body: AppContentWidth.reading(
          child: switch (state.status) {
            CalendarSyncStatus.loading => const AppSkeletonList(
              count: 2,
              height: 160,
            ),
            CalendarSyncStatus.failure => AppErrorView(
              error: state.error!,
              onRetry: () => context.read<CalendarSyncBloc>().add(
                const CalendarSyncEvent.started(),
              ),
            ),
            CalendarSyncStatus.ready => ListView(
              padding: const EdgeInsets.all(TokensSpacing.m),
              children: [
                _FeedSection(state: state),
                const SizedBox(height: TokensSpacing.m),
                _CampusSection(state: state),
              ],
            ),
          },
        ),
      ),
    );
  }
}

/// Tarjeta de la pantalla: icono con el color de su área, título e intro.
class _SyncSection extends StatelessWidget {
  const _SyncSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.intro,
    required this.children,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String intro;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            ExcludeSemantics(child: Icon(icon, color: color)),
            const SizedBox(width: TokensSpacing.s),
            Expanded(child: AppSectionHeader(title: title)),
          ],
        ),
        Text(intro, style: context.textStyles.bodyMedium),
        const SizedBox(height: TokensSpacing.m),
        ...children,
      ],
    ),
  );
}

/// Ver el planificador en otro calendario con el enlace secreto.
class _FeedSection extends StatefulWidget {
  const _FeedSection({required this.state});

  final CalendarSyncState state;

  @override
  State<_FeedSection> createState() => _FeedSectionState();
}

class _FeedSectionState extends State<_FeedSection> {
  /// El botón que tenía el foco desaparece al crear o desactivar el enlace:
  /// el foco pasa a «Copiar enlace» o vuelve a «Crear enlace» (WCAG 2.4.3).
  final _copyFocus = FocusNode();
  final _createFocus = FocusNode();

  @override
  void dispose() {
    _copyFocus.dispose();
    _createFocus.dispose();
    super.dispose();
  }

  Future<void> _create({required bool replace}) async {
    final bloc = context.read<CalendarSyncBloc>();
    if (replace) {
      final l10n = context.localizations;
      final ok = await showConfirmDialog(
        context,
        title: l10n.plannerSyncNewLinkTitle,
        message: l10n.plannerSyncNewLinkMessage,
        confirmLabel: l10n.plannerSyncNewLink,
      );
      if (!ok) return;
    }
    bloc.add(const CalendarSyncEvent.feedCreated());
  }

  Future<void> _revoke() async {
    final l10n = context.localizations;
    final bloc = context.read<CalendarSyncBloc>();
    final ok = await showConfirmDialog(
      context,
      title: l10n.plannerSyncRevokeTitle,
      message: l10n.plannerSyncRevokeMessage,
      confirmLabel: l10n.plannerSyncRevoke,
    );
    if (ok) bloc.add(const CalendarSyncEvent.feedRevoked());
  }

  void _onChanged(BuildContext context, CalendarSyncState state) {
    final l10n = context.localizations;
    if (state.link != null) {
      _copyFocus.requestFocus();
      unawaited(
        SemanticsService.sendAnnouncement(
          View.of(context),
          l10n.plannerSyncLinkReady,
          Directionality.of(context),
        ),
      );
    } else {
      _createFocus.requestFocus();
      context.showSnack(l10n.plannerSyncRevoked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final state = widget.state;
    final link = state.link;
    final since = state.feed.activeSince;
    return BlocListener<CalendarSyncBloc, CalendarSyncState>(
      listenWhen: (a, b) =>
          (a.link == null && b.link != null) ||
          a.revokedCount != b.revokedCount,
      // Tras reconstruir, para que exista el botón que recibe el foco.
      listener: (context, s) => WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.mounted ? _onChanged(context, s) : null,
      ),
      child: _SyncSection(
        icon: Icons.event_repeat_rounded,
        color: context.colors.primary,
        title: l10n.plannerSyncFeedTitle,
        intro: l10n.plannerSyncFeedIntro,
        children: [
          if (link != null)
            _LinkCard(link: link, copyFocus: _copyFocus)
          else if (state.feed.active && since != null) ...[
            Text(
              l10n.plannerSyncActiveSince(
                DateFormat.yMMMd(l10n.localeName).format(since),
              ),
              style: context.textStyles.titleSmall,
            ),
            const SizedBox(height: TokensSpacing.xs),
            Text(
              l10n.plannerSyncHiddenLink,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: TokensSpacing.m),
          Wrap(
            spacing: TokensSpacing.s,
            runSpacing: TokensSpacing.s,
            children: [
              if (!state.feed.active)
                AppPrimaryButton(
                  label: l10n.plannerSyncCreateLink,
                  focusNode: _createFocus,
                  loading: state.feedAction == CalendarFeedAction.creating,
                  onPressed: () => _create(replace: false),
                )
              else ...[
                AppSecondaryButton(
                  label: l10n.plannerSyncNewLink,
                  icon: const Icon(Icons.autorenew_rounded),
                  loading: state.feedAction == CalendarFeedAction.creating,
                  onPressed: state.feedBusy
                      ? null
                      : () => _create(replace: true),
                ),
                AppSecondaryButton(
                  label: l10n.plannerSyncRevoke,
                  icon: const Icon(Icons.link_off_rounded),
                  loading: state.feedAction == CalendarFeedAction.revoking,
                  onPressed: state.feedBusy ? null : _revoke,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// El enlace recién creado: el aviso de privacidad primero, el enlace,
/// copiarlo, abrirlo en la app de calendario y cómo añadirlo en Google.
class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.link, required this.copyFocus});

  final CalendarFeedLink link;
  final FocusNode copyFocus;

  Future<void> _open(BuildContext context) async {
    final opened = await launchUrl(Uri.parse(link.webcalUrl));
    if (!opened && context.mounted) {
      context.showSnack(context.localizations.plannerSyncOpenFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.warning_amber_rounded,
                color: context.palette.warning,
              ),
            ),
            const SizedBox(width: TokensSpacing.s),
            Expanded(
              child: Text(
                l10n.plannerSyncSaveLinkWarning,
                style: context.textStyles.bodyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: TokensSpacing.s),
        Container(
          padding: const EdgeInsets.all(TokensSpacing.s),
          decoration: BoxDecoration(
            color: context.colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(TokensRadius.m),
          ),
          child: Semantics(
            label: l10n.plannerSyncLinkLabel,
            child: SelectableText(
              link.url,
              style: context.textStyles.bodySmall,
            ),
          ),
        ),
        const SizedBox(height: TokensSpacing.s),
        Wrap(
          spacing: TokensSpacing.s,
          runSpacing: TokensSpacing.s,
          children: [
            AppSecondaryButton(
              label: l10n.plannerSyncCopy,
              icon: const Icon(Icons.copy_rounded),
              focusNode: copyFocus,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: link.url));
                if (context.mounted) context.showSnack(l10n.plannerSyncCopied);
              },
            ),
            AppSecondaryButton(
              label: l10n.plannerSyncOpen,
              icon: const Icon(Icons.event_available_rounded),
              onPressed: () => _open(context),
            ),
          ],
        ),
        const SizedBox(height: TokensSpacing.m),
        Text(l10n.plannerSyncGoogleSteps, style: context.textStyles.bodyMedium),
      ],
    );
  }
}

/// Importar exámenes y entregas del calendario del Campus Virtual (Moodle).
class _CampusSection extends StatefulWidget {
  const _CampusSection({required this.state});

  final CalendarSyncState state;

  @override
  State<_CampusSection> createState() => _CampusSectionState();
}

class _CampusSectionState extends State<_CampusSection>
    with ErrorsMessageMixin {
  final _url = TextEditingController();

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  void _import() => context.read<CalendarSyncBloc>().add(
    CalendarSyncEvent.importRequested(_url.text),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final state = widget.state;
    final result = state.importResult;
    final importError = state.importError;
    return _SyncSection(
      icon: Icons.school_rounded,
      color: context.colors.tertiary,
      title: l10n.plannerSyncCampusTitle,
      intro: l10n.plannerSyncCampusSteps,
      children: [
        AppTextField(
          controller: _url,
          label: l10n.plannerSyncCampusUrlLabel,
          helper: l10n.plannerSyncCampusUrlHelper,
          icon: Icons.link_rounded,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          autocorrect: false,
          errorText: state.urlMissing
              ? l10n.plannerSyncCampusUrlRequired
              : null,
          onSubmitted: (_) => _import(),
        ),
        const SizedBox(height: TokensSpacing.m),
        if (importError != null) ...[
          AppInlineMessage(message: errorMessage(context, importError)),
          const SizedBox(height: TokensSpacing.m),
        ],
        AppPrimaryButton(
          label: l10n.plannerSyncCampusImport,
          loading: state.importing,
          onPressed: _import,
        ),
        // Región viva montada siempre: en web, una que aparece ya con texto
        // a menudo no se lee.
        Semantics(
          liveRegion: true,
          child: result == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: TokensSpacing.m),
                  child: _ImportSummary(result: result),
                ),
        ),
      ],
    );
  }
}

class _ImportSummary extends StatelessWidget {
  const _ImportSummary({required this.result});

  final IcsImportResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final none = result.exams + result.deliveries == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                none ? Icons.info_outline_rounded : Icons.check_circle_rounded,
                color: none
                    ? context.colors.onSurfaceVariant
                    : context.palette.success,
              ),
            ),
            const SizedBox(width: TokensSpacing.s),
            Expanded(
              child: Text(
                none
                    ? l10n.plannerSyncCampusNothing
                    : l10n.plannerSyncCampusResult(
                        result.exams,
                        result.deliveries,
                        result.matchingEvents,
                      ),
              ),
            ),
          ],
        ),
        if (!none)
          TextButton.icon(
            onPressed: () => context.push(PlannerPaths.deadlines),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(l10n.plannerSyncSeeDeadlines),
          ),
      ],
    );
  }
}
