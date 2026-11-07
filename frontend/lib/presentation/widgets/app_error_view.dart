import 'package:flutter/material.dart';

import '../../domain/errors/app_error.dart';
import '../extensions/context_extensions.dart';
import '../mixins/errors_message_mixin.dart';
import '../theme/app_icons.dart';
import '../theme/tokens.g.dart';
import 'app_secondary_button.dart';

/// Vista de error con texto traducido y botón de reintento.
class AppErrorView extends StatelessWidget with ErrorsMessageMixin {
  const AppErrorView({super.key, required this.error, this.onRetry});

  final AppError error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TokensSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              error is NetworkError
                  ? Icons.wifi_off_rounded
                  : Icons.error_outline_rounded,
              size: TokensSize.iconXl,
              color: context.colors.error,
            ),
            const SizedBox(height: TokensSpacing.m),
            Text(
              errorMessage(context, error),
              textAlign: TextAlign.center,
              style: context.textStyles.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: TokensSpacing.m),
              AppSecondaryButton(
                onPressed: onRetry,
                icon: const Icon(AppIcons.refresh),
                label: context.localizations.commonRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
