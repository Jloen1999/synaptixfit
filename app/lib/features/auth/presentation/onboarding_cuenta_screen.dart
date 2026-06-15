import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/widgets/feature_scaffold.dart';
import '../../../shared/widgets/sv_primary_button.dart';

/// Pantalla de onboarding para configurar nombre y contraseña tras registro
/// con Google. Permite establecer una contraseña para login alternativo con
/// email/password en el futuro.
class OnboardingCuentaScreen extends ConsumerStatefulWidget {
  const OnboardingCuentaScreen({super.key});

  @override
  ConsumerState<OnboardingCuentaScreen> createState() =>
      _OnboardingCuentaScreenState();
}

class _OnboardingCuentaScreenState
    extends ConsumerState<OnboardingCuentaScreen> {
  final _nombreCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  bool _guardando = false;
  bool _ocultarPassword = true;
  bool _ocultarConfirmar = true;
  String? _errorPassword;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _nombreCtrl.text = user.userMetadata?['full_name'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  void _validarPassword() {
    setState(() {
      if (_passwordCtrl.text.isEmpty && _confirmarCtrl.text.isEmpty) {
        _errorPassword = null;
      } else if (_passwordCtrl.text.length < 8) {
        _errorPassword = 'La contraseña debe tener al menos 8 caracteres';
      } else if (_passwordCtrl.text != _confirmarCtrl.text) {
        _errorPassword = 'Las contraseñas no coinciden';
      } else {
        _errorPassword = null;
      }
    });
  }

  Future<void> _continuar() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('El nombre debe tener al menos 3 caracteres')),
      );
      return;
    }
    if (_passwordCtrl.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('La contraseña debe tener al menos 8 caracteres')),
      );
      return;
    }
    if (_passwordCtrl.text != _confirmarCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    setState(() => _guardando = true);
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;

      // Actualizar nombre
      if (userId != null) {
        await client.from('usuarios').update({
          'nombre_completo': nombre,
        }).eq('id', userId);
      }

      // Establecer contraseña
      await client.auth
          .updateUser(UserAttributes(password: _passwordCtrl.text));

      if (!mounted) return;
      context.go('/onboarding/fisico');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';

    return FeatureScaffold(
      title: 'Tu cuenta',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.person_add_alt_rounded, size: 48, color: cs.primary),
            const SizedBox(height: 8),
            Text('Configura tu cuenta',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('Establece tu nombre y una contraseña para iniciar sesión',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: cs.outlineVariant.withAlpha(50)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: TextEditingController(text: email),
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nombreCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo *',
                        hintText: 'ej: Juan García',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _ocultarPassword,
                      onChanged: (_) => _validarPassword(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña * (mín. 8 caracteres)',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_ocultarPassword
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _ocultarPassword = !_ocultarPassword),
                        ),
                        errorText: _errorPassword,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirmarCtrl,
                      obscureText: _ocultarConfirmar,
                      onChanged: (_) => _validarPassword(),
                      decoration: InputDecoration(
                        labelText: 'Confirmar contraseña *',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(_ocultarConfirmar
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _ocultarConfirmar = !_ocultarConfirmar),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SVPrimaryButton(
              label: _guardando ? 'Guardando...' : 'Continuar',
              onPressed: _guardando ? null : _continuar,
            ),
          ],
        ),
      ),
    );
  }
}
