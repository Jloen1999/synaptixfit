import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/planner_enums.dart';
import '../../../../../domain/models/planner/planner_ai.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../widgets/planner_form_fields.dart';
import '../../widgets/semester_dates_sheet.dart';
import '../bloc/schedule_scan_bloc.dart';

/// Importar y exportar el horario (`/planner/schedule-scan`): escaneo con IA,
/// calendario ICS de una asignatura y exportación `.ics`.
class ScheduleScanPage extends StatelessWidget {
  const ScheduleScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ScheduleScanBloc>()..add(const ScheduleScanEvent.started()),
      child: const _ScheduleScanView(),
    );
  }
}

class _ScheduleScanView extends StatefulWidget {
  const _ScheduleScanView();

  @override
  State<_ScheduleScanView> createState() => _ScheduleScanViewState();
}

class _ScheduleScanViewState extends State<_ScheduleScanView>
    with ErrorsMessageMixin {
  static const _extensions = ['pdf', 'png', 'jpg', 'jpeg', 'webp', 'heic'];

  String? _icsSubjectId;
  final _icsUrl = TextEditingController();

  ScheduleScanBloc get _bloc => context.read<ScheduleScanBloc>();

  @override
  void dispose() {
    _icsUrl.dispose();
    super.dispose();
  }

  static String _mimeOf(String? extension) =>
      switch (extension?.toLowerCase()) {
        'pdf' => 'application/pdf',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'heic' => 'image/heic',
        _ => 'image/jpeg',
      };

  Future<void> _pickFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: _extensions,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    _bloc.add(
      ScheduleScanEvent.fileSelected(
        ScheduleFile(
          name: file.name,
          bytes: bytes,
          mimeType: _mimeOf(file.extension),
        ),
      ),
    );
  }

  Future<void> _askDates() async {
    final dates = await SemesterDatesSheet.show(context);
    if (!mounted) return;
    _bloc.add(
      dates == null
          ? const ScheduleScanEvent.semesterDatesDismissed()
          : ScheduleScanEvent.semesterDatesSubmitted(
              start: dates.start,
              end: dates.end,
            ),
    );
  }

  Future<void> _saveIcs(String content) async {
    final uri = await FilePicker.saveFile(
      fileName: 'synaptixfit.ics',
      bytes: Uint8List.fromList(utf8.encode(content)),
      mimeType: 'text/calendar',
    );
    if (uri != null && mounted) {
      context.showSnack(context.localizations.plannerExported);
    }
  }

  void _onNotice(BuildContext context, ScheduleScanNotice notice) {
    final l10n = context.localizations;
    switch (notice) {
      case ScheduleScanNoticeAskDates():
        unawaited(_askDates());
      case ScheduleScanNoticeScanned():
        context.showSnack(l10n.plannerScanResultTitle);
      case ScheduleScanNoticeIcsImported(:final result):
        if (result.imported) {
          context.showSnack(
            l10n.plannerIcsResult(
              result.created,
              result.updated,
              result.totalEvents,
            ),
          );
        }
      case ScheduleScanNoticeExportReady(:final content):
        unawaited(_saveIcs(content));
      case ScheduleScanNoticeFailure(:final error):
        context.showSnack(errorMessage(context, error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<ScheduleScanBloc, ScheduleScanState>(
      listenWhen: (a, b) => a.noticeId != b.noticeId && b.notice != null,
      listener: (context, state) => _onNotice(context, state.notice!),
      builder: (context, state) {
        return Scaffold(
          appBar: AppPageBar.reading(title: Text(l10n.plannerScheduleTitle)),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: TokensLayout.readingMaxWidth,
              ),
              child: ListView(
                padding: const EdgeInsets.all(TokensSpacing.m),
                children: [
                  _scanCard(context, state),
                  const SizedBox(height: TokensSpacing.m),
                  _icsCard(context, state),
                  const SizedBox(height: TokensSpacing.m),
                  _exportCard(context, state),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _section(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String intro,
    required List<Widget> children,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: TokensSpacing.s),
              Expanded(
                child: Text(title, style: context.textStyles.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.xs),
          Text(
            intro,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: TokensSpacing.m),
          ...children,
        ],
      ),
    );
  }

  Widget _scanCard(BuildContext context, ScheduleScanState state) {
    final l10n = context.localizations;
    final busy =
        state.scanStatus == ScanStatus.uploading ||
        state.scanStatus == ScanStatus.savingDates;
    final uploaded = state.progress >= 1;
    final result = state.scanResult;
    return _section(
      context,
      icon: Icons.document_scanner_rounded,
      color: context.colors.tertiary,
      title: l10n.plannerScanSection,
      intro: l10n.plannerScanIntro,
      children: [
        if (busy) ...[
          LinearProgressIndicator(
            value: state.scanStatus == ScanStatus.uploading && !uploaded
                ? state.progress
                : null,
          ),
          const SizedBox(height: TokensSpacing.s),
          Text(
            state.scanStatus == ScanStatus.uploading && !uploaded
                ? l10n.plannerUploading((state.progress * 100).round())
                : l10n.plannerAnalyzing,
            style: context.textStyles.bodySmall,
          ),
          const SizedBox(height: TokensSpacing.m),
        ],
        if (state.scanError != null) ...[
          InlineMessage(message: errorMessage(context, state.scanError!)),
          const SizedBox(height: TokensSpacing.m),
        ],
        if (result != null) ...[
          _ScanResultView(result: result),
          const SizedBox(height: TokensSpacing.m),
        ],
        AppPrimaryButton(
          label: l10n.plannerPickFile,
          icon: Icons.upload_file_rounded,
          loading: busy,
          onPressed: busy ? null : _pickFile,
        ),
      ],
    );
  }

  Widget _icsCard(BuildContext context, ScheduleScanState state) {
    final l10n = context.localizations;
    final result = state.icsResult;
    final subjectId = _icsSubjectId;
    return _section(
      context,
      icon: Icons.event_repeat_rounded,
      color: context.colors.primary,
      title: l10n.plannerIcsSection,
      intro: l10n.plannerIcsIntro,
      children: [
        if (!state.subjectsLoaded)
          const AppSkeletonGroup(child: AppSkeleton(height: 56))
        else if (state.subjects.isEmpty)
          InlineMessage(message: l10n.plannerIcsNoSubjects, isError: false)
        else ...[
          DropdownButtonFormField<String>(
            initialValue: subjectId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.plannerFieldSubject,
              prefixIcon: const Icon(Icons.class_rounded),
            ),
            items: [
              for (final s in state.subjects)
                DropdownMenuItem(value: s.id, child: Text(s.name)),
            ],
            onChanged: (v) => setState(() {
              _icsSubjectId = v;
              final subject = state.subjects
                  .where((s) => s.id == v)
                  .firstOrNull;
              _icsUrl.text = subject?.icsUrl ?? '';
            }),
          ),
          const SizedBox(height: TokensSpacing.s),
          AppTextField(
            label: l10n.plannerIcsUrl,
            hint: l10n.plannerIcsUrlHint,
            controller: _icsUrl,
            icon: Icons.link_rounded,
            keyboardType: TextInputType.url,
          ),
          if (result != null) ...[
            const SizedBox(height: TokensSpacing.s),
            if (result.imported)
              InlineMessage(
                isError: false,
                message: l10n.plannerIcsResult(
                  result.created,
                  result.updated,
                  result.totalEvents,
                ),
              )
            else ...[
              InlineMessage(
                isError: false,
                message: l10n.plannerIcsNotImported(
                  result.matchingEvents,
                  result.totalEvents,
                ),
              ),
              if (result.match != IcsMatch.full && state.icsSubjectId != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: state.importingIcs
                        ? null
                        : () => _bloc.add(
                            ScheduleScanEvent.icsImportRequested(
                              subjectId: state.icsSubjectId!,
                              url: state.icsUrl,
                              force: true,
                            ),
                          ),
                    child: Text(l10n.plannerIcsForce),
                  ),
                ),
            ],
          ],
          const SizedBox(height: TokensSpacing.m),
          AppSecondaryButton(
            label: l10n.plannerIcsImport,
            icon: state.importingIcs
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            onPressed: subjectId == null || state.importingIcs
                ? null
                : () => _bloc.add(
                    ScheduleScanEvent.icsImportRequested(
                      subjectId: subjectId,
                      url: _icsUrl.text.trim(),
                    ),
                  ),
          ),
        ],
      ],
    );
  }

  Widget _exportCard(BuildContext context, ScheduleScanState state) {
    final l10n = context.localizations;
    return _section(
      context,
      icon: Icons.ios_share_rounded,
      color: context.colors.secondary,
      title: l10n.plannerExportSection,
      intro: l10n.plannerExportIntro,
      children: [
        AppSecondaryButton(
          label: l10n.plannerExportAction,
          icon: state.exporting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.file_download_outlined),
          onPressed: state.exporting
              ? null
              : () => _bloc.add(const ScheduleScanEvent.exportRequested()),
        ),
      ],
    );
  }
}

class _ScanResultView extends StatelessWidget {
  const _ScanResultView({required this.result});

  final ScheduleScanResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return Container(
      padding: const EdgeInsets.all(TokensSpacing.m),
      decoration: BoxDecoration(
        color: context.palette.success.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(TokensRadius.m),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: context.palette.success),
              const SizedBox(width: TokensSpacing.s),
              Expanded(
                child: Text(
                  l10n.plannerScanResultTitle,
                  style: context.textStyles.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: TokensSpacing.xs),
          Text(
            l10n.plannerScanResultSummary(
              result.classesFound,
              result.blocksCreated,
              result.blocksUpdated,
            ),
          ),
          if (result.unmatchedSubjects.isNotEmpty) ...[
            const SizedBox(height: TokensSpacing.s),
            Text(
              l10n.plannerUnmatchedSubjects,
              style: context.textStyles.labelLarge,
            ),
            for (final s in result.unmatchedSubjects)
              Padding(
                padding: const EdgeInsets.only(top: TokensSpacing.xxs),
                child: Row(
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      size: 16,
                      color: context.palette.warning,
                    ),
                    const SizedBox(width: TokensSpacing.xs),
                    Expanded(child: Text(s)),
                  ],
                ),
              ),
            const SizedBox(height: TokensSpacing.xs),
            Text(
              l10n.plannerUnmatchedHint,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
