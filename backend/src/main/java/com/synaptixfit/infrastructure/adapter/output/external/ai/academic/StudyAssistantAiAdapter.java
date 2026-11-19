package com.synaptixfit.infrastructure.adapter.output.external.ai.academic;

import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.exception.DomainException;
import com.synaptixfit.domain.model.academic.DocumentQuestion;
import com.synaptixfit.domain.model.academic.MindMap;
import com.synaptixfit.domain.model.academic.QuestionBatch;
import com.synaptixfit.domain.model.academic.QuestionDraft;
import com.synaptixfit.domain.model.academic.QuestionType;
import com.synaptixfit.domain.model.academic.TeachingGuide;
import com.synaptixfit.domain.port.output.academic.StudyAssistantPort;
import com.synaptixfit.domain.port.output.academic.StudyDocumentCodecPort;
import com.synaptixfit.domain.port.output.ai.AiAttachment;
import com.synaptixfit.domain.port.output.ai.GenerativeAiPort;
import com.synaptixfit.infrastructure.adapter.output.external.ai.AiLanguage;
import java.util.ArrayList;
import java.util.List;
import org.springframework.stereotype.Component;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

/**
 * Asistente de estudio sobre {@link GenerativeAiPort} (DeepSeek). Prompts en español (el contenido sale en el
 * idioma de la app, {@link AiLanguage}) heredados de
 * {@code estudio_ia_service.dart} y {@code guia_docente_ia_service.dart}; las fuentes de texto
 * van en el prompt y los PDF o imágenes como adjuntos multimodales.
 */
@Component
public class StudyAssistantAiAdapter implements StudyAssistantPort {

    static final double TEMPERATURE = 0.2;
    static final double GUIDE_TEMPERATURE = 0.1;

    private static final String SYSTEM = """
            Eres un motor de generación académica. Responde ÚNICAMENTE con el objeto JSON
            solicitado. NO incluyas saludos, introducciones, conclusiones ni texto de relleno
            conversacional antes o después del JSON. Solo devuelve el JSON puro.
            """;

    private static final String TITLE_RULE = "titulo_personalizado: descriptivo, directo y conciso. NUNCA incluyas "
            + "fechas, horas ni palabras redundantes como \\\"Resumen\\\", \\\"Mapa\\\" o \\\"Cuestionario\\\".";

    /*
     * Plan docente → datos de la app. Las guías españolas suelen traer dos sistemas de evaluación
     * (continua y global) que suman 100 % cada uno: se piden por separado con su modalidad para
     * que la calculadora de nota no los mezcle. Los temas se numeran para enlazar cada prueba con
     * lo que entra en ella.
     */
    private static final String GUIDE_PROMPT = """
            Eres un asistente que lee PLANES DOCENTES (guías docentes) de asignaturas universitarias.
            Devuelve SOLO un objeto JSON, sin markdown, con este esquema exacto. Usa null (o []) si un dato no aparece; nunca inventes datos.
            {
              "asignatura": {
                "nombre": "denominación en español",
                "codigo": "código de la asignatura",
                "creditos_ects": 6,
                "curso": 3,
                "semestre": 6,
                "caracter": "Obligatoria | Básica | Optativa | Trabajo Fin de Grado | Prácticas externas",
                "titulacion": "titulación principal (la primera si hay varias)",
                "centro": "facultad o escuela",
                "universidad": "nombre completo de la universidad (dedúcelo del centro o de la web si es evidente)",
                "curso_academico": "2025/2026",
                "departamento": "departamento",
                "descripcion": "resumen del contenido en 1-3 frases"
              },
              "profesores": [{"nombre": "", "email": "", "despacho": "", "papel": "Coordinador/a · Teoría", "tutorias": "Lun 10:00-12:00 · Mié 16:00-18:00"}],
              "temario": [{"titulo": "Tema 1: título breve", "tipo": "teoria | practica", "subtemas": ["apartado"], "horas": 27}],
              "evaluacion": [{"nombre": "Prueba 1 (temas 1-3)", "porcentaje": 30, "modalidad": "continua | global | null", "tipo": "examen | entrega | presentacion | otro", "duracion_minutos": 120, "temas": [1, 2, 3], "recuperable": true, "fecha": "AAAA-MM-DD"}],
              "bibliografia": ["referencia completa"]
            }
            Reglas:
            - "semestre" es el número que figura (p. ej. 6). "curso" (1-6) solo si la guía lo escribe; si no, null (nunca lo supongas: con «Semestre 1» o «Semestre 2» sin curso escrito, "curso": null).
            - "papel": qué hace cada profesor según la guía (coordinador/a, teoría, prácticas, laboratorio…), en pocas palabras y unido con « · »; null si no lo dice.
            - "tutorias": horario de tutorías en texto corto (días y horas, «con cita» si lo pide); null si no lo dice.
            - "temario": un elemento por TEMA, en orden. Si los temas se agrupan en partes o bloques, no añadas las partes como temas. Los apartados de cada tema van en "subtemas". Las prácticas de laboratorio son un tema de tipo "practica" solo si la guía las presenta como bloque propio.
            - "horas": horas totales de trabajo del alumno de ese tema si hay una tabla de actividades formativas; si no, null.
            - "evaluacion": cada prueba o trabajo puntuable por separado. Si un bloque (p. ej. «Examen 60 %%») se divide en pruebas con su propio peso, devuelve las pruebas y no el bloque.
            - Si hay evaluación continua y global, devuelve los criterios de ambas con su "modalidad"; los porcentajes de cada modalidad suman 100. Si solo hay un sistema, "modalidad": null.
            - "porcentaje": número sin el símbolo %% sobre la nota final de su modalidad.
            - "temas": números de tema (1 = primer elemento de "temario") que cubre la prueba; [] si no se indica.
            - "recuperable": false si la guía dice que no es recuperable, true si dice que sí, null si no lo dice.
            - "fecha": solo si la guía da una fecha concreta; si dice «según la agenda» o similar, null.
            - No incluyas competencias, resultados de aprendizaje ni metodologías.
            - Escribe en español.""".replace("%%", "%");

    private final GenerativeAiPort ai;
    private final JsonMapper mapper;
    private final StudyDocumentCodecPort codec;

    public StudyAssistantAiAdapter(GenerativeAiPort ai, JsonMapper mapper, StudyDocumentCodecPort codec) {
        this.ai = ai;
        this.mapper = mapper;
        this.codec = codec;
    }

    @Override
    public Summary summarize(List<Source> sources) {
        String prompt = SYSTEM + """

                TAREA: Genera un resumen académico sintetizando todas las fuentes del contexto.

                ESQUEMA JSON EXACTO (responde SOLO este JSON):
                {
                  "titulo_personalizado": "%s",
                  "contenido_markdown": "# Desarrollo del tema\\n\\n..."
                }

                REGLAS DEL RESUMEN:
                - Sintetiza y conecta los conceptos de TODAS las fuentes combinadas.
                - Estructura el contenido en secciones con encabezados ##.
                - Usa listas con viñetas para las ideas clave.
                - Usa **negrita** en conceptos importantes.
                - Termina con la sección "## Puntos clave" (3-5 viñetas).
                - No inventes información que no esté en las fuentes.
                - %s
                """.formatted(TITLE_RULE, AiLanguage.rule());
        JsonNode json = call(prompt, sources);
        String markdown = json.path("contenido_markdown").asString("");
        if (markdown.isBlank()) {
            throw new AiUnavailableException("AI summary without content");
        }
        return new Summary(json.path("titulo_personalizado").asString(""), markdown);
    }

    @Override
    public GeneratedMindMap mindMap(List<Source> sources) {
        String prompt = SYSTEM + """

                TAREA: Genera un mapa mental jerárquico sintetizando todas las fuentes.

                ESQUEMA JSON EXACTO (responde SOLO este JSON):
                {
                  "titulo_personalizado": "%s",
                  "contenido_markdown": "- Nodo Central\\n  - Rama 1\\n    - Subidea 1.1\\n  - Rama 2\\n    - Subidea 2.1"
                }

                REGLAS DEL MAPA:
                - El nodo central resume el tema transversal de todas las fuentes.
                - Entre 4 y 8 ramas principales a partir del nodo central.
                - Cada rama con 2 a 5 subnodos. Profundidad máxima: 3 niveles.
                - Etiquetas MUY concisas (máximo 6 palabras por nodo).
                - Cada línea del markdown es un nodo indentado con dos espacios por nivel y "- ".
                - Conecta conceptos de diferentes fuentes cuando sea relevante.
                - Solo conceptos de las fuentes. %s
                """.formatted(TITLE_RULE, AiLanguage.rule());
        JsonNode json = call(prompt, sources);
        String title = json.path("titulo_personalizado").asString("");
        MindMap map = MindMap.fromIndentedMarkdown(title, json.path("contenido_markdown").asString(""));
        if (map.isEmpty()) {
            throw new AiUnavailableException("AI mind map without branches");
        }
        return new GeneratedMindMap(title, map);
    }

    @Override
    public Flashcards flashcards(List<Source> sources) {
        String prompt = SYSTEM + """

                TAREA: Genera tarjetas de estudio (pregunta/respuesta) a partir de todas las fuentes.

                ESQUEMA JSON EXACTO (responde SOLO este JSON):
                {
                  "titulo_personalizado": "%s",
                  "tarjetas": [
                    {"pregunta": "¿Qué establece...?", "respuesta": "Establece que..."}
                  ]
                }

                REGLAS:
                - Exactamente 10 tarjetas.
                - Las preguntas deben cubrir TODAS las fuentes combinadas, no solo una.
                - Preguntas variadas: definiciones, relaciones, causas, consecuencias, comparaciones.
                - Respuestas claras y concisas (1-3 frases).
                - %s Solo conceptos de las fuentes.
                - Ordena de más sencillo a más difícil.
                """.formatted(TITLE_RULE, AiLanguage.rule());
        JsonNode json = call(prompt, sources);
        List<Flashcard> cards = new ArrayList<>();
        for (JsonNode card : json.path("tarjetas")) {
            String q = card.path("pregunta").asString("");
            String a = card.path("respuesta").asString("");
            if (!q.isBlank() && !a.isBlank()) {
                cards.add(new Flashcard(q.strip(), a.strip()));
            }
        }
        if (cards.isEmpty()) {
            throw new AiUnavailableException("AI returned no flashcards");
        }
        return new Flashcards(json.path("titulo_personalizado").asString(""), cards);
    }

    @Override
    public PracticeQuestions practiceQuestions(List<Source> sources) {
        String prompt = SYSTEM + """

                TAREA: Genera un test de práctica a partir de todas las fuentes.

                ESQUEMA JSON EXACTO (responde SOLO este JSON):
                {
                  "titulo_personalizado": "%s",
                  "preguntas": [
                    {
                      "tipo": "opcion_multiple",
                      "enunciado": "¿Qué establece...?",
                      "opciones": ["Opción 1", "Opción 2", "Opción 3", "Opción 4"],
                      "respuesta_correcta": "Opción 1",
                      "explicacion": "Porque..."
                    },
                    {
                      "tipo": "rellenar_hueco",
                      "enunciado": "La ____ es ...",
                      "respuesta_correcta": "palabra",
                      "explicacion": "Porque..."
                    }
                  ]
                }

                REGLAS:
                - Exactamente 10 preguntas: 5 de opción múltiple (4 opciones) y 5 de rellenar hueco.
                - En opción múltiple, "respuesta_correcta" es el texto EXACTO de una de las opciones.
                - Cubre TODAS las fuentes combinadas proporcionalmente.
                - Opciones verosímiles. Respuestas de hueco: máximo 3 palabras.
                - Enunciados claros. Explicaciones de 1-2 frases.
                - %s Solo conceptos de las fuentes.
                - Ordena de más sencilla a más difícil.
                """.formatted(TITLE_RULE, AiLanguage.rule());
        JsonNode json = call(prompt, sources);
        List<QuestionDraft> questions = new ArrayList<>();
        for (JsonNode q : json.path("preguntas")) {
            QuestionDraft draft = toDraft(q);
            // Este camino (asistente y «Crear material») llega a apps anteriores: sin «Varias correctas».
            if (draft != null && draft.type() != QuestionType.MULTIPLE_ANSWER) {
                questions.add(draft);
            }
        }
        if (questions.isEmpty()) {
            throw new AiUnavailableException("AI returned no valid questions");
        }
        return new PracticeQuestions(json.path("titulo_personalizado").asString(""), questions);
    }

    @Override
    public PracticeQuestions practiceQuestions(List<Source> sources, QuestionBatch batch, List<String> avoid) {
        StringBuilder kinds = new StringBuilder();
        if (batch.singleChoice() > 0) {
            kinds.append("- ").append(batch.singleChoice()).append(" de tipo \"opcion_multiple\": 4 opciones y UNA ")
                    .append("sola correcta; \"respuestas_correctas\" lleva el texto EXACTO de esa opción.\n");
        }
        if (batch.multipleAnswer() > 0) {
            kinds.append("- ").append(batch.multipleAnswer()).append(" de tipo \"varias_correctas\": 4 o 5 opciones ")
                    .append("y entre 2 y 3 correctas; \"respuestas_correctas\" lleva el texto EXACTO de cada opción ")
                    .append("correcta. El enunciado no dice cuántas son.\n");
        }
        if (batch.fillInBlank() > 0) {
            kinds.append("- ").append(batch.fillInBlank()).append(" de tipo \"rellenar_hueco\": una frase con un ")
                    .append("hueco ____ y la palabra que falta (1 a 3 palabras) en \"respuestas_correctas\".\n");
        }
        if (batch.flashcards() > 0) {
            kinds.append("- ").append(batch.flashcards()).append(" de tipo \"tarjeta\": pregunta directa ")
                    .append("(«¿Qué es…?», «¿Cómo se llama…?») con respuesta de 1 a 4 palabras.\n");
        }
        String prompt = SYSTEM + """

                TAREA: Crea preguntas de práctica a partir de todas las fuentes.

                ESQUEMA JSON EXACTO (responde SOLO este JSON):
                {
                  "titulo_personalizado": "%s",
                  "preguntas": [
                    {
                      "tipo": "opcion_multiple | varias_correctas | rellenar_hueco | tarjeta",
                      "enunciado": "¿Qué establece...?",
                      "opciones": ["Opción 1", "Opción 2", "Opción 3", "Opción 4"],
                      "respuestas_correctas": ["Opción 1"],
                      "explicacion": "Porque..."
                    }
                  ]
                }

                REGLAS:
                - Exactamente %d preguntas:
                %s- Sin opciones ("opciones": []) en rellenar_hueco y tarjeta.
                - Cubre todo el contenido de las fuentes, no solo el principio.
                - Opciones verosímiles. Enunciados claros. Explicaciones de 1-2 frases.
                - %s Solo conceptos de las fuentes.
                - Ordena de más sencilla a más difícil.
                """.formatted(TITLE_RULE, batch.total(), kinds, AiLanguage.rule()) + avoidRule(avoid);
        JsonNode json = call(prompt, sources);
        List<QuestionDraft> questions = new ArrayList<>();
        for (JsonNode q : json.path("preguntas")) {
            QuestionDraft draft = toDraft(q);
            if (draft != null) {
                questions.add(draft);
            }
        }
        if (questions.isEmpty()) {
            throw new AiUnavailableException("AI returned no valid questions");
        }
        return new PracticeQuestions(json.path("titulo_personalizado").asString(""), questions);
    }

    /*
     * Preguntas que ya trae el documento (ADR 0058). Se pide una tanda por posición («de la 11 a la 20») y el
     * total, para no superar el tope de tokens de salida con un examen largo. El texto se copia tal cual: no
     * se traduce ni se reescribe, porque la persona tiene que reconocer sus preguntas.
     */
    @Override
    public DocumentQuestionPage documentQuestions(Source source, int from, int limit) {
        String prompt = SYSTEM + """

                TAREA: Busca en el documento las preguntas que YA están escritas en él (ejercicios, autoevaluación,
                preguntas de examen o test). NO inventes preguntas ni conviertas el temario en preguntas: si el
                documento no trae preguntas, "total_preguntas": 0 y "preguntas": [].

                Numera las preguntas en el orden en que aparecen (la primera es la 1). Devuelve en
                "total_preguntas" cuántas hay en todo el documento y en "preguntas" SOLO de la %d a la %d.

                ESQUEMA JSON EXACTO (responde SOLO este JSON):
                {
                  "total_preguntas": 12,
                  "preguntas": [
                    {
                      "numero": 1,
                      "tipo": "opcion_multiple | varias_correctas | rellenar_hueco | respuesta_corta | respuesta_larga",
                      "enunciado": "texto tal cual",
                      "opciones": ["texto de la opción tal cual"],
                      "respuestas_correctas": ["texto exacto de la opción correcta"],
                      "respuesta_en_documento": true,
                      "explicacion": null
                    }
                  ]
                }

                REGLAS:
                - Copia enunciados y opciones tal cual, sin traducirlos y sin la letra de delante («a)», «B.»).
                - "opcion_multiple": opciones y una correcta. "varias_correctas": opciones y se pide marcar varias.
                  "rellenar_hueco": una frase con un hueco. "respuesta_corta": sin opciones, se responde con 1 a 4
                  palabras. "respuesta_larga": pide explicar, desarrollar, razonar, demostrar o resolver con pasos.
                - Si el documento da la respuesta (solucionario, clave, «Respuesta:»), ponla en
                  "respuestas_correctas" (el texto exacto de la opción) y "respuesta_en_documento": true.
                - Si no la da y no es de respuesta larga, propón la correcta según el propio documento y pon
                  "respuesta_en_documento": false. Si no puedes deducirla con seguridad, deja [].
                - En "respuesta_larga", "respuestas_correctas": [].
                """.formatted(from + 1, from + limit);
        JsonNode json = callOne(prompt, source);
        List<DocumentQuestion> questions = new ArrayList<>();
        for (JsonNode q : json.path("preguntas")) {
            if (questions.size() >= limit) {
                break;
            }
            String statement = q.path("enunciado").asString("");
            if (statement.isBlank()) {
                continue;
            }
            QuestionType type = switch (q.path("tipo").asString("")) {
                case "varias_correctas" -> QuestionType.MULTIPLE_ANSWER;
                case "rellenar_hueco", "respuesta_corta" -> QuestionType.FILL_IN_BLANK;
                case "respuesta_larga" -> null;
                default -> QuestionType.MULTIPLE_CHOICE;
            };
            List<String> options = texts(q.path("opciones"));
            List<String> answers = letterAnswers(texts(q.path("respuestas_correctas")), options);
            String explanation = q.path("explicacion").asString("");
            questions.add(DocumentQuestion.of(type, statement, type == null ? List.of() : options, answers,
                    q.path("respuesta_en_documento").asBoolean(false), explanation));
        }
        int total = Math.max(json.path("total_preguntas").asInt(0), from + questions.size());
        return new DocumentQuestionPage(total, questions);
    }

    @Override
    public TeachingGuide extractTeachingGuide(Source document) {
        String raw = ai.generateJson(GUIDE_PROMPT, attachments(List.of(document)), GUIDE_TEMPERATURE);
        JsonNode json = parse(raw);
        return codec.decodeTeachingGuide(mapper.writeValueAsString(json));
    }

    // ------------------------------------------------------------------ apoyo

    private JsonNode call(String prompt, List<Source> sources) {
        StringBuilder full = new StringBuilder(prompt).append("\n[CONTEXTO DE FUENTES COMBINADAS]\n");
        for (int i = 0; i < sources.size(); i++) {
            full.append("Fuente ").append(i + 1).append(": \"").append(sources.get(i).title()).append("\"\n");
        }
        full.append("\nSintetiza TODAS las fuentes anteriores. Conecta los conceptos de forma transversal. ")
                .append("No trates cada fuente por separado; el objetivo es una visión integrada del material.\n");
        for (Source s : sources) {
            if (!s.isBinary()) {
                full.append("\n--- FUENTE: ").append(s.title()).append(" ---\n").append(s.text() == null ? "" : s.text())
                        .append('\n');
            }
        }
        return parse(ai.generateJson(full.toString(), attachments(sources), TEMPERATURE));
    }

    private static List<AiAttachment> attachments(List<Source> sources) {
        return sources.stream().filter(Source::isBinary).map(s -> new AiAttachment(s.mimeType(), s.data())).toList();
    }

    /** Extrae el objeto JSON aunque el modelo lo envuelva en texto o en bloques de código. */
    JsonNode parse(String raw) {
        String s = raw == null ? "" : raw.strip();
        int start = s.indexOf('{');
        int end = s.lastIndexOf('}');
        if (start < 0 || end <= start) {
            throw new AiUnavailableException("AI did not return a JSON object");
        }
        try {
            JsonNode node = mapper.readTree(s.substring(start, end + 1));
            if (node == null || !node.isObject()) {
                throw new AiUnavailableException("AI did not return a JSON object");
            }
            return node;
        } catch (JacksonException e) {
            throw new AiUnavailableException("AI returned invalid JSON");
        }
    }

    /** Un solo documento, tal cual (sin la instrucción de sintetizar varias fuentes). */
    private JsonNode callOne(String prompt, Source source) {
        StringBuilder full = new StringBuilder(prompt).append("\n[DOCUMENTO: \"").append(source.title()).append("\"]\n");
        if (!source.isBinary()) {
            full.append(source.text() == null ? "" : source.text()).append('\n');
        }
        return parse(ai.generateJson(full.toString(), attachments(List.of(source)), TEMPERATURE));
    }

    /** Enunciados que no se deben repetir; se recortan para no inflar el prompt. */
    static String avoidRule(List<String> avoid) {
        if (avoid == null || avoid.isEmpty()) {
            return "";
        }
        StringBuilder sb = new StringBuilder("\nNO repitas ni reformules estas preguntas, que ya existen:\n");
        avoid.stream().skip(Math.max(0, avoid.size() - MAX_AVOID)).forEach(a -> sb.append("- ")
                .append(a.length() > 200 ? a.substring(0, 200) : a).append('\n'));
        return sb.toString();
    }

    /** Máximo de enunciados a evitar en el prompt (los últimos): bastan para no repetir y caben de sobra. */
    static final int MAX_AVOID = 80;

    private static List<String> texts(JsonNode array) {
        List<String> out = new ArrayList<>();
        for (JsonNode n : array) {
            String t = n.asString("");
            if (!t.isBlank()) {
                out.add(t.strip());
            }
        }
        return out;
    }

    /** Algunos modelos responden con la letra de la opción («B») en lugar de su texto. */
    private static List<String> letterAnswers(List<String> answers, List<String> options) {
        return answers.stream().map(a -> {
            if (a.length() == 1 && !options.contains(a)) {
                int index = Character.toUpperCase(a.charAt(0)) - 'A';
                if (index >= 0 && index < options.size()) {
                    return options.get(index);
                }
            }
            return a;
        }).toList();
    }

    /**
     * Convierte una pregunta del modelo; las inválidas se descartan. Acepta «respuesta_correcta» (un texto,
     * prompt antiguo) o «respuestas_correctas» (lista); «tarjeta» se guarda como respuesta corta.
     */
    private static QuestionDraft toDraft(JsonNode q) {
        QuestionType type = switch (q.path("tipo").asString("")) {
            case "rellenar_hueco", "tarjeta" -> QuestionType.FILL_IN_BLANK;
            case "varias_correctas" -> QuestionType.MULTIPLE_ANSWER;
            default -> QuestionType.MULTIPLE_CHOICE;
        };
        List<String> options = texts(q.path("opciones"));
        List<String> answers = new ArrayList<>(texts(q.path("respuestas_correctas")));
        String single = q.path("respuesta_correcta").asString("");
        if (answers.isEmpty() && !single.isBlank()) {
            answers.add(single.strip());
        }
        if (type != QuestionType.FILL_IN_BLANK) {
            answers = letterAnswers(answers, options);
        }
        String explanation = q.path("explicacion").asString("");
        try {
            return type == QuestionType.MULTIPLE_ANSWER
                    ? QuestionDraft.multipleAnswer(q.path("enunciado").asString(""), options, answers, explanation)
                    : new QuestionDraft(type, q.path("enunciado").asString(""), options,
                    answers.isEmpty() ? "" : answers.getFirst(), explanation);
        } catch (DomainException e) {
            return null;
        }
    }
}
