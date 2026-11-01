import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pdfx/pdfx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../../domain/enums/study_source_type.dart';
import '../../../../../domain/models/academic/subject_file.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_visuals.dart';
import '../../widgets/academic_widgets.dart';
import '../../widgets/ai_assistant_sheet.dart';
import '../bloc/file_viewer_bloc.dart';

/// Visor de archivos: PDF dentro de la app (móvil/escritorio), imágenes con
/// zoom y el resto se abre fuera con la URL firmada.
class FileViewerPage extends StatelessWidget {
  const FileViewerPage({super.key, required this.fileId});

  final String fileId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    // En web pdfx necesita pdf.js en index.html: el PDF se abre en otra pestaña.
    create: (_) =>
        getIt<FileViewerBloc>()..add(FileViewerEvent.started(fileId)),
    child: const _FileViewerView(),
  );
}

class _FileViewerView extends StatelessWidget with ErrorsMessageMixin {
  const _FileViewerView();

  Future<void> _openExternal(BuildContext context, String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      context.showSnack(context.localizations.academicFileOpenFailed);
    }
  }

  Future<void> _delete(BuildContext context, SubjectFile file) async {
    final l10n = context.localizations;
    final bloc = context.read<FileViewerBloc>();
    final ok = await confirmDestructive(
      context,
      title: l10n.academicFileDeleteTitle,
      message: l10n.academicDeleteMessage(file.fileName),
    );
    if (ok) bloc.add(const FileViewerEvent.deleteRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<FileViewerBloc, FileViewerState>(
      listenWhen: (a, b) =>
          a.deleted != b.deleted ||
          a.actionError != b.actionError ||
          a.navigation != b.navigation,
      listener: (context, state) {
        final navigation = state.navigation;
        if (state.deleted) {
          context.showSnack(l10n.academicFileDeleted);
          context.pop(true);
        } else if (navigation != null) {
          context.push(
            navigation.practice
                ? AcademicPaths.practice(navigation.materialId)
                : AcademicPaths.review(navigation.materialId),
          );
        } else if (state.actionError != null) {
          context.showSnack(errorMessage(context, state.actionError!));
        }
      },
      builder: (context, state) {
        final content = state.content;
        if (content == null) {
          return Scaffold(
            appBar: const AppPageBar(),
            body: state.error != null
                ? AppErrorView(
                    error: state.error!,
                    onRetry: () => context.read<FileViewerBloc>().add(
                      FileViewerEvent.started(state.fileId),
                    ),
                  )
                : const AppLoadingView(),
          );
        }
        final file = content.file;
        return Scaffold(
          appBar: AppPageBar(
            title: Text(
              file.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (file.aiReadable)
                IconButton(
                  tooltip: l10n.academicAiAssistantTitle,
                  icon: Icon(
                    Icons.auto_awesome_rounded,
                    color: context.colors.tertiary,
                  ),
                  onPressed: () => showAiAssistantSheet(
                    context,
                    sourceType: StudySourceType.file,
                    sourceId: file.id,
                    title: file.fileName,
                    availability: state.availability,
                  ),
                ),
              IconButton(
                tooltip: l10n.academicFileOpenExternal,
                icon: const Icon(Icons.open_in_new_rounded),
                onPressed: () => _openExternal(context, content.url.url),
              ),
              PopupMenuButton<String>(
                tooltip: l10n.academicMoreActions,
                onSelected: (_) => _delete(context, file),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(
                        Icons.delete_outline_rounded,
                        color: context.colors.error,
                      ),
                      title: Text(l10n.commonDelete),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Como en el visor de apuntes: repasar y practicar a la vista (antes
          // estaban escondidos en el menú). Solo si la IA puede leerlo.
          bottomNavigationBar: file.aiReadable
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(TokensSpacing.m),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppSecondaryButton(
                            label: l10n.academicActionReview,
                            icon: const Icon(Icons.replay_rounded),
                            loading: state.requestedPractice == false,
                            onPressed: state.busy
                                ? null
                                : () => context.read<FileViewerBloc>().add(
                                    const FileViewerEvent.materialRequested(
                                      practice: false,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: TokensSpacing.s),
                        Expanded(
                          child: AppPrimaryButton(
                            label: l10n.academicActionPractice,
                            icon: Icons.quiz_outlined,
                            loading: state.requestedPractice == true,
                            onPressed: state.busy
                                ? null
                                : () => context.read<FileViewerBloc>().add(
                                    const FileViewerEvent.materialRequested(
                                      practice: true,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
          body: Column(
            children: [
              if (state.busy) const LinearProgressIndicator(),
              Expanded(
                child: _Preview(content: content, onOpen: _openExternal),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.content, required this.onOpen});

  final FileContent content;
  final Future<void> Function(BuildContext, String) onOpen;

  @override
  Widget build(BuildContext context) {
    final file = content.file;
    final bytes = content.bytes;
    if (file.isPdf && bytes != null) return _PdfPreview(bytes: bytes);
    if (file.isImage) {
      return InteractiveViewer(
        maxScale: 5,
        child: Center(
          child: Semantics(
            image: true,
            label: file.fileName,
            child: CachedNetworkImage(
              imageUrl: content.url.url,
              httpHeaders: content.url.headers,
              placeholder: (_, _) => const AppLoadingView(),
              errorWidget: (_, _, _) => Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }
    final l10n = context.localizations;
    return AppEmptyState(
      icon: fileIcon(file),
      title: file.fileName,
      message: '${fileSize(file.sizeBytes)} · ${l10n.academicFileNoPreview}',
      action: AppPrimaryButton(
        label: l10n.academicFileOpenExternal,
        icon: Icons.open_in_new_rounded,
        onPressed: () => onOpen(context, content.url.url),
      ),
    );
  }
}

class _PdfPreview extends StatefulWidget {
  const _PdfPreview({required this.bytes});

  final Uint8List bytes;

  @override
  State<_PdfPreview> createState() => _PdfPreviewState();
}

class _PdfPreviewState extends State<_PdfPreview> {
  late final PdfControllerPinch _controller = PdfControllerPinch(
    document: PdfDocument.openData(widget.bytes),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.colors.surfaceContainerLow,
    child: Padding(
      padding: const EdgeInsets.all(TokensSpacing.xs),
      child: PdfViewPinch(controller: _controller),
    ),
  );
}
