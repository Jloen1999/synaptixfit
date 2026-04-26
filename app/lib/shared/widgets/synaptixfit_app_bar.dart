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
    this.leading,
    this.centerTitle = true,
    super.key,
  });

  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final String? backPath;
  final Widget? leading;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final canGoBack = context.canPop() || backPath != null;
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      centerTitle: centerTitle,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: showBackButton && canGoBack
          ? BackButton(
              onPressed: () {
                handleSynaptixBackNavigation(context, backPath: backPath);
              },
            )
          : leading,
      actions: actions,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
