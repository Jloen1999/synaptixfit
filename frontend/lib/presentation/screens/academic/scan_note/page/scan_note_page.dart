import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/di/app_di.dart';
import '../../../../extensions/context_extensions.dart';
import '../../../../mixins/errors_message_mixin.dart';
import '../../../../theme/tokens.g.dart';
import '../../../../widgets/widgets.dart';
import '../../academic_routes.dart';
import '../../widgets/academic_widgets.dart';
import '../bloc/scan_note_bloc.dart';

/// Pega o escribe el texto escaneado de un documento y guárdalo como apunte.
class ScanNotePage extends StatelessWidget {
  const ScanNotePage({super.key, this.subjectId});

  final String? subjectId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        getIt<ScanNoteBloc>()..add(ScanNoteEvent.started(subjectId: subjectId)),
    child: const _ScanNoteView(),
  );
}

class _ScanNoteView extends StatefulWidget {
  const _ScanNoteView();

  @override
  State<_ScanNoteView> createState() => _ScanNoteViewState();
}

class _ScanNoteViewState extends State<_ScanNoteView> with ErrorsMessageMixin {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _text = TextEditingController();
  String? _subjectId;
  bool _subjectSet = false;

  @override
  void dispose() {
    _title.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    setState(() {
      _text.text = _text.text.isEmpty ? text : '${_text.text}\n$text';
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ScanNoteBloc>().add(
      ScanNoteEvent.submitted(
        title: _title.text.trim(),
        text: _text.text.trim(),
        subjectId: _subjectId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    return BlocConsumer<ScanNoteBloc, ScanNoteState>(
      listener: (context, state) {
        if (!_subjectSet && !state.loading) {
          _subjectSet = true;
          setState(() => _subjectId = state.initialSubjectId);
        }
        if (state.savedNoteId != null) {
          context.showSnack(l10n.academicNoteSaved);
          context.pushReplacement(AcademicPaths.note(state.savedNoteId!));
        } else if (state.saveError != null) {
          context.showSnack(errorMessage(context, state.saveError!));
        }
      },
      builder: (context, state) {
        final known = state.subjects.any((s) => s.id == _subjectId);
        return Scaffold(
          appBar: AppPageBar.reading(title: Text(l10n.academicScanTitle)),
          body: state.loading
              ? const AppLoadingView()
              : AcademicBody(
                  maxWidth: TokensLayout.readingMaxWidth,
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(TokensSpacing.m),
                      children: [
                        AppCard(
                          color: context.colors.tertiaryContainer.withValues(
                            alpha: 0.4,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.document_scanner_outlined,
                                color: context.colors.tertiary,
                              ),
                              const SizedBox(width: TokensSpacing.m),
                              Expanded(child: Text(l10n.academicScanExplain)),
                            ],
                          ),
                        ),
                        const SizedBox(height: TokensSpacing.m),
                        AppTextField(
                          label: l10n.academicNoteTitleLabel,
                          controller: _title,
                          validator: (v) => (v ?? '').trim().isEmpty
                              ? l10n.validationRequired
                              : null,
                        ),
                        const SizedBox(height: TokensSpacing.m),
                        DropdownButtonFormField<String?>(
                          key: ValueKey(_subjectSet),
                          initialValue: known ? _subjectId : null,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: l10n.academicNoteSubject,
                            prefixIcon: const Icon(Icons.school_outlined),
                          ),
                          items: [
                            DropdownMenuItem(
                              child: Text(l10n.academicNoteNoSubject),
                            ),
                            for (final s in state.subjects)
                              DropdownMenuItem(
                                value: s.id,
                                child: Text(
                                  s.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (v) => setState(() => _subjectId = v),
                        ),
                        const SizedBox(height: TokensSpacing.m),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _paste,
                            icon: const Icon(Icons.content_paste_rounded),
                            label: Text(l10n.academicScanPaste),
                          ),
                        ),
                        TextFormField(
                          controller: _text,
                          minLines: 12,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            labelText: l10n.academicScanTextHint,
                          ),
                          validator: (v) => (v ?? '').trim().isEmpty
                              ? l10n.validationRequired
                              : null,
                        ),
                        const SizedBox(height: TokensSpacing.l),
                        AppPrimaryButton(
                          label: l10n.academicScanSave,
                          icon: Icons.save_alt_rounded,
                          loading: state.saving,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
