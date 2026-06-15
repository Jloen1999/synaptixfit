import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/sv_primary_button.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FeatureScaffold(
      title: 'SynaptixFit',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fitness_center, size: 72),
              const SizedBox(height: 16),
              Text('Bienvenido a SynaptixFit',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Tu compañero de estudio y bienestar universitario.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SVPrimaryButton(
                label: 'Continuar',
                onPressed: () => context.go('/acceso'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
