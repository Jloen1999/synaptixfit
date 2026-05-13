# 03 - Arquitectura del Sistema (SynaptixFit)

**Versión:** 3.1
**Estado:** APROBADO
**Fecha:** 14-05-2026
**Autor:** Arquitectura
**Referencia:** [02-requirements.md](02-requirements.md) (SRS v3.0)

## 1. Objetivo

Definir la arquitectura completa de SynaptixFit (Flutter móvil/web + Supabase + Gemini IA), cubriendo:
1. Estructura de carpetas y módulos.
2. Modelo de datos y permisos (RLS).
3. Contratos de servicios.
4. Arquitectura del servicio de IA (Gemini Flash).
5. Sistema de check-in diario y periodización.
6. Estrategia técnica por fases (MVP → Crecimiento).

## 2. Decisiones de Arquitectura

### 2.1 Stack principal

| Capa | Tecnología | Justificación |
|------|-----------|---------------|
| **Frontend** | Flutter 3.x (Dart) + Riverpod + GoRouter | Multiplataforma, estado reactivo, routing declarativo |
| **Base de datos** | Supabase PostgreSQL 15 | Relacional, RLS nativo, Realtime |
| **Autenticación** | Supabase Auth (Google OAuth + Email) | JWT, refresh tokens, proveedores sociales |
| **Tiempo real** | Supabase Realtime (WebSocket) | Sincronización en vivo de catálogo y sesiones |
| **IA generativa** | Gemini Flash API (REST) | Cliente-side vía `dio`, sin SDK de Google |
| **Almacenamiento** | Cloudflare R2 + Worker de proxy | Multimedia de ejercicios, URLs públicas |
| **Persistencia local** | Hive | Caché offline, cola de sincronización |

### 2.2 ¿Por qué Gemini Flash y no otra IA?

| Criterio | Gemini Flash | OpenAI GPT-4o | Anthropic Claude |
|----------|-------------|---------------|-----------------|
| Latencia típica | ~2-3s | ~3-5s | ~4-6s |
| Capa gratuita | 15 RPM gratis | Pay-as-you-go | Pay-as-you-go |
| Calidad JSON | Buena con prompt engineering | Excelente | Buena |
| Disponibilidad | Global (Google Cloud) | Global | Global |

**Decisión:** Gemini Flash por su baja latencia (crítica para UX interactiva en entrenamiento) y capa gratuita generosa, adecuada para un TFG/MVP.

### 2.3 ¿Por qué IA en cliente y no en Edge Function?

| Opción | Ventaja | Desventaja |
|--------|---------|------------|
| **Cliente Flutter** (adoptado) | Sin latencia extra de red, sin coste de Edge Function, respuesta directa al UI | API key viaja en requests (mitigado: HTTPS) |
| **Edge Function Supabase** | API key nunca sale del backend | Doble latencia (cliente→Edge→Gemini→Edge→cliente), coste adicional |

**Decisión:** IA en cliente con `dio`. La API key de Gemini tiene scope limitado (solo generación de texto) y viaja sobre HTTPS. Para producción futura, se puede mover a Edge Function.

## 3. Arquitectura de Alto Nivel

```mermaid
flowchart TB
    subgraph Cliente["Cliente Flutter"]
        UI["Pantallas Flutter"]
        RV["Riverpod (Estado)"]
        RP["Repositorios"]
        subgraph Servicios["Servicios"]
            IA["RecomendacionIaService\n(Gemini Flash API)"]
            SB["Supabase Client\n(supabase_flutter)"]
        end
        Hive["Hive (Caché local)"]
    end

    subgraph Nube["Infraestructura Cloud"]
        subgraph Supabase["Supabase"]
            Auth["Auth (JWT)"]
            PG["PostgreSQL 15\n(27 tablas + RLS)"]
            RT["Realtime (WebSocket)"]
            EF["Edge Functions\n(Deno)"]
        end
        subgraph Google["Google Cloud"]
            Gemini["Gemini Flash API\n(generativelanguage.googleapis.com)"]
        end
        subgraph CF["Cloudflare"]
            R2["R2 Storage\n(Multimedia ejercicios)"]
            WK["Worker\n(firmar_url_r2)"]
        end
    end

    UI --> RV
    RV --> RP
    RP --> Servicios
    IA --> Gemini
    SB --> Supabase
    Hive --> SB
    RT --> SB
```

## 4. Arquitectura Lógica por Módulos

```mermaid
flowchart TB
    subgraph App["App Flutter"]
        UI["Presentation\n(Screens, Widgets, Dialogs)"]
        ST["State (Riverpod)\n(Providers, Notifiers)"]
        APP["Application\n(Casos de uso, Orquestación)"]
        DOM["Domain\n(Modelos, DTOs, Reglas)"]
        INF["Infrastructure\n(Repositorios, DataSources, IA Service)"]
        LOC["Local Sync Layer\n(Hive)"]
    end

    UI --> ST
    ST --> APP
    APP --> DOM
    APP --> INF
    INF --> LOC
    INF --> SP["Supabase\n(PostgreSQL + Realtime + Auth)"]
    INF --> GM["Gemini Flash API"]
    INF --> CF["Cloudflare R2"]
```

## 5. Estructura de Carpetas

```
synaptixfit/
├── docs/                          # 14 archivos de documentación
├── app/
│   └── lib/
│       ├── core/                  # Errores, utils, config, routing, design system, sync
│       │   ├── config/
│       │   │   └── env_config.dart        # Lectura de .env (Supabase, Gemini, R2, Google)
│       │   └── routing/
│       │       ├── app_router.dart         # GoRouter con 20+ rutas
│       │       └── shell_route.dart        # StatefulShellRoute (5 tabs)
│       ├── shared/
│       │   ├── models/
│       │   │   └── db_models.dart          # 25+ modelos (1645 líneas)
│       │   └── widgets/
│       ├── features/
│       │   ├── auth/                       # Login, registro, onboarding
│       │   │   └── infrastructure/
│       │   │       ├── auth_repository.dart
│       │   │       └── bienestar_repository.dart  # CRUD perfil bienestar
│       │   ├── academico/                  # Planes, asignaturas, apuntes
│       │   ├── retos/                      # Retos simples y complejos
│       │   ├── bienestar/
│       │   │   ├── infrastructure/
│       │   │   │   ├── recomendacion_ia_service.dart  # ★ Servicio IA (867 líneas)
│       │   │   │   └── ejercicios_repository.dart
│       │   │   └── application/
│       │   │       ├── rutina_provider.dart         # ★ 30+ providers y funciones
│       │   │       ├── ejercicios_provider.dart
│       │   │       └── sesion_provider.dart
│       │   ├── social/                     # Muro, likes, comentarios
│       │   ├── notificaciones/             # Centro de notificaciones
│       │   ├── dashboard/                  # Dashboard principal
│       │   └── perfil/                     # Perfil de usuario
│       └── main.dart                       # Entry point, ProviderScope, Supabase.init
├── supabase/
│   ├── migrations/                         # 17 migraciones SQL
│   ├── seed_ejercicios.py                  # Seeding del catálogo ExerciseDB
│   └── seed_catalogo.py                    # Seeding del catálogo académico
├── cloudflare/
│   └── synaptixfit-r2-proxy/
│       └── worker.js                       # Proxy R2 con CORS
└── migraciones_pendientes.sql              # SQL consolidado para deploy manual
```

## 6. Servicio de IA — Arquitectura en Profundidad

### 6.1 Diagrama de Secuencia: Recomendación de Rutina Completa

```mermaid
sequenceDiagram
    actor User as Usuario
    participant UI as NuevaRutinaScreen
    participant Prov as Riverpod Providers
    participant IA as RecomendacionIaService
    participant Gemini as Gemini Flash API
    participant SB as Supabase

    User->>UI: Pulsa "Recomendar rutina con IA"
    UI->>Prov: Lee perfilBienestarProvider
    Prov->>SB: SELECT perfil_bienestar_usuario
    SB-->>Prov: PerfilBienestarDb

    UI->>Prov: Lee historialSesionUsuarioProvider
    Prov->>SB: SELECT sesiones_registradas<br/>(últimas 4 semanas)
    SB-->>Prov: HistorialSesionDto

    UI->>Prov: Lee estadoDiarioHoyProvider
    Prov->>SB: SELECT estado_diario_usuario<br/>WHERE fecha = today
    SB-->>Prov: EstadoDiarioDb? (o null)

    UI->>Prov: Lee ejerciciosProvider
    Prov->>SB: SELECT v_ejercicios_completos
    SB-->>Prov: List<EjercicioDb>

    UI->>IA: generarRecomendacionRutina(perfil, ejercicios, historial, estadoDiario)

    rect rgb(40, 60, 120)
        Note over IA: Construcción del prompt

        IA->>IA: 1. Filtrar ejercicios por equipamiento<br/>(_ejercicioUsaEquipamiento)
        IA->>IA: 2. Formatear historial<br/>(_formatearHistorial)
        IA->>IA: 3. Formatear estado diario<br/>(_formatearEstadoDiario)
        IA->>IA: 4. Generar reglas de seguridad IMC<br/>(_reglasSeguridadIMC)
        IA->>IA: 5. Construir prompt con:<br/>- Perfil completo<br/>- Catálogo filtrado<br/>- Reglas de seguridad<br/>- Reglas de periodización<br/>- Formato JSON esperado
    end

    IA->>Gemini: POST /v1beta/models/gemini-flash-latest:generateContent
    Note over Gemini: Body: {contents: [{parts: [{text: prompt}]}]}<br/>Headers: X-goog-api-key
    Gemini-->>IA: Response (JSON con candidates[0].content.parts[0].text)

    rect rgb(40, 100, 60)
        Note over IA: Parsing de respuesta

        IA->>IA: 6. Extraer texto del candidate
        IA->>IA: 7. _extraerJson():<br/>- Buscar ```json ... ```<br/>- Buscar primer { o [<br/>- Extraer substring válido
        IA->>IA: 8. _parseMapa(): json.decode()
        IA->>IA: 9. _parseEstructura():<br/>Iterar semanas→días→ejercicios<br/>Crear List<EjercicioRecomendado>
    end

    IA-->>UI: RecomendacionRutinaResult<br/>(nombre, desc, objetivo, estructura)

    UI->>UI: Rellenar campos del formulario:<br/>- Nombre de rutina<br/>- Descripción<br/>- Objetivo (ChoiceChip)<br/>- Duración (semanas)<br/>- Estructura (semanas × días)

    User->>UI: Revisa y ajusta
    User->>UI: Pulsa "Recomendar ejercicios"
    UI->>IA: generarEstructuraCompleta(perfil, ejercicios, rutinaConfig)

    Note over IA: Prompt con:<br/>- Reglas de periodización por semana<br/>- Catálogo de ejercicios<br/>- Reglas de seguridad<br/>- Alternancia de grupos musculares<br/>- Sobrecarga progresiva si hay historial

    IA->>Gemini: POST generateContent
    Gemini-->>IA: Estructura semanas×días×ejercicios
    IA-->>UI: RecomendacionRutinaResult (estructura completa)
    UI->>UI: Rellenar Paso 2 con ejercicios por día
```

### 6.2 Diagrama de Secuencia: Check-in Diario y Sesión en Vivo

```mermaid
sequenceDiagram
    actor User as Usuario
    participant Det as RutinaDetalleScreen
    participant Dialog as _CheckInDialog
    participant Prov as rutina_provider.dart
    participant SB as Supabase
    participant Live as LiveSessionScreen

    User->>Det: Pulsa "Empezar entrenamiento"
    Det->>Det: Verifica que el día tiene ejercicios
    alt Día sin ejercicios
        Det-->>User: SnackBar: "Este día no tiene ejercicios"
    else Día con ejercicios
        Det->>Dialog: Muestra _CheckInDialog

        Note over Dialog: 4 sliders (1-5):<br/>- Calidad del sueño<br/>- Nivel de estrés<br/>- Nivel de energía<br/>- Dolor muscular

        User->>Dialog: Ajusta sliders
        alt Dolor ≥ 3
            Dialog->>Dialog: Muestra chips de zonas de dolor
            User->>Dialog: Selecciona zonas (piernas, espalda, etc.)
        end

        alt Pulsa "Empezar"
            User->>Dialog: Confirma check-in

            Dialog->>Dialog: Calcula listoParaEntrenar<br/>= sueño > 1 OR energía > 2

            Dialog->>Prov: guardarEstadoDiario(sueño, estrés, energía, dolor, zonas)
            Prov->>SB: UPSERT estado_diario_usuario<br/>ON CONFLICT (usuario_id, fecha)
            SB-->>Prov: OK
            Prov->>Prov: ref.invalidate(estadoDiarioHoyProvider)

            Dialog->>Prov: iniciarSesion(rutinaId, diaId)
            Prov->>SB: INSERT sesiones_registradas<br/>(tipo='rutina', duracion_min=1, rpe=5)
            SB-->>Prov: sesionId
            Prov->>SB: UPDATE dias_rutina SET estado='en_progreso'
            SB-->>Prov: OK

            Dialog-->>Det: Sesión iniciada (sesionId)
            Det->>Live: Navega a LiveSessionScreen
        else Pulsa "Omitir"
            User->>Dialog: Omite check-in
            Dialog->>Prov: iniciarSesion(rutinaId, diaId)
            Prov->>SB: INSERT sesiones_registradas
            SB-->>Prov: sesionId
            Dialog-->>Det: Sesión iniciada sin check-in
            Det->>Live: Navega a LiveSessionScreen
        end
    end

    Note over Live: Sesión en vivo:<br/>- Cronómetro automático<br/>- Check de series con peso/reps<br/>- Cronómetro de descanso (90s)<br/>- +15s / -15s / Saltar<br/>- Diálogo de finalización con RPE

    User->>Live: Finaliza sesión
    Live->>Prov: finalizarSesion(sesionId, diaId, rutinaId, duracion, rpe)
    Prov->>SB: UPDATE sesiones_registradas<br/>(duracion_minutos, rpe, calorias_quemadas)
    Prov->>SB: UPDATE dias_rutina SET estado='completado'
    Note over SB: Trigger trg_dias_rutina_estado:<br/>si todos los días 'completado' → semana 'completada'
    SB-->>Prov: OK
    Prov->>Prov: ref.invalidate(diasDeSemanaProvider)<br/>ref.invalidate(semanasDeRutinaProvider)

    Live->>Det: Vuelve a RutinaDetalleScreen
    Det->>Prov: Refresca progreso (días completados / total)
```

### 6.3 Diagrama de Flujo: Periodización Inteligente

```mermaid
flowchart TD
    A["crearRutinaCompleta()"] --> B{"¿Total semanas?"}

    B -->|"1 semana"| C1["tipo = 'carga'"]
    B -->|"2 semanas"| C2["Sem 1: 'adaptacion'\nSem 2: 'carga'"]
    B -->|"3 semanas"| C3["Sem 1: 'adaptacion'\nSem 2: 'carga'\nSem 3: 'pico'"]
    B -->|"4+ semanas"| C4["Sem 1: 'adaptacion'\nSem 2-N: 'carga'\nSem N: 'descarga'"]

    C1 --> D["INSERT semanas_rutina\ncon tipo_semana"]

    D --> E["UI: Badge de tipo\n(azul=adapt, verde=carga,\nnaranja=pico, teal=desc)"]

    F["estadoPeriodizacionProvider\n(se ejecuta periódicamente)"] --> G["Consulta sesiones_registradas\n(últimas 3 semanas)"]

    G --> H{"¿RPE promedio > 8.0\n+ 3+ semanas\n+ volumen decreciente?"}

    H -->|Sí| I["necesitaDescarga = true"]
    H -->|No| J{"¿Puntuación fatiga\ndiaria > 50?"}
    J -->|Sí| I
    J -->|No| K["necesitaDescarga = false"]

    I --> L["UI: Banner 'Tu cuerpo\nnecesita descanso'"]
    K --> M["Sin alerta"]
```

## 7. Modelo de Datos Relacional (Resumen)

Ver [04-data-model.md](04-data-model.md) para el esquema SQL completo con RLS. A continuación el ER conceptual actualizado:

```mermaid
erDiagram
    USUARIOS ||--|| PERFIL_BIENESTAR_USUARIO : tiene
    USUARIOS ||--o{ ESTADO_DIARIO_USUARIO : registra
    USUARIOS ||--o{ RUTINAS : crea
    USUARIOS ||--o{ SESIONES_REGISTRADAS : completa

    RUTINAS ||--o{ SEMANAS_RUTINA : periodiza
    SEMANAS_RUTINA ||--o{ DIAS_RUTINA : contiene
    DIAS_RUTINA ||--o{ SELECCION_DE_EJERCICIOS : agrupa
    EJERCICIOS ||--o{ SELECCION_DE_EJERCICIOS : referencia

    SESIONES_REGISTRADAS ||--o{ SERIES_SESION : desglosa
    SELECCION_DE_EJERCICIOS ||--o{ SERIES_SESION : referencia

    EJERCICIOS ||--o{ EJERCICIO_MUSCULO_OBJETIVO : tiene
    EJERCICIOS ||--o{ EJERCICIO_MUSCULO_SECUNDARIO : activa
    EJERCICIOS ||--o{ EJERCICIO_PARTE_CUERPO : pertenece
    EJERCICIOS ||--o{ EJERCICIO_EQUIPAMIENTO : usa

    MUSCULOS ||--o{ EJERCICIO_MUSCULO_OBJETIVO : objetivo
    MUSCULOS ||--o{ EJERCICIO_MUSCULO_SECUNDARIO : secundario
    PARTES_CUERPO ||--o{ EJERCICIO_PARTE_CUERPO : contiene
    EQUIPAMIENTOS ||--o{ EJERCICIO_EQUIPAMIENTO : se_usa
```

## 8. Servicio de IA — `RecomendacionIaService`

**Archivo:** `app/lib/features/bienestar/infrastructure/recomendacion_ia_service.dart` (867 líneas)

### 8.1 DTOs (Data Transfer Objects)

| DTO | Propósito | Campos clave |
|-----|-----------|-------------|
| `EjercicioRecomendado` | Un ejercicio con sus parámetros sugeridos | `ejercicioId`, `series`, `repeticiones`, `segundosDescanso`, `pesoKg?` |
| `RecomendacionRutinaResult` | Resultado de recomendación de metadatos o estructura | `nombre`, `descripcion`, `objetivo`, `duracionSemanas`, `estructura` (Map<semana, Map<día, List<EjercicioRecomendado>>>), `error?` |
| `RecomendacionEjerciciosResult` | Resultado de sugerencia de ejercicios para un día | `ejercicios` (List<EjercicioRecomendado>), `error?` |
| `HistorialSesionDto` | Historial agregado de sesiones para contexto IA | `totalSesionesCompletadas`, `rpePromedio`, `volumenSemanalEstimado`, `ejerciciosRecientes`, `diasCompletadosUltimaSemana`, `semanasConsecutivasEntrenando`, `requiereDescarga` |
| `EjericicioRecienteDto` | Datos de un ejercicio del historial | `nombreEjercicio`, `pesoPromedio`, `repsPromedio`, `rpePromedio`, `ultimaFecha` |

### 8.2 Métodos del Servicio

#### `generarRecomendacionRutina()`
**Propósito:** Generar metadatos de una rutina (nombre, descripción, objetivo, duración, estructura semana×día) basados en el perfil, historial y estado diario.

**Parámetros:**
- `apiKey`: Clave de Gemini desde `.env`
- `perfil`: `PerfilBienestarDb` — datos antropométricos, objetivo, equipamiento, disponibilidad
- `ejerciciosDisponibles`: Catálogo completo de ejercicios (se filtra por equipamiento)
- `historial`: `HistorialSesionDto?` — historial de sesiones (opcional)
- `estadoDiario`: `EstadoDiarioDb?` — check-in del día (opcional)

**Flujo interno:**
1. Valida que `apiKey` no esté vacía → retorna error descriptivo
2. Filtra ejercicios por equipamiento compatible (`_ejercicioUsaEquipamiento`)
3. Si no hay ejercicios compatibles → retorna error con el equipamiento listado
4. Construye prompt con: perfil, historial formateado, estado diario, reglas de seguridad IMC, reglas de periodización, formato JSON esperado
5. Llama a `_callGemini()` → extrae JSON → parsea estructura
6. Si falla → retorna `RecomendacionRutinaResult` con `error`

**Estructura del prompt:** Ver sección 6.1 del código fuente. Incluye secciones: CONTEXTO DEL USUARIO, REGLAS DE SEGURIDAD, REGLAS DE EQUIPAMIENTO, HISTORIAL DEPORTIVO, REGLAS DE RECOMENDACIÓN SEGÚN OBJETIVO, PERIODIZACIÓN, FORMATO JSON ESPERADO.

#### `generarEstructuraCompleta()`
**Propósito:** Generar la estructura completa de ejercicios (semanas × días × ejercicios) para una rutina ya configurada.

**Diferencias con `generarRecomendacionRutina()`:**
- Recibe la rutina ya configurada (nombre, descripción, objetivo, semanas, días/semana)
- El prompt incluye reglas de periodización detalladas por semana (`_reglasPeriodizacion`)
- Incluye reglas de programación por objetivo (`_reglasPorObjetivo`)
- Incluye datos de sobrecarga progresiva si hay historial (`_formatearProgresion`)
- La respuesta solo incluye el campo `estructura` (no metadatos)
- Obliga a alternar grupos musculares entre días consecutivos

#### `generarRecomendacionEjercicios()`
**Propósito:** Sugerir 3-6 ejercicios adicionales para un día específico, sin repetir los ya agregados.

**Cuándo se usa:** En el Paso 2 de creación de rutina, por cada día, el botón "Sugerir ejercicios con IA".

**Particularidades:**
- El catálogo se filtra excluyendo `ejerciciosYaAgregados` (por `exerciseDbId`)
- El prompt incluye el catálogo filtrado completo como JSON embebido
- La respuesta es un array JSON, no un objeto con estructura
- Si la respuesta está vacía o no tiene ejercicios válidos → error

#### `generarProgresionEjercicio()`
**Propósito:** Sugerir la siguiente progresión de carga (peso/reps) para un ejercicio, basada en historial real.

**Reglas de progresión implementadas en el prompt:**

| RPE Última Sesión | Acción Recomendada |
|-------------------|-------------------|
| < 7 | Subir peso 5-10% o +1-2 reps (músculo infra-desafiado) |
| 7 - 8 | Subir peso 2.5-5% o mantener reps (zona óptima) |
| 8.5 - 9.5 | Mantener peso y reps (progresión sostenida) |
| = 10 (fallo) | **NO subir peso** en la próxima sesión |

**Modulación por objetivo:**
- `fuerza` → priorizar subir peso sobre reps
- `ganar_masa` → equilibrio peso/reps, rango 8-12
- `perder_peso` → mantener o bajar ligeramente peso, subir reps
- `resistencia` → mantener peso, subir reps

### 8.3 Helpers Privados

| Método | Propósito | Detalle |
|--------|-----------|---------|
| `_ejercicioUsaEquipamiento()` | Filtro de compatibilidad | Compara equipamiento del ejercicio con el del usuario. `peso_corporal` siempre es compatible. Incluye mapeo de equivalencias (mancuerna↔mancuernas, banda_elastica↔banda de resistencia, kettlebell↔pesa rusa) |
| `_reglasSeguridadIMC()` | Restricciones por biometría | Genera reglas condicionales: IMC>30→bajo impacto, IMC<18.5→evitar déficit, edad>50→fortalecimiento articular, edad<18→priorizar técnica |
| `_reglasPeriodizacion()` | Estructura de periodización | Para 4+ semanas: adaptación→carga→carga→descarga. Si `historial.requiereDescarga`, semana 1 es descarga. Para 2-3 semanas: adaptación→carga(+pico) |
| `_reglasPorObjetivo()` | Reglas de programación | Devuelve texto con reps, descanso, tipo de ejercicios según objetivo (fuerza/hipertrofia/resistencia/perder_peso/movilidad/fitness_general) |
| `_formatearHistorial()` | Contexto de historial | Formatea `HistorialSesionDto` a texto para el prompt. Incluye alerta si `requiereDescarga` |
| `_formatearEstadoDiario()` | Traducción fatiga→reglas | Convierte `EstadoDiarioDb` a instrucciones para IA: fatiga>50→reducir 30%, zonas dolor→sustituir, energía≤2→movilidad, sueño≤2→evitar peso muerto/squat máximo |
| `_formatearProgresion()` | Datos de sobrecarga | Lista los últimos 5 ejercicios con peso/reps/RPE para que la IA aplique progresión lógica |
| `_callGemini()` | Llamada HTTP a Gemini | POST a `generativelanguage.googleapis.com` con `X-goog-api-key`. Extrae texto de `candidates[0].content.parts[0].text` |
| `_extraerJson()` | Parsing robusto de JSON | 3 estrategias: (1) regex para bloques ```json...```, (2) búsqueda de primer `{` o `[`, (3) substring hasta último cierre. Previene fallos por Markdown espurio |
| `_parseError()` | Clasificación de errores | DioException 400/401/403→error de API key, otros→error de conexión. FormatException→JSON malformado. Genérico→mensaje truncado a 100 chars |

## 9. Sistema de Check-in Diario

### 9.1 Modelo `EstadoDiarioDb`

```dart
class EstadoDiarioDb {
  final int calidadSueno;    // 1 (muy mal) a 5 (excelente)
  final int nivelEstres;     // 1 (muy bajo) a 5 (muy alto)
  final int nivelEnergia;    // 1 (agotado) a 5 (pleno)
  final int dolorMuscular;   // 1 (ninguno) a 5 (intenso)
  final List<String> zonasDolor;  // ['piernas', 'espalda', 'hombros', ...]
  final bool listoParaEntrenar;   // sueño > 1 OR energía > 2

  // Puntuación compuesta 0-100 (mayor = peor estado)
  int get puntuacionFatiga {
    final suenoInv = (6 - calidadSueno) * 5;    // 0-25
    final estres = (nivelEstres - 1) * 5;       // 0-20
    final energiaInv = (6 - nivelEnergia) * 4;  // 0-20
    final dolor = (dolorMuscular - 1) * 7;      // 0-28
    return (suenoInv + estres + energiaInv + dolor).clamp(0, 100);
  }

  bool get requiereAdaptacion => puntuacionFatiga > 50;
}
```

### 9.2 Fórmula de Fatiga — Justificación

La fórmula pondera los 4 indicadores según su impacto en el rendimiento deportivo:

| Indicador | Peso | Rango | Justificación |
|-----------|------|-------|---------------|
| Sueño (invertido) | ×5 | 0-25 | El sueño es el factor #1 de recuperación (literatura: impacto directo en testosterona, cortisol, síntesis proteica) |
| Estrés | ×5 | 0-20 | Estrés elevado = cortisol alto = catabolismo. Afecta recuperación y motivación |
| Energía (invertido) | ×4 | 0-20 | Baja energía = sistema nervioso central fatigado. Riesgo de lesión por falta de concentración |
| Dolor muscular | ×7 | 0-28 | Mayor peso porque el dolor es la señal más directa de que el músculo no se ha recuperado. DOMS severo contraindica entrenamiento intenso |

**Umbral de adaptación (>50):** Seleccionado para que se active cuando al menos 2 indicadores están en valores malos (ej: sueño=2 + estrés=4 = 50 puntos) o 1 indicador está muy mal (dolor=5 = 28 puntos → necesita otros 22 de los demás).

### 9.3 Overlay `_CheckInOverlay` (durante el primer descanso)

Implementado como `_CheckInOverlay` dentro de `sesion_en_vivo_screen.dart`. Ya no es un diálogo bloqueante antes de empezar: el cronómetro arranca inmediatamente y el check-in se muestra como overlay no bloqueante durante el primer descanso:

```dart
// Flujo actual:
// 1. Usuario pulsa "Iniciar" → cronómetro visible de inmediato
// 2. Usuario completa 1ª serie → inicia descanso 90s
// 3. _lanzarCheckInOverlay() consulta estadoDiarioHoyProvider:
//    - Si ya existe check-in hoy → no muestra nada (silencio)
//    - Si no existe → muestra overlay con 4 sliders
// 4. Overlay: 4 sliders (1-5) + zonas de dolor si dolor>=3
// 5. Botones: "Guardar" (persiste) / "Omitir" (solo continúa)
```

**Importante (v3.4):** El overlay ya no muestra el mensaje "Ya has hecho check-in hoy". En su lugar, la verificación se hace antes de mostrar el overlay: si `estadoDiarioHoyProvider` devuelve un registro, el overlay simplemente no se muestra. Esto evita interrumpir al usuario innecesariamente.

**Indicador visual de fatiga:** Si `estadoDiarioHoyProvider` devuelve `requiereAdaptacion == true`, se muestra un banner naranja en `RutinaDetalleScreen` antes de iniciar la sesión: "Hoy tu cuerpo necesita un entrenamiento más ligero."

### 9.4 Integración con IA — `_formatearEstadoDiario()`

La IA recibe el estado diario traducido a reglas concretas:

```
ESTADO FISICO DE HOY (Check-in diario):
- Calidad del sueño: 2/5
- Nivel de estrés: 4/5
- Nivel de energía: 2/5
- Dolor muscular: 3/5
- Zonas con dolor: piernas, espalda
- Puntuación de fatiga: 67/100 (mayor = peor)
- ALERTA: El usuario necesita adaptación hoy. Reducir volumen un 30%.
  Evitar ejercicios en zonas con dolor.
- SUSTITUIR ejercicios que trabajen: piernas, espalda.
- Energía muy baja: priorizar movilidad y ejercicios de baja intensidad.
- Sueño deficiente: evitar ejercicios de alta demanda neuromuscular
  (peso muerto, squat máximo).
```

## 10. Sistema de Periodización Inteligente

### 10.1 Algoritmo `_calcularTipoSemana()`

```dart
String _calcularTipoSemana(int semanaNum, int totalSemanas) {
  if (totalSemanas <= 1) return 'carga';           // Rutina de 1 semana
  if (semanaNum == 1) return 'adaptacion';          // Primera semana siempre adaptación
  if (semanaNum == totalSemanas && totalSemanas >= 4) return 'descarga';  // Última de 4+ → descarga
  if (semanaNum == totalSemanas && totalSemanas >= 3) return 'pico';      // Última de 3 → pico
  return 'carga';                                   // Semanas intermedias → carga
}
```

**Tabla de decisión:**

| Total Semanas | Sem 1 | Sem 2 | Sem 3 | Sem 4 | Sem 5+ |
|---------------|-------|-------|-------|-------|--------|
| 1 | carga | — | — | — | — |
| 2 | adaptacion | carga | — | — | — |
| 3 | adaptacion | carga | pico | — | — |
| 4 | adaptacion | carga | carga | descarga | — |
| 5 | adaptacion | carga | carga | carga | descarga |

### 10.2 Detección de Necesidad de Descarga (`estadoPeriodizacionProvider`)

Algoritmo que se ejecuta periódicamente para detectar signos de sobre-entrenamiento:

```
1. Consultar sesiones_registradas de las últimas 3 semanas
2. Calcular RPE promedio de todas las sesiones
3. Agrupar volumen por semana (suma de duración en minutos)
4. Detectar si el volumen es decreciente (3 semanas consecutivas bajando)
5. Consultar check-in diario de hoy (estado_diario_usuario)
6. Calcular puntuación de fatiga diaria

necesitaDescarga = true SI:
  (RPE > 8.0 AND semanas ≥ 3 AND volumen decreciente)
  OR
  (puntuacionFatigaDiaria > 50)
```

**DTO `PeriodizacionEstado`:**

```dart
class PeriodizacionEstado {
  final bool necesitaDescarga;         // ¿Recomendar descarga?
  final double rpePromedioReciente;    // RPE promedio últimas 3 semanas
  final bool volumenDecreciente;       // ¿Volumen bajando 3 semanas?
  final int semanasConsecutivas;       // Semanas seguidas entrenando
  final int puntuacionFatigaDiaria;    // Puntuación del check-in de hoy
}
```

### 10.3 Badges Visuales en UI

En `RutinaDetalleScreen`, el selector horizontal de semanas muestra badges coloreados:

| Tipo | Color | Texto | Significado |
|------|-------|-------|-------------|
| `adaptacion` | Azul | "Adapt" | 70% volumen, énfasis en técnica |
| `carga` | Verde | "Carga" | 85-90% volumen, progresión |
| `pico` | Naranja | "Pico" | Máxima intensidad, volumen completo |
| `descarga` | Teal | "Desc" | 60% volumen, recuperación activa |

## 11. Barra de Progreso de Rutina

### 11.1 Cálculo

En `RutinaDetalleScreen`:

```dart
// Días completados / días totales
final diasCompletados = dias.where((d) => d.estado == 'completado').length;
final diasTotales = dias.length;
final progreso = diasTotales > 0 ? diasCompletados / diasTotales : 0.0;

// Tiempo acumulado: suma de duración de sesiones para los días de esta rutina
// vía tiempoDiaProvider(diaId)
```

### 11.2 Invalidaciones y Cascada

- Al marcar un día como completado → `diasDeSemanaProvider` + `semanasDeRutinaProvider(rutinaId)` se invalidan. El trigger `trg_dias_rutina_estado` en BD actualiza la semana automáticamente.
- Al añadir/quitar/editar ejercicios de un día → `ejerciciosDeDiaProvider(diaId)` + `nombresEjerciciosProvider(diaId)` se invalidan. Si el día estaba completado, se revierte a `pendiente` y el trigger de BD revierte la semana.
- Si un día tenía ejercicios y se vacía → el estado vuelve a `pendiente`
- Si un día no tiene ejercicios → botón "Iniciar" bloqueado con SnackBar

## 12. Proveedores Riverpod — Catálogo Completo

### 12.1 Módulo de Bienestar (IA + Periodización)

| Provider | Tipo | Propósito | Fuente de datos | Invalidación |
|----------|------|-----------|----------------|-------------|
| `perfilBienestarProvider` | `FutureProvider<PerfilBienestarDb?>` | Perfil físico del usuario | `BienestarRepository.obtenerPerfilBienestar()` → `perfil_bienestar_usuario` | Manual al editar perfil |
| `estadoDiarioHoyProvider` | `FutureProvider<EstadoDiarioDb?>` | Check-in del día actual | `estado_diario_usuario` WHERE fecha = today | `guardarEstadoDiario()` |
| `historialSesionUsuarioProvider` | `FutureProvider<HistorialSesionDto?>` | Historial agregado (4 semanas) | `sesiones_registradas` + `series_sesion` (JOIN) | Al completar sesión |
| `estadoPeriodizacionProvider` | `FutureProvider<PeriodizacionEstado>` | Detección de necesidad de descarga | `sesiones_registradas` (3 semanas) + `estado_diario_usuario` | Al completar sesión |
| `semanasDeRutinaProvider` | `FutureProvider.family<List<SemanaRutinaDb>, String>` | Semanas de una rutina | `semanas_rutina` WHERE rutina_id | Al crear/modificar semanas |
| `diasDeSemanaProvider` | `FutureProvider.family<List<DiaRutinaDb>, String>` | Días de una semana | `dias_rutina` WHERE semana_id | Al añadir día o cambiar estado |
| `ejerciciosDeDiaProvider` | `FutureProvider.family<List<SeleccionEjercicioDb>, String>` | Ejercicios de un día | `seleccion_de_ejercicios` WHERE dia_id | Al añadir/quitar/editar ejercicios |
| `nombresEjerciciosProvider` | `FutureProvider.family<Map<String, String>, String>` | Nombres de ejercicios de un día (JOIN) | `seleccion_de_ejercicios` JOIN `ejercicios` WHERE dia_id | Al añadir/quitar/editar ejercicios |
| `tiempoDiaProvider` | `FutureProvider.family<int, String>` | Duración de última sesión del día | `sesiones_registradas` WHERE dia_id (última) | Al finalizar sesión |
| `rutinasComunidadProvider` | `FutureProvider<List<RutinaComunidadDto>>` | Rutinas públicas de la comunidad | `rutinas` WHERE visibilidad='public' + JOIN `usuarios` | Manual |
| `rutinasUsuarioProvider` | `FutureProvider<List<RutinaDb>>` | Rutinas del usuario | `rutinas` WHERE usuario_id | Al crear/eliminar/clonar rutina |

### 12.2 Funciones de Mutación (en `rutina_provider.dart`)

| Función | Operación | Tablas afectadas |
|---------|-----------|-----------------|
| `crearRutinaCompleta()` | INSERT | `rutinas` + `semanas_rutina` + `dias_rutina` + `seleccion_de_ejercicios` |
| `eliminarRutina()` | DELETE (CASCADE) | `rutinas` → cascada a semanas, días, ejercicios |
| `clonarRutina()` | INSERT (copia) | `rutinas` + `seleccion_de_ejercicios` (como privada) |
| `iniciarSesion()` | INSERT + UPDATE | `sesiones_registradas` + `dias_rutina.estado` |
| `finalizarSesion()` | UPDATE | `sesiones_registradas` (duración, RPE, calorías) + `dias_rutina.estado` (cascada a semana vía trigger) |
| `registrarSerie()` | INSERT | `series_sesion` |
| `guardarEstadoDiario()` | UPSERT | `estado_diario_usuario` ON CONFLICT (usuario_id, fecha) |
| `agregarEjercicioADia()` | INSERT | `seleccion_de_ejercicios` |
| `quitarEjercicioDeDia()` | DELETE | `seleccion_de_ejercicios` |
| `actualizarEjercicioDia()` | UPDATE | `seleccion_de_ejercicios` |
| `agregarDiaASemana()` | INSERT | `dias_rutina` |
| `actualizarEstadoSemana()` | UPDATE | `semanas_rutina.estado` |
| `actualizarEstadoDia()` | UPDATE | `dias_rutina.estado` |

### 12.3 Módulo de Ejercicios (Catálogo)

| Provider | Tipo | Propósito | Fuente |
|----------|------|-----------|--------|
| `ejerciciosProvider` | `StreamProvider<List<EjercicioDb>>` | Catálogo en tiempo real | `supabase.from('ejercicios').stream()` (Realtime) |
| `catalogosProvider` | `FutureProvider<CatalogosEjercicios>` | Listas de catálogo | `partes_cuerpo`, `musculos`, `equipamientos` |
| `ejerciciosFiltradosProvider` | `Family` | Búsqueda con filtros | `v_ejercicios_completos` con query params |
| `ejercicioDetalleProvider` | `FutureProvider.family<DetalleEjercicio?, String>` | Detalle de un ejercicio | `v_ejercicios_completos` WHERE id |

## 13. Estrategia Técnica por Fases

| Sprint | Alcance | Estado |
|--------|---------|--------|
| Sprint 1 | Base Flutter + Supabase Auth + Perfil + Clean Architecture | ✅ |
| Sprint 2 | Módulo académico (asignaturas, planes, bloques, apuntes) + RLS visibilidad | ✅ |
| Sprint 3 | Evaluaciones, calificaciones, retos, perfil bienestar, catálogo ejercicios, rutinas, sesiones | ✅ |
| Sprint 4 | Multimedia R2, ingesta completa ExerciseDB, feed social, notificaciones, hardening | ✅ |
| **Sprint 5** | **IA (Gemini), periodización, check-in diario, sobrecarga progresiva, perfil editable** | ✅ |
| Sprint 6 | Retos complejos con dependencias, analítica avanzada, sincronización offline | 🔜 |

## 14. Riesgos Técnicos y Mitigaciones

| Riesgo | Impacto | Mitigación |
|--------|---------|-----------|
| API de Gemini no disponible | Alto — bloquea recomendaciones IA | Creación manual de rutinas siempre funciona. Timeout de 15s con Dio. |
| JSON malformado de Gemini | Medio — error en parsing | `_extraerJson()` con 3 estrategias de extracción. Error genérico sin crashear. |
| Fatiga mal calibrada sin check-in | Bajo — IA menos precisa | Check-in opcional. Sin datos, IA usa solo historial de sesiones. |
| Periodización mal aplicada | Medio — rutina inadecuada | Algoritmo determinista (`_calcularTipoSemana`). El usuario puede crear rutinas sin IA. |
| Coste de API en producción | Bajo (MVP) | Gemini Flash capa gratuita: 15 RPM. Prompts minimalistas (solo IDs). |

---

**Documento compilado:** 14-05-2026
**Versión:** 3.1
**Clasificación:** PÚBLICO — Equipo jloen
