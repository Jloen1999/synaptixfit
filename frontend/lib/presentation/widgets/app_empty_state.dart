import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/tokens.g.dart';

/// Estado vacío con icono, mensaje y acción opcional. [compact] es la versión
/// para dentro de una tarjeta (Inicio): menos margen y un icono menor.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  }) : compact = false;

  const AppEmptyState.compact({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  }) : compact = true;

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final badge = compact
        ? TokensSize.emptyBadgeCompact
        : TokensSize.emptyBadge;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? TokensSpacing.s : TokensSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Container(
                width: badge,
                height: badge,
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: compact ? TokensSize.iconM : TokensSize.iconL,
                  color: context.colors.onPrimaryContainer,
                ),
              ),
            ),
            SizedBox(height: compact ? TokensSpacing.s : TokensSpacing.m),
            Text(
              title,
              style: context.textStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: TokensSpacing.s),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[
              SizedBox(height: compact ? TokensSpacing.m : TokensSpacing.l),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
