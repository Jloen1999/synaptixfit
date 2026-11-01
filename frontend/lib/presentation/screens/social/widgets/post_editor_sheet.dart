import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../domain/enums/post_type.dart';
import '../../../../domain/errors/app_error.dart';
import '../../../../domain/models/social/post.dart';
import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';
import 'social_feedback.dart';
import 'social_format.dart';

/// Datos de una publicación nueva o editada.
class PostDraft {
  const PostDraft({
    required this.type,
    required this.description,
    this.imageUrl,
  });

  final PostType type;
  final String description;
  final String? imageUrl;
}

/// Envía el borrador y devuelve el error si falla (la hoja sigue abierta).
typedef PostDraftSubmit = Future<AppError?> Function(PostDraft draft);

/// Tipos que el usuario puede elegir al publicar a mano. «Rutina» y «Reto»
/// no se ofrecen: una publicación así no enlazaba ninguna rutina ni reto (las
/// antiguas se siguen mostrando).
const _selectableTypes = [PostType.milestoneReached, PostType.sessionCompleted];

const _maxDescription = 2000;
const _maxImageUrl = 2048;

/// Abre la hoja para crear ([initial] nulo) o editar una publicación.
/// [initialType] preselecciona el tipo al crear (atajos de la cabecera del
/// muro). Devuelve `true` si se guardó.
Future<bool> showPostEditorSheet(
  BuildContext context, {
  Post? initial,
  PostType? initialType,
  required PostDraftSubmit onSubmit,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _PostEditorSheet(
      initial: initial,
      initialType: initialType,
      onSubmit: onSubmit,
    ),
  );
  return saved ?? false;
}

class _PostEditorSheet extends StatefulWidget {
  const _PostEditorSheet({
    required this.initial,
    required this.initialType,
    required this.onSubmit,
  });

  final Post? initial;
  final PostType? initialType;
  final PostDraftSubmit onSubmit;

  @override
  State<_PostEditorSheet> createState() => _PostEditorSheetState();
}

class _PostEditorSheetState extends State<_PostEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _description = TextEditingController(
    text: widget.initial?.description,
  );
  late final _imageUrl = TextEditingController(text: widget.initial?.imageUrl);
  // Un tipo que ya no se ofrece no dejaría ningún chip marcado.
  late PostType _type =
      widget.initial?.type ??
      (_selectableTypes.contains(widget.initialType)
          ? widget.initialType!
          : PostType.milestoneReached);
  bool _sending = false;
  AppError? _error;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _imageUrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _description.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  String? _validImageUrl() {
    final url = _imageUrl.text.trim();
    final uri = Uri.tryParse(url);
    if (url.isEmpty || uri == null || !uri.hasAuthority) return null;
    return uri.isScheme('http') || uri.isScheme('https') ? url : null;
  }

  Future<void> _submit() async {
    if (_sending || !_formKey.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    final url = _imageUrl.text.trim();
    final error = await widget.onSubmit(
      PostDraft(
        type: _type,
        description: _description.text.trim(),
        imageUrl: url.isEmpty ? null : url,
      ),
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _sending = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final preview = _validImageUrl();
    return Padding(
      padding: EdgeInsets.only(
        left: TokensSpacing.l,
        right: TokensSpacing.l,
        bottom: MediaQuery.viewInsetsOf(context).bottom + TokensSpacing.l,
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _editing
                        ? l10n.socialEditPostTitle
                        : l10n.socialCreatePostTitle,
                    style: context.textStyles.titleLarge,
                  ),
                  if (!_editing) ...[
                    const SizedBox(height: TokensSpacing.m),
                    Text(
                      l10n.socialPostTypeLabel,
                      style: context.textStyles.labelLarge,
                    ),
                    const SizedBox(height: TokensSpacing.s),
                    Wrap(
                      spacing: TokensSpacing.s,
                      runSpacing: TokensSpacing.s,
                      children: [
                        for (final type in _selectableTypes)
                          ChoiceChip(
                            avatar: Icon(type.icon, size: 18),
                            label: Text(type.label(l10n)),
                            selected: _type == type,
                            onSelected: _sending
                                ? null
                                : (_) => setState(() => _type = type),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: TokensSpacing.m),
                  TextFormField(
                    controller: _description,
                    autofocus: !_editing,
                    enabled: !_sending,
                    minLines: 3,
                    maxLines: 8,
                    maxLength: _maxDescription,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: l10n.socialPostDescriptionLabel,
                      hintText: l10n.socialPostDescriptionHint,
                      alignLabelWithHint: true,
                    ),
                    validator: (value) => (value?.trim() ?? '').isEmpty
                        ? l10n.validationRequired
                        : null,
                  ),
                  const SizedBox(height: TokensSpacing.s),
                  TextFormField(
                    controller: _imageUrl,
                    enabled: !_sending,
                    keyboardType: TextInputType.url,
                    maxLength: _maxImageUrl,
                    decoration: InputDecoration(
                      labelText: l10n.socialPostImageLabel,
                      hintText: l10n.socialPostImageHint,
                      prefixIcon: const Icon(Icons.image_outlined),
                      counterText: '',
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return null;
                      return _validImageUrl() == null
                          ? l10n.socialPostImageInvalid
                          : null;
                    },
                  ),
                  if (preview != null) ...[
                    const SizedBox(height: TokensSpacing.s),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(TokensRadius.m),
                      child: Semantics(
                        image: true,
                        label: context.localizations.socialAttachedImage,
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: CachedNetworkImage(
                            imageUrl: preview,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => ColoredBox(
                              color: context.colors.surfaceContainer,
                              child: Center(
                                child: Text(
                                  l10n.socialPostImageLoadError,
                                  style: context.textStyles.bodySmall,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: TokensSpacing.s),
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: context.colors.error,
                          size: 20,
                        ),
                        const SizedBox(width: TokensSpacing.s),
                        Expanded(
                          child: Text(
                            socialErrorText(context, _error!),
                            style: context.textStyles.bodyMedium?.copyWith(
                              color: context.colors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: TokensSpacing.m),
                  AppPrimaryButton(
                    label: _editing ? l10n.commonSave : l10n.socialPublish,
                    loading: _sending,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
