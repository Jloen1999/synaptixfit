import 'package:flutter/material.dart';

import '../../domain/errors/app_error.dart';
import '../extensions/context_extensions.dart';
import '../mixins/errors_message_mixin.dart';
import '../theme/app_icons.dart';
import '../theme/tokens.g.dart';
import 'app_secondary_button.dart';

/// Indicador al final de una lista paginada mientras carga la siguiente página.
class LoadMoreIndicator extends StatelessWidget {
  const LoadMoreIndicator({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(TokensSpacing.m),
    child: Center(
      child: SizedBox.square(
        dimension: TokensSize.iconM,
        child: CircularProgressIndicator(
          semanticsLabel: context.localizations.commonLoadingMore,
        ),
      ),
    ),
  );
}

/// Fila al final de una lista paginada cuando falla la siguiente página: el
/// motivo y «Reintentar», para que no parezca que la lista se ha terminado.
class LoadMoreError extends StatelessWidget with ErrorsMessageMixin {
  const LoadMoreError({super.key, required this.error, required this.onRetry});

  final AppError error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(TokensSpacing.m),
    child: Column(
      children: [
        Text(
          errorMessage(context, error),
          textAlign: TextAlign.center,
          style: context.textStyles.bodyMedium,
        ),
        const SizedBox(height: TokensSpacing.s),
        AppSecondaryButton(
          label: context.localizations.commonRetry,
          icon: const Icon(AppIcons.refresh),
          onPressed: onRetry,
        ),
      ],
    ),
  );
}

/// Pide la siguiente página cuando el scroll vertical se acerca al final.
bool onScrollNearEnd(ScrollNotification notification, VoidCallback loadMore) {
  if (notification.metrics.axis == Axis.vertical &&
      notification.metrics.extentAfter < _nearEnd) {
    loadMore();
  }
  return false;
}

/// Distancia al final (píxeles lógicos) a la que se pide la siguiente página.
const double _nearEnd = 400;
