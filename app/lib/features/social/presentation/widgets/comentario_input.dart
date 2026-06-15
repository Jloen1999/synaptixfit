import 'package:flutter/material.dart';

/// Barra inferior para escribir comentarios.
///
/// Muestra un TextField con hint y botón de enviar. Valida entre 1 y 500
/// caracteres antes de llamar [onEnviar].
class ComentarioInput extends StatefulWidget {
  const ComentarioInput({
    required this.onEnviar,
    this.enviando = false,
    super.key,
  });

  /// Callback con el texto del comentario cuando el usuario pulsa enviar.
  final ValueChanged<String> onEnviar;

  /// Si es `true`, deshabilita el input (e.g., mientras se envía a la BD).
  final bool enviando;

  @override
  State<ComentarioInput> createState() => _ComentarioInputState();
}

class _ComentarioInputState extends State<ComentarioInput> {
  final _controller = TextEditingController();
  bool _tieneTexto = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => _validarTexto());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _validarTexto() {
    final texto = _controller.text.trim();
    final activo = texto.isNotEmpty && texto.length <= 500;
    if (activo != _tieneTexto) {
      setState(() => _tieneTexto = activo);
    }
  }

  void _enviar() {
    final texto = _controller.text.trim();
    if (texto.isEmpty || texto.length > 500) return;
    widget.onEnviar(texto);
    _controller.clear();
    setState(() => _tieneTexto = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !widget.enviando,
              maxLength: 500,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _tieneTexto ? _enviar() : null,
              decoration: InputDecoration(
                hintText: 'Escribe un comentario...',
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color:
                        theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                  ),
                ),
                counterStyle: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                ),
              ),
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: IconButton.filled(
              onPressed: (_tieneTexto && !widget.enviando) ? _enviar : null,
              icon: widget.enviando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                disabledBackgroundColor:
                    theme.colorScheme.surfaceContainerHighest,
                disabledForegroundColor:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
