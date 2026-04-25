import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/config/env_config.dart';
import '../../../core/design_system/sv_colors.dart';
import '../../../shared/widgets/sv_primary_button.dart';
import 'auth_controller.dart';

class AccesoScreen extends ConsumerStatefulWidget {
  const AccesoScreen({super.key});

  @override
  ConsumerState<AccesoScreen> createState() => _AccesoScreenState();
}

class _AccesoScreenState extends ConsumerState<AccesoScreen> {
  final _correoCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  StreamSubscription<sb.AuthState>? _subscripcionAuth;
  bool _mostrarContrasena = false;
  bool _validandoSesion = true;

  @override
  void initState() {
    super.initState();

    if (!EnvConfig.hasSupabase) return;

    _subscripcionAuth =
        sb.Supabase.instance.client.auth.onAuthStateChange.listen((evento) {
      if (!mounted) return;

      if (evento.event == sb.AuthChangeEvent.signedIn) {
        ref.read(authControllerProvider.notifier).sincronizarSesionActiva();
      }
    });

    _validarSesionActiva();
  }

  @override
  void dispose() {
    _subscripcionAuth?.cancel();
    _correoCtrl.dispose();
    _contrasenaCtrl.dispose();
    super.dispose();
  }

  Future<void> _validarSesionActiva() async {
    final sesion = await ref.read(authRepositoryProvider).estadoSesionActual();

    if (!mounted) return;

    if (sesion.autenticado) {
      context.go(sesion.requiereOnboarding ? '/onboarding' : '/dashboard');
      return;
    }

    setState(() {
      _validandoSesion = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_validandoSesion) {
      return const Scaffold(
        backgroundColor: SVColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    ref.listen<AuthState>(authControllerProvider, (anterior, actual) {
      if (actual.loading || !mounted) return;

      if (actual.error != null && actual.error != anterior?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(actual.error!),
            backgroundColor: SVColors.error,
          ),
        );
        return;
      }

      if (actual.autenticado && anterior?.autenticado != true) {
        if (actual.requiereOnboarding) {
          context.go('/onboarding');
        } else {
          context.go('/dashboard');
        }
      }
    });

    final estado = ref.watch(authControllerProvider);
    final tema = Theme.of(context);

    return Scaffold(
      backgroundColor: SVColors.background,
      body: Stack(
        children: [
          const _FondoModernoAcceso(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: 'Volver',
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go('/dashboard'),
                        child: const Text('Explorar'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Hero(
                    tag: 'app_logo',
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 82,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.fitness_center_rounded,
                        size: 82,
                        color: SVColors.primary,
                      ),
                    ),
                  )
                      .animate()
                      .fade(duration: 420.ms)
                      .scale(begin: const Offset(0.94, 0.94)),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 620),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                    decoration: BoxDecoration(
                      color: SVColors.surfaceContainerLowest.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(26),
                      border:
                          Border.all(color: SVColors.outline.withOpacity(0.12)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Accede a tu progreso',
                          style: tema.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: SVColors.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Continua tus objetivos academicos y de bienestar sin perder el ritmo.',
                          style: tema.textTheme.bodyMedium?.copyWith(
                            color: SVColors.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 52,
                          child: OutlinedButton(
                            onPressed: estado.loading
                                ? null
                                : () => ref
                                    .read(authControllerProvider.notifier)
                                    .loginConGoogle(),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                color: SVColors.outline.withOpacity(0.35),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F3F4),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'G',
                                    style: tema.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1A73E8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Continuar con Google',
                                  style: tema.textTheme.labelLarge?.copyWith(
                                    color: SVColors.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: SVColors.outline.withOpacity(0.35),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'o con correo',
                                style: tema.textTheme.labelMedium?.copyWith(
                                  color: SVColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: SVColors.outline.withOpacity(0.35),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _correoCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Correo institucional',
                            hintText: 'ejemplo@universidad.edu',
                            prefixIcon: Icon(
                              Icons.alternate_email_rounded,
                              color: SVColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _contrasenaCtrl,
                          obscureText: !_mostrarContrasena,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Contrasena',
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              color: SVColors.primary,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _mostrarContrasena = !_mostrarContrasena;
                                });
                              },
                              icon: Icon(
                                _mostrarContrasena
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: SVColors.outline,
                              ),
                            ),
                          ),
                          onSubmitted: (_) {
                            if (!estado.loading) {
                              ref.read(authControllerProvider.notifier).login(
                                    email: _correoCtrl.text.trim(),
                                    password: _contrasenaCtrl.text,
                                  );
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 54,
                          child: SVPrimaryButton(
                            label: estado.loading
                                ? 'Ingresando...'
                                : 'Iniciar sesion',
                            onPressed: estado.loading
                                ? null
                                : () => ref
                                    .read(authControllerProvider.notifier)
                                    .login(
                                      email: _correoCtrl.text.trim(),
                                      password: _contrasenaCtrl.text,
                                    ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: estado.loading
                              ? null
                              : () => ref
                                  .read(authControllerProvider.notifier)
                                  .registro(
                                    email: _correoCtrl.text.trim(),
                                    password: _contrasenaCtrl.text,
                                  ),
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('Crear cuenta'),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fade(duration: 500.ms, delay: 80.ms)
                      .slideY(begin: 0.06),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FondoModernoAcceso extends StatelessWidget {
  const _FondoModernoAcceso();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFEAF4FF),
                Color(0xFFF6FBF3),
                Color(0xFFF9F7ED),
              ],
            ),
          ),
        ),
        Positioned(
          top: -30,
          left: -60,
          child: Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SVColors.primary.withOpacity(0.08),
            ),
          ),
        ),
        Positioned(
          top: 120,
          right: -40,
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SVColors.secondary.withOpacity(0.1),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
                begin: -10,
                end: 10,
                duration: 2600.ms,
              ),
        ),
      ],
    );
  }
}
