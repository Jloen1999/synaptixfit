# Plan Definitivo: Backoffice Híbrido Empresarial — Fases 1 y 2

## Correcciones al plan original

| # | Plan original | Corrección aplicada |
|---|---|---|
| 1 | Shadowban: filtrar solo tablas sociales | También filtrar `rutinas`, `retos`, `horarios_academicos` (políticas `peer_select`) |
| 2 | `WHERE is_shadowbanned = false` en SELECT | El autor debe ver su propio contenido. Condición: `(auth.uid() = autor) OR es_admin() OR NOT autor.is_shadowbanned` |
| 3 | Lockdown: bloquear INSERT creación cuentas vía RLS | Supabase Auth gestiona signups. Alternativa: trigger en `usuarios` que auto-shadowbanea cuentas creadas durante lockdown |
| 4 | Reescribir `delete_user` | NO. Crear nueva RPC `anonymize_user`. Conservar `delete_user` para cuentas spam sin valor analítico |
| 5 | UUID fijo para anonimización | Usar `gen_random_uuid()` por usuario (evita fusionar datos anonimizados en un bucket) |
| 6 | Exportación JSON desde Flutter | RPC SECURITY DEFINER en BD para completitud |
| 7 | Falta: eliminar `auth.users` | Hacerlo dentro de la RPC (`DELETE FROM auth.users`) con SECURITY DEFINER |

## Migración 29: Shadowban + Modo Pánico

### Nuevas estructuras
- `usuarios.is_shadowbanned BOOLEAN DEFAULT false` + índice parcial
- `configuracion_global` (fila única, `id BOOLEAN PK CHECK(id=true)`): `lockdown_activo`, `lockdown_iniciado_en`, `lockdown_iniciado_por`

### Funciones SECURITY DEFINER
- `lockdown_activo()` — lee config global
- `excluir_si_shadowban(p_autor_id)` — `STABLE SECURITY DEFINER`, decide visibilidad: `(self OR admin OR NOT autor.shadowbanned)`

### Políticas RLS modificadas (6 tablas)
actividades_sociales, comentarios_feed, interacciones_sociales, rutinas, retos, horarios_academicos

### Triggers
- `trg_lockdown_shadowban_nuevo` — BEFORE INSERT en `usuarios`: fuerza `is_shadowbanned = true` si `lockdown_activo()`
- `trg_auditar_config_global` — BEFORE UPDATE en `configuracion_global`: registra en `admin_auditoria`

## Migración 30: GDPR

### RPC `anonymize_user(p_usuario_id UUID)`
Fase 1 ANONIMIZAR (UPDATE usuario_id → v_anon_id): sesiones_registradas, carga_academica_semanal, horarios_academicos, estado_cognitivo_usuario, estado_regulacion_cruzada, registros_carga_fisica, registros_repaso_srs, estado_diario_usuario, series_sesion

Fase 2 ELIMINAR: resto de tablas con datos personales

Fase 3: DELETE FROM public.usuarios + DELETE FROM auth.users

### RPC `exportar_datos_usuario(p_usuario_id UUID)`
JSON con 22 secciones de datos del usuario

## Cambios Flutter

| Archivo | Cambio |
|---|---|
| `admin_dto.dart` | `isShadowbanned: bool` |
| `admin_repository.dart` | `toggleShadowban()`, `getLockdownState()`, `toggleLockdown()`, `anonymizeUser()`, `exportUserData()` |
| `admin_provider.dart` | Mutaciones + invalidación |
| `admin_hub_screen.dart` | Toggle Lockdown en KPIs |
| `admin_usuario_detalle.dart` | Switch shadowban + botones GDPR |
| `sync_hub.dart` | Eventos `shadowbanToggled`, `lockdownToggled` |
