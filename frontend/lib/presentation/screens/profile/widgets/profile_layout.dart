import 'package:flutter/material.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Ancho máximo del contenido del módulo en pantallas grandes.
const double profileMaxContentWidth = TokensLayout.readingMaxWidth;

/// Centra el contenido y limita su ancho (móvil y web).
class ProfileConstrained extends StatelessWidget {
  const ProfileConstrained({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      AppContentWidth(maxWidth: profileMaxContentWidth, child: child);
}

/// Cuerpo desplazable con ancho limitado y márgenes del sistema de diseño.
///
/// Monta todos los hijos a la vez (no es una lista perezosa): las pantallas
/// del perfil son formularios cortos y, en una lista perezosa, el `Form` de
/// arriba se desmontaba al bajar hasta «Guardar» y el guardado no hacía nada
/// (fallo 12, ADR 0036).
class ProfileScrollBody extends StatelessWidget {
  const ProfileScrollBody({
    super.key,
    required this.children,
    this.controller,
    this.physics,
  });

  final List<Widget> children;
  final ScrollController? controller;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: controller,
      physics: physics,
      padding: const EdgeInsets.all(TokensSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final child in children) ProfileConstrained(child: child),
        ],
      ),
    );
  }
}

/// Título de un bloque de formulario (encabezado para el lector de pantalla)
/// con subtítulo y pastilla de estado ([trailing]) opcionales.
class ProfileFormSection extends StatelessWidget {
  const ProfileFormSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final heading = Semantics(
      header: true,
      child: Text(title, style: context.textStyles.titleMedium),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Con texto grande la pastilla de [trailing] va debajo del título:
          // en una fila, en francés o portugués, lo dejaría sin sitio.
          if (trailing != null && context.largeText) ...[
            heading,
            const SizedBox(height: TokensSpacing.xs),
            Align(alignment: AlignmentDirectional.centerStart, child: trailing),
          ] else
            Row(
              children: [
                Expanded(child: heading),
                ?trailing,
              ],
            ),
          if (subtitle != null) ...[
            const SizedBox(height: TokensSpacing.xxs),
            Text(
              subtitle!,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: TokensSpacing.s),
          child,
        ],
      ),
    );
  }
}

/// Texto de error bajo un grupo de opciones (chips, tarjetas).
class ProfileFieldError extends StatelessWidget {
  const ProfileFieldError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: TokensSpacing.xs),
      child: Text(
        message,
        style: context.textStyles.bodySmall?.copyWith(
          color: context.colors.error,
        ),
      ),
    );
  }
}

/// Fila etiqueta–valor para los resúmenes del perfil. Si falta el dato
/// ([value] nulo) dice «Sin indicar» y, con [onEdit], toda la fila es un botón
/// que abre «Editar» para ponerlo (lo nombrado se puede tocar).
class ProfileInfoRow extends StatelessWidget {
  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onEdit,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final value = this.value;
    final missing = value == null;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: TokensSpacing.xs),
      child: Row(
        children: [
          Icon(
            icon,
            size: TokensSize.iconS,
            color: context.colors.onSurfaceVariant,
          ),
          const SizedBox(width: TokensSpacing.s),
          Expanded(
            child: Text(
              label,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: TokensSpacing.s),
          Flexible(
            child: Text(
              value ?? l10n.profileNotSet,
              textAlign: TextAlign.end,
              style: context.textStyles.bodyMedium?.copyWith(
                fontWeight: missing ? null : FontWeight.w600,
                color: missing ? context.colors.onSurfaceVariant : null,
              ),
            ),
          ),
          if (missing && onEdit != null) ...[
            const SizedBox(width: TokensSpacing.xs),
            Icon(
              AppIcons.edit,
              size: TokensSize.iconS,
              color: context.colors.onSurfaceVariant,
            ),
          ],
        ],
      ),
    );
    final edit = onEdit;
    if (!missing || edit == null) return row;
    return AppFocusOutline(
      child: InkWell(
        borderRadius: BorderRadius.circular(TokensRadius.m),
        onTap: edit,
        child: Semantics(
          button: true,
          onTapHint: l10n.commonEdit,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: TokensLayout.minTouchTarget,
            ),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: row,
            ),
          ),
        ),
      ),
    );
  }
}
