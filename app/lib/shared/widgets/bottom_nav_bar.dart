import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design_system/sv_colors.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late final Future<_NavProfile?> _perfilFuture;

  @override
  void initState() {
    super.initState();
    _perfilFuture = _cargarPerfilNav();
  }

  Future<_NavProfile?> _cargarPerfilNav() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) return null;

    final perfilMap = await client
        .from('usuarios')
        .select('nombre_completo, url_avatar')
        .eq('id', user.id)
        .maybeSingle();

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final nombreGuardado = perfilMap?['nombre_completo'] as String?;
    final urlGuardada = perfilMap?['url_avatar'] as String?;
    final nombre = nombreGuardado != null && nombreGuardado.trim().isNotEmpty
        ? nombreGuardado.trim()
        : (metadata['full_name'] ?? metadata['name'] ?? user.email ?? 'Usuario')
            .toString();
    final avatarUrl = urlGuardada != null && urlGuardada.trim().isNotEmpty
        ? urlGuardada.trim()
        : (metadata['avatar_url'] ?? metadata['picture'])?.toString();

    return _NavProfile(nombre: nombre, avatarUrl: avatarUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
            child: FutureBuilder<_NavProfile?>(
              future: _perfilFuture,
              builder: (context, snapshot) {
                final profile = snapshot.data;
                return NavigationBar(
                  selectedIndex: widget.currentIndex,
                  onDestinationSelected: widget.onTap,
                  height: 76,
                  backgroundColor: Colors.transparent,
                  indicatorColor: SVColors.secondaryContainer,
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: 'Inicio',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.school_outlined),
                      selectedIcon: Icon(Icons.school_rounded),
                      label: 'Académico',
                    ),
                    NavigationDestination(
                      icon: _AvatarDestination(
                        profile: profile,
                        selected: widget.currentIndex == 2,
                      ),
                      selectedIcon: _AvatarDestination(
                        profile: profile,
                        selected: true,
                      ),
                      label: 'Perfil',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.flag_outlined),
                      selectedIcon: Icon(Icons.flag_rounded),
                      label: 'Retos',
                    ),
                    const NavigationDestination(
                      icon: Icon(Icons.people_outline),
                      selectedIcon: Icon(Icons.people_rounded),
                      label: 'Social',
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavProfile {
  const _NavProfile({required this.nombre, required this.avatarUrl});

  final String nombre;
  final String? avatarUrl;
}

class _AvatarDestination extends StatelessWidget {
  const _AvatarDestination({required this.profile, required this.selected});

  final _NavProfile? profile;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final nombre = profile?.nombre.trim() ?? '';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'P';
    final avatarUrl = profile?.avatarUrl?.trim();

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? SVColors.primary
              : Theme.of(context).colorScheme.outlineVariant,
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: selected ? 0.12 : 0.06),
            blurRadius: selected ? 10 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _AvatarFallback(inicial: inicial),
              )
            : _AvatarFallback(inicial: inicial),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.inicial});

  final String inicial;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SVColors.primary.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        inicial,
        style: const TextStyle(
          color: SVColors.primary,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}
