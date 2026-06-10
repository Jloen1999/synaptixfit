# 10 - Despliegue (Deployment)

**Proyecto:** SynaptixFit  
**Versión:** 2.0  
**Fecha:** 07-06-2026

---

## 1. Entornos

| Entorno | Propósito | Supabase | R2 Bucket |
|---------|----------|----------|-----------|
| **Development** | Desarrollo local | Proyecto dev | `synaptixfit-media-dev` |
| **Staging** | Pruebas pre-producción | Proyecto staging | `synaptixfit-media-staging` |
| **Production** | Usuarios finales | Proyecto prod | `synaptixfit-media` |

---

## 2. Infraestructura

### 2.1 Supabase (Backend gestionado)

| Componente | Configuración MVP |
|------------|------------------|
| Base de datos | PostgreSQL (plan Free/Pro) |
| Autenticación | Email/password + Google OAuth |
| Realtime | WebSocket (máx. conexiones según plan) |
| Región | Más cercana al público objetivo |

### 2.2 Cloudflare R2 (Almacenamiento multimedia)

| Aspecto | Configuración |
|---------|--------------|
| Bucket | `synaptixfit-media` |
| Acceso | URLs firmadas vía Cloudflare Workers |
| CORS | Habilitado para dominio de la app |
| Límite free tier | 10 GB almacenamiento, 10M solicitudes/mes |

### 2.3 Distribución de la App

| Plataforma | Canal |
|------------|-------|
| Android | Google Play Store |
| iOS | Apple App Store |
| Web | Hosting estático (Cloudflare Pages / Vercel) |

---

## 3. Pipeline CI/CD

```mermaid
flowchart LR
    Dev["Push a branch"] --> Lint["Lint + Formateo"]
    Lint --> Test["Tests unitarios + integración"]
    Test --> Build["Flutter build"]
    Build --> Review["Pull Request → Code Review"]
    Review --> Master["Merge a master"]
    Master --> Deploy["Despliegue automático (futuro)"]
    Deploy --> Store["Play Store / App Store"]
    Deploy --> Backend["Supabase migrations"]
```

### 3.1 Comandos de build

```bash
# Android (APK para testing)
flutter build apk --release

# Android (App Bundle para Play Store)
flutter build appbundle --release

# iOS
flutter build ipa --release

# Web
flutter build web --release
```

### 3.2 Despliegue de base de datos

```bash
# Migraciones de base de datos
supabase db push

# Alternativa: ejecutar migraciones_pendientes.sql en SQL Editor de Supabase
# (útil si el CLI no está vinculado al proyecto)

# Verificar estado
supabase status
```

> **Nota:** No hay Edge Functions que desplegar. Toda la lógica de negocio se ejecuta en el cliente Flutter.

### 3.3 Configuración de pg_cron (Job nocturno — futuro)

> **Estado:** No implementado en MVP. El job nocturno `generar_recomendaciones_diarias()` es una optimización futura.

Si se activa en el futuro:
1. Habilitar extensión `pg_cron` en Supabase (plan Pro+)
2. Ejecutar en SQL Editor:
```sql
CREATE EXTENSION IF NOT EXISTS pg_cron;
SELECT cron.schedule('recomendaciones-diarias', '0 2 * * *',
  'SELECT generar_recomendaciones_diarias();');
```

---

## 4. Variables de Entorno por Entorno

Ver [08-installation.md](08-installation.md) para la lista completa. Cada entorno debe tener su propio archivo `.env` con las credenciales correspondientes.

---

## 5. Monitorización

| Aspecto | Herramienta | Métrica |
|---------|------------|---------|
| Errores de app | Supabase Analytics / Crashlytics | Tasa de errores < 1% |
| Rendimiento BD | Supabase Dashboard | Queries lentas > 500ms |
| Disponibilidad | Supabase Health | ≥ 99.5% mensual (RNF-CON-01) |
| Uso R2 | Cloudflare Dashboard | Almacenamiento y solicitudes |

---

## 6. Estrategia de Rollback

1. **Migraciones SQL:** Cada migración tiene su script de reversión en `supabase/migrations/`.
2. **App:** Publicación gradual (staged rollout) en Play Store. Rollback manual si tasa de errores sube.

## 7. Guía de Despliegue de Cloudflare Worker

A continuación, se detalla el proceso paso a paso para crear y desplegar el Cloudflare Worker encargado de gestionar las solicitudes a los buckets R2.

### Paso 1: Navegar a Workers & Pages
En el panel de control de Cloudflare, dirígete a la sección **Workers & Pages**.

![Workers & Pages](/c:/Users/JLOel/Desktop/synaptixfit/app/assets/images/documentacion/worker/workers_pages.png)

### Paso 2: Crear una nueva aplicación
Haz clic en el botón para **Create application**.

![Create Application](/c:/Users/JLOel/Desktop/synaptixfit/app/assets/images/documentacion/worker/create_application.png)

### Paso 3: Seleccionar plantilla
Elige crear un Worker, utilizando la plantilla básica (por ejemplo, **Hello World**).

![Start with Hello World](/c:/Users/JLOel/Desktop/synaptixfit/app/assets/images/documentacion/worker/start_with_helloworld.png)

### Paso 4: Nombrar el Worker
Asigna un nombre descriptivo a tu Worker, como `synaptixfit-media-worker`, y procede a desplegarlo inicialmente.

![Name the Worker](/c:/Users/JLOel/Desktop/synaptixfit/app/assets/images/documentacion/worker/worker_name.png)

### Paso 5: Confirmación de despliegue
Espera a que el despliegue inicial se complete exitosamente.

![Worker Deployed](/c:/Users/JLOel/Desktop/synaptixfit/app/assets/images/documentacion/worker/worker_deploy.png)

### Paso 6: Editar el código
Haz clic en **Edit code** para reemplazar el código generado por defecto con la lógica necesaria para manejar las peticiones a nuestro bucket R2.

![Edit Code](/c:/Users/JLOel/Desktop/synaptixfit/app/assets/images/documentacion/worker/edit_code.png)

*Nota: Asegúrate de configurar las variables de entorno necesarias (como la URL de tu backend o las claves si requiere autenticación de servidor a servidor) en la configuración del Worker.*

---

**Documento compilado:** 08-06-2026  
**Última revisión:** v2.1
