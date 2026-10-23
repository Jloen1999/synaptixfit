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

/// Lista desplazable con ancho limitado y márgenes del sistema de diseño.
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
    return ListView(
      controller: controller,
      physics: physics,
      padding: const EdgeInsets.all(TokensSpacing.m),
      children: [
        for (final child in children) ProfileConstrained(child: child),
      ],
    );
  }
}

/// Título de un bloque de formulario con subtítulo opcional.
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
    return Padding(
      padding: const EdgeInsets.only(bottom: TokensSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: context.textStyles.titleMedium),
              ),
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

/// Fila etiqueta–valor para los resúmenes del perfil.
class ProfileInfoRow extends StatelessWidget {
  const ProfileInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TokensSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.colors.onSurfaceVariant),
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
              value,
              textAlign: TextAlign.end,
              style: context.textStyles.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
