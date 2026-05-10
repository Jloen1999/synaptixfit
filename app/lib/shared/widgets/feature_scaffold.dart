import 'package:flutter/material.dart';

import 'synaptixfit_app_bar.dart';

class FeatureScaffold extends StatelessWidget {
  const FeatureScaffold({
    required this.title,
    required this.child,
    this.floatingActionButton,
    this.actions,
    this.backPath,
    this.appBarLeading,
    this.centerTitle = true,
    this.hideAppBar = false,
    super.key,
  });

  final String title;
  final Widget child;
  final Widget? floatingActionButton;
  final List<Widget>? actions;
  final String? backPath;
  final Widget? appBarLeading;
  final bool centerTitle;
  final bool hideAppBar;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        handleSynaptixBackNavigation(context, backPath: backPath);
      },
      child: Scaffold(
        appBar: SynaptixFitAppBar(
          title: title,
          actions: actions,
          backPath: backPath,
          leading: appBarLeading,
          centerTitle: centerTitle,
          compact: hideAppBar,
        ),
        body: SafeArea(
          top: hideAppBar,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 1200;
              final isTablet = constraints.maxWidth >= 840;
              final maxWidth = isDesktop
                  ? 1100.0
                  : isTablet
                      ? 900.0
                      : double.infinity;
              final horizontalPadding = isDesktop
                  ? 24.0
                  : isTablet
                      ? 16.0
                      : 0.0;

              return Align(
                alignment: Alignment.topCenter,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: double.infinity,
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: child,
                ),
              );
            },
          ),
        ),
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
