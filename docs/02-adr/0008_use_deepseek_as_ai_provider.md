# 0008. Usar DeepSeek como proveedor de IA en lugar de Google Gemini

* **Estado:** Aprobado (sustituye la parte de IA de la ADR 0004)
* **Fecha:** 2026-10-18
* **Autores:** Equipo SynaptixFit

## Contexto
El propietario decidió dejar de usar Google Gemini y usar DeepSeek. Toda la IA del backend pasa por un único puerto de dominio (`GenerativeAiPort`); los adaptadores de cada módulo (`external/ai/<modulo>/`) solo construyen prompts y leen la respuesta. DeepSeek ofrece una API compatible con OpenAI (`POST /chat/completions`) con modo JSON, pero **solo entiende texto**: no admite imágenes ni PDF.

## Decisión
- `DeepSeekAiAdapter` implementa `GenerativeAiPort` y sustituye a `GeminiAiAdapter`. Modelo por defecto `deepseek-chat`, configurable con `DEEPSEEK_MODEL`.
- Modo JSON con `response_format: json_object` y un mensaje de sistema que menciona «json» (requisito de DeepSeek).
- Adjuntos: `AttachmentTextExtractor` convierte los PDF a texto con Apache PDFBox y lo añade al prompt; los ficheros de texto se pasan tal cual. Imágenes y PDF escaneados sin texto → `AI_ATTACHMENT_UNSUPPORTED` (422).
- Errores del proveedor: 402 (sin saldo) y 429 (límite) → `AI_QUOTA_EXCEEDED`; respuesta cortada (`finish_reason: length`), ilegible o red → `AI_UNAVAILABLE`.
- Los adaptadores de los módulos pierden el prefijo `Gemini` (`RoutineGeneratorAiAdapter`, `PlanningAssistantAiAdapter`, `ScheduleScannerAiAdapter`, `GoalSuggestionAiAdapter`): describen la función, no el proveedor.

## Consecuencias
* **Positivas:** cambio aislado en un adaptador (la arquitectura hexagonal lo permitió sin tocar dominio ni casos de uso); coste menor; mismo contrato de errores para el cliente.
* **Negativas:** el escaneo de horarios y el asistente de estudio ya no leen **fotos** ni PDF escaneados (antes Gemini era multimodal). Con PDF que tengan texto funcionan igual. Si en el futuro se necesitan imágenes, bastaría un adaptador con OCR o un proveedor multimodal detrás del mismo puerto.
