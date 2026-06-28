import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/insignias/application/insignias_provider.dart';
import '../../features/sync/presentation/widgets/offline_indicator.dart';
import '../../shared/widgets/bottom_nav_bar.dart';

class SynaptixShellRoute extends ConsumerWidget {
  const SynaptixShellRoute({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(insigniasRecienObtenidasProvider, (prev, next) {
      if (next.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) mostrarInsigniaToast(context, next);
        });
      }
    });

    return Scaffold(
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
