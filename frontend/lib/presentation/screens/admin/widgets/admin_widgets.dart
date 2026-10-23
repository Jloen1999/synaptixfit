import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../extensions/context_extensions.dart';
import '../../../theme/tokens.g.dart';
import '../../../widgets/widgets.dart';

/// Centra el contenido del panel con el ancho de los paneles anchos
/// ([AppContentWidth.wide]); sus barras usan [AppPageBar.wide].
class AdminContentWidth extends StatelessWidget {
  const AdminContentWidth({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => AppContentWidth.wide(child: child);
}

/// Fila etiqueta / valor para fichas de datos.
class AdminKeyValue extends StatelessWidget {
  const AdminKeyValue({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: TokensSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: TokensSpacing.s),
          Expanded(
            flex: 3,
            child: SelectableText(value, style: context.textStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Barra de paginación: anterior, «página x de y» y siguiente.
class AdminPaginationBar extends StatelessWidget {
  const AdminPaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.totalItems,
    required this.onPageSelected,
  });

  final int page;
  final int totalPages;
  final int totalItems;
  final ValueChanged<int> onPageSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.localizations;
    final pages = totalPages < 1 ? 1 : totalPages;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TokensSpacing.m,
        vertical: TokensSpacing.s,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.adminPaginationTotal(totalItems),
              style: context.textStyles.labelMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.adminPaginationPrevious,
            onPressed: page > 0 ? () => onPageSelected(page - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text(
            l10n.adminPaginationPage(page + 1, pages),
            style: context.textStyles.labelLarge,
          ),
          IconButton(
            tooltip: l10n.adminPaginationNext,
            onPressed: page + 1 < pages ? () => onPageSelected(page + 1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

/// Mantiene vivo el estado de una pestaña al cambiar de pestaña.
class AdminKeepAlive extends StatefulWidget {
  const AdminKeepAlive({super.key, required this.child});

  final Widget child;

  @override
  State<AdminKeepAlive> createState() => _AdminKeepAliveState();
}

class _AdminKeepAliveState extends State<AdminKeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// Formatos de fecha del panel (locale `es`).
abstract final class AdminFormat {
  static String dateTime(DateTime? value) =>
      value == null ? '—' : DateFormat('d MMM y, HH:mm', 'es').format(value);

  static String date(DateTime? value) =>
      value == null ? '—' : DateFormat('d MMM y', 'es').format(value);

  static String shortDate(DateTime value) =>
      DateFormat('d MMM', 'es').format(value);

  static String number(num value) =>
      NumberFormat.decimalPattern('es').format(value);

  static String decimal(double? value) =>
      value == null ? '—' : NumberFormat('0.#', 'es').format(value);
}
