package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.academic;

import com.synaptixfit.domain.model.academic.MindMap;
import com.synaptixfit.domain.model.academic.MindMapNode;
import com.synaptixfit.domain.model.academic.TeachingGuide;
import com.synaptixfit.domain.port.output.academic.StudyDocumentCodecPort;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.stereotype.Component;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;
import tools.jackson.databind.node.ArrayNode;
import tools.jackson.databind.node.ObjectNode;

/**
 * Codificación JSON de los documentos estructurados de {@code documentos_ia}. Conserva el
 * formato del sistema antiguo (claves en español) para que los documentos ya guardados sigan
 * siendo legibles. La lectura es tolerante: un contenido corrupto da un documento vacío.
 */
@Component
public class StudyDocumentJsonCodecAdapter implements StudyDocumentCodecPort {

    private final JsonMapper mapper;

    public StudyDocumentJsonCodecAdapter(JsonMapper mapper) {
        this.mapper = mapper;
    }

    // ------------------------------------------------------------------ mapa mental

    @Override
    public String encodeMindMap(MindMap mindMap) {
        ObjectNode root = mapper.createObjectNode();
        root.put("central", mindMap.central());
        writeNodes(root.putArray("ramas"), mindMap.branches());
        return mapper.writeValueAsString(root);
    }

    private static void writeNodes(ArrayNode array, List<MindMapNode> nodes) {
        for (MindMapNode n : nodes) {
            ObjectNode o = array.addObject();
            o.put("titulo", n.title());
            writeNodes(o.putArray("hijos"), n.children());
        }
    }

    @Override
    public MindMap decodeMindMap(String content) {
        JsonNode root = read(content);
        return new MindMap(root.path("central").asString(""), readNodes(root.path("ramas")));
    }

    private static List<MindMapNode> readNodes(JsonNode array) {
        List<MindMapNode> nodes = new ArrayList<>();
        if (array.isArray()) {
            for (JsonNode n : array) {
                nodes.add(new MindMapNode(n.path("titulo").asString(""), readNodes(n.path("hijos"))));
            }
        }
        return nodes;
    }

    // ------------------------------------------------------------------ guía docente

    @Override
    public String encodeTeachingGuide(TeachingGuide guide) {
        ObjectNode root = mapper.createObjectNode();
        TeachingGuide.SubjectInfo s = guide.subject();
        root.putObject("asignatura").put("nombre", s.name()).put("codigo", s.code())
                .put("creditos_ects", s.ectsCredits()).put("curso", s.courseYear()).put("semestre", s.semester())
                .put("caracter", s.character()).put("titulacion", s.degree()).put("centro", s.center())
                .put("universidad", s.university()).put("curso_academico", s.academicYear())
                .put("departamento", s.department()).put("descripcion", s.description());
        ArrayNode professors = root.putArray("profesores");
        for (TeachingGuide.Professor p : guide.professors()) {
            professors.addObject().put("nombre", nz(p.name())).put("email", nz(p.email()))
                    .put("despacho", nz(p.office()));
        }
        ArrayNode topics = root.putArray("temario");
        for (TeachingGuide.Topic t : guide.topics()) {
            ObjectNode o = topics.addObject().put("titulo", t.title())
                    .put("tipo", t.kind() == TeachingGuide.TopicKind.PRACTICE ? "practica" : "teoria")
                    .put("completado", t.completed()).put("horas", t.hours());
            ArrayNode subtopics = o.putArray("subtemas");
            t.subtopics().forEach(subtopics::add);
        }
        ArrayNode assessments = root.putArray("evaluacion");
        for (TeachingGuide.Assessment a : guide.assessments()) {
            ObjectNode o = assessments.addObject().put("nombre", a.name()).put("porcentaje", a.percentage())
                    .put("modalidad", modeCode(a.mode())).put("tipo", kindCode(a.kind()))
                    .put("duracion_minutos", a.durationMinutes()).put("recuperable", a.recoverable())
                    .put("fecha", a.dueDate() == null ? null : a.dueDate().toString());
            ArrayNode covered = o.putArray("temas");
            a.topicNumbers().forEach(covered::add);
            if (a.grade() != null) {
                o.put("nota_obtenida", a.grade());
            }
        }
        ArrayNode bibliography = root.putArray("bibliografia");
        guide.bibliography().forEach(bibliography::add);
        root.put("modalidad_elegida", modeCode(guide.selectedMode()));
        return mapper.writeValueAsString(root);
    }

    @Override
    public TeachingGuide decodeTeachingGuide(String content) {
        return parseTeachingGuide(read(content));
    }

    /**
     * Mismo esquema que devuelve el modelo al extraer una guía docente. Los campos nuevos
     * (asignatura, subtemas, modalidad…) son opcionales para seguir leyendo las guías antiguas.
     */
    private static TeachingGuide parseTeachingGuide(JsonNode root) {
        JsonNode s = root.path("asignatura");
        TeachingGuide.SubjectInfo subject = new TeachingGuide.SubjectInfo(text(s.path("nombre")),
                text(s.path("codigo")), number(s.path("creditos_ects")), integer(s.path("curso")),
                integer(s.path("semestre")), text(s.path("caracter")), text(s.path("titulacion")),
                text(s.path("centro")), text(s.path("universidad")), text(s.path("curso_academico")),
                text(s.path("departamento")), text(s.path("descripcion")));
        List<TeachingGuide.Professor> professors = new ArrayList<>();
        for (JsonNode p : root.path("profesores")) {
            professors.add(new TeachingGuide.Professor(p.path("nombre").asString(""), p.path("email").asString(""),
                    p.path("despacho").asString("")));
        }
        List<TeachingGuide.Topic> topics = new ArrayList<>();
        for (JsonNode t : root.path("temario")) {
            String title = t.isString() ? t.asString("") : t.path("titulo").asString("");
            if (title.isBlank()) {
                continue;
            }
            TeachingGuide.TopicKind kind = "practica".equalsIgnoreCase(t.path("tipo").asString(""))
                    ? TeachingGuide.TopicKind.PRACTICE : TeachingGuide.TopicKind.THEORY;
            topics.add(new TeachingGuide.Topic(title, kind, t.path("completado").asBoolean(false),
                    strings(t.path("subtemas")), number(t.path("horas"))));
        }
        List<TeachingGuide.Assessment> assessments = new ArrayList<>();
        for (JsonNode a : root.path("evaluacion")) {
            JsonNode grade = a.path("nota_obtenida");
            Double g = grade.isNumber() ? grade.asDouble() : null;
            if (g != null && (g < 0 || g > 10)) {
                g = null;
            }
            List<Integer> covered = new ArrayList<>();
            for (JsonNode n : a.path("temas")) {
                Integer value = integer(n);
                if (value != null) {
                    covered.add(value);
                }
            }
            JsonNode recoverable = a.path("recuperable");
            assessments.add(new TeachingGuide.Assessment(a.path("nombre").asString(""),
                    percentage(a.path("porcentaje")), g, mode(a.path("modalidad").asString("")),
                    kind(a.path("tipo").asString("")), integer(a.path("duracion_minutos")), covered,
                    recoverable.isBoolean() ? recoverable.asBoolean() : null, date(a.path("fecha").asString(""))));
        }
        List<String> bibliography = new ArrayList<>();
        for (JsonNode b : root.path("bibliografia")) {
            String ref = b.asString("");
            if (!ref.isBlank()) {
                bibliography.add(ref);
            }
        }
        return new TeachingGuide(subject, professors, topics, assessments, bibliography,
                mode(root.path("modalidad_elegida").asString("")));
    }

    private static String modeCode(TeachingGuide.EvaluationMode mode) {
        if (mode == null) {
            return null;
        }
        return mode == TeachingGuide.EvaluationMode.GLOBAL ? "global" : "continua";
    }

    private static TeachingGuide.EvaluationMode mode(String code) {
        String c = code.strip().toLowerCase(Locale.ROOT);
        if (c.contains("contin")) {
            return TeachingGuide.EvaluationMode.CONTINUOUS;
        }
        return c.contains("global") || c.contains("final") ? TeachingGuide.EvaluationMode.GLOBAL : null;
    }

    private static String kindCode(TeachingGuide.AssessmentKind kind) {
        return switch (kind) {
            case EXAM -> "examen";
            case ASSIGNMENT -> "entrega";
            case PRESENTATION -> "presentacion";
            case OTHER -> "otro";
        };
    }

    /** El modelo a veces responde con sinónimos («prueba», «trabajo»…): se normalizan aquí. */
    private static TeachingGuide.AssessmentKind kind(String code) {
        String c = code.strip().toLowerCase(Locale.ROOT);
        if (c.startsWith("exam") || c.startsWith("prueba")) {
            return TeachingGuide.AssessmentKind.EXAM;
        }
        if (c.startsWith("entrega") || c.startsWith("trabajo") || c.startsWith("practica")
                || c.startsWith("práctica")) {
            return TeachingGuide.AssessmentKind.ASSIGNMENT;
        }
        return c.startsWith("present") || c.startsWith("expos") ? TeachingGuide.AssessmentKind.PRESENTATION
                : TeachingGuide.AssessmentKind.OTHER;
    }

    private static String text(JsonNode node) {
        if (node == null || node.isNull() || node.isMissingNode()) {
            return null;
        }
        String v = node.asString("");
        return v.isBlank() || "null".equalsIgnoreCase(v.strip()) ? null : v;
    }

    private static Double number(JsonNode node) {
        if (node.isNumber()) {
            return node.asDouble();
        }
        String v = node.asString("").replace(',', '.').replaceAll("[^0-9.]", "");
        try {
            return v.isBlank() ? null : Double.parseDouble(v);
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private static Integer integer(JsonNode node) {
        Double d = number(node);
        return d == null ? null : (int) Math.round(d);
    }

    private static List<String> strings(JsonNode array) {
        List<String> values = new ArrayList<>();
        for (JsonNode n : array) {
            String v = n.isString() ? n.asString("") : n.path("titulo").asString("");
            if (!v.isBlank()) {
                values.add(v);
            }
        }
        return values;
    }

    private static LocalDate date(String value) {
        try {
            return value.isBlank() ? null : LocalDate.parse(value.strip());
        } catch (DateTimeParseException e) {
            return null;
        }
    }

    private static double percentage(JsonNode node) {
        if (node.isNumber()) {
            return node.asDouble();
        }
        try {
            return Double.parseDouble(node.asString("0").replace("%", "").replace(',', '.').strip());
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    // ------------------------------------------------------------------ práctica

    @Override
    public String encodePractice(PracticeMarker marker) {
        ObjectNode root = mapper.createObjectNode();
        root.put("material_id", marker.materialId() == null ? null : marker.materialId().toString());
        root.put("banco_id", marker.bankId() == null ? null : marker.bankId().toString());
        root.put("num_preguntas", marker.questionCount());
        return mapper.writeValueAsString(root);
    }

    @Override
    public PracticeMarker decodePractice(String content) {
        JsonNode root = read(content);
        return new PracticeMarker(uuid(root.path("material_id")), uuid(root.path("banco_id")),
                root.path("num_preguntas").asInt(0));
    }

    // ------------------------------------------------------------------ apoyo

    private JsonNode read(String content) {
        if (content == null || content.isBlank()) {
            return mapper.createObjectNode();
        }
        try {
            return mapper.readTree(content);
        } catch (JacksonException e) {
            return mapper.createObjectNode();
        }
    }

    private static UUID uuid(JsonNode node) {
        String v = node.asString("");
        try {
            return v.isBlank() ? null : UUID.fromString(v);
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    private static String nz(String v) {
        return v == null ? "" : v;
    }
}
