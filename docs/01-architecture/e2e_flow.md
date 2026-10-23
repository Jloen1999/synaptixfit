# Flujo de una acción de extremo a extremo

Ejemplo: el usuario marca un bloque de estudio del calendario como completado.

```mermaid
sequenceDiagram
    actor U as Usuario
    participant Pg as Page (Flutter)
    participant B as Bloc
    participant UC as *UseCase (cliente)
    participant R as Repository + guard()
    participant C as Controller (API)
    participant S as *Service (API)
    participant PA as PersistenceAdapter
    participant EV as Oyentes de eventos

    U->>Pg: pulsa «Completar»
    Pg->>B: BlockCompletionToggled
    B->>UC: call(blockId)
    UC->>R: completeBlock(blockId)
    R->>C: POST /api/v1/planner/blocks/{id}/complete (JWT)
    C->>S: CompleteBlockUseCase
    S->>PA: guarda bloque + XP
    S->>EV: StudyBlockCompletionChanged
    Note over EV: Indicadores recalcula la carga cognitiva<br/>Gamificación actualiza la tarea vinculada
    S-->>C: bloque actualizado
    C-->>R: 200 + JSON
    R-->>UC: Result.success(bloque)
    UC-->>B: Result
    B-->>Pg: nuevo estado
```

Si algo falla en la API, la respuesta es un Problem Details con `code` y el cliente muestra su propio texto (`error_pipeline.md`).
