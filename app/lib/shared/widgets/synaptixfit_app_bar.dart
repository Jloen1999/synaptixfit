import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void handleSynaptixBackNavigation(BuildContext context, {String? backPath}) {
  if (context.canPop()) {
    context.pop();
    return;
  }

  if (backPath != null) {
    context.go(backPath);
  }
}

class SynaptixFitAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SynaptixFitAppBar({
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.backPath,
    this.onBack,
    this.leading,
    this.centerTitle = true,
    this.compact = false,
    super.key,
  });

  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final String? backPath;
  final VoidCallback? onBack;
  final Widget? leading;
  final bool centerTitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) return const SizedBox.shrink();
    final canGoBack = context.canPop() || backPath != null || onBack != null;
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      centerTitle: centerTitle,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: showBackButton && canGoBack
          ? BackButton(
              onPressed: onBack ??
                  () {
                    handleSynaptixBackNavigation(context, backPath: backPath);
                  },
            )
          : leading,
      actions: actions,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Size get preferredSize =>
      compact ? Size.zero : const Size.fromHeight(kToolbarHeight);
}
