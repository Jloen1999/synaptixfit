package com.synaptixfit.infrastructure.adapter.output.external.ai.profile;

import com.synaptixfit.domain.exception.AiUnavailableException;
import com.synaptixfit.domain.model.profile.enrollment.EnrollmentReading;
import com.synaptixfit.domain.model.profile.enrollment.EnrollmentReading.EnrolledSubject;
import com.synaptixfit.domain.port.output.ai.GenerativeAiPort;
import com.synaptixfit.domain.port.output.profile.EnrollmentReaderPort;
import java.util.ArrayList;
import java.util.List;
import org.springframework.stereotype.Component;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

/**
 * Lee con IA (modo JSON) el texto de una carta de pago o resguardo de matrícula, que llega ya sin
 * datos personales. Solo pide centro, titulación, curso académico y asignaturas; el resto del
 * documento (importes, pagos) se ignora.
 */
@Component
public class EnrollmentReaderAiAdapter implements EnrollmentReaderPort {

    static final double TEMPERATURE = 0.0;
    static final int MAX_SUBJECTS = 40;

    private final GenerativeAiPort ai;
    private final JsonMapper json;

    public EnrollmentReaderAiAdapter(GenerativeAiPort ai, JsonMapper json) {
        this.ai = ai;
        this.json = json;
    }

    @Override
    public EnrollmentReading read(String redactedText) {
        return parse(ai.generateJson(prompt(redactedText), List.of(), TEMPERATURE));
    }

    static String prompt(String text) {
        return """
                Eres un lector de documentos universitarios. El texto es una carta de pago o un resguardo de
                matrícula de una universidad española (los datos personales ya se han ocultado). Extrae SOLO:
                la universidad, el centro, la titulación, el curso académico y las asignaturas matriculadas.
                Ignora importes, descuentos, plazos, pagos y cualquier dato personal.

                Responde SOLO con este JSON:
                {
                  "universidad": "nombre completo o null",
                  "centro": "nombre del centro o null",
                  "titulacion": "nombre de la titulación o null",
                  "curso_academico": "p. ej. 2024-25 o null",
                  "asignaturas": [
                    {"codigo": "código o null", "nombre": "nombre", "curso": 1, "creditos": 6.0,
                     "periodo": "1S, 2S, A u otro tal cual o null", "veces_matriculada": 1}
                  ]
                }
                Reglas:
                - Una entrada por asignatura de la tabla de matrícula, sin repetir.
                - Escribe los nombres con mayúsculas normales (no todo en mayúsculas) y con sus tildes.
                - Si un nombre está partido en dos líneas, únelo.
                - En las tablas de matrícula suele haber columnas Cv (convocatoria), T (tipo), C (curso),
                  Gr (grupo), Créditos, D (duración: 1S, 2S, A…) y Mt (veces matriculada). "curso" es la
                  columna C, no la convocatoria; "periodo" es la columna D.
                - Si no sabes un dato, pon null; no inventes.

                TEXTO:
                %s
                """.formatted(text);
    }

    EnrollmentReading parse(String response) {
        JsonNode root;
        try {
            root = json.readTree(response);
        } catch (JacksonException e) {
            throw new AiUnavailableException("Enrollment response is not valid JSON");
        }
        List<EnrolledSubject> subjects = new ArrayList<>();
        for (JsonNode s : root.path("asignaturas")) {
            String name = text(s, "nombre");
            if (name == null || subjects.size() >= MAX_SUBJECTS) {
                continue;
            }
            subjects.add(new EnrolledSubject(text(s, "codigo"), name, integer(s, "curso"), number(s, "creditos"),
                    text(s, "periodo"), integer(s, "veces_matriculada")));
        }
        return new EnrollmentReading(text(root, "universidad"), text(root, "centro"), text(root, "titulacion"),
                text(root, "curso_academico"), subjects);
    }

    private static String text(JsonNode node, String field) {
        JsonNode v = node.path(field);
        if (v.isNull() || v.isMissingNode()) {
            return null;
        }
        String s = v.asString("").strip();
        return s.isEmpty() || s.equalsIgnoreCase("null") ? null : s;
    }

    private static Integer integer(JsonNode node, String field) {
        JsonNode v = node.path(field);
        return v.isNumber() ? Integer.valueOf(v.asInt()) : null;
    }

    private static Double number(JsonNode node, String field) {
        JsonNode v = node.path(field);
        return v.isNumber() ? Double.valueOf(v.asDouble()) : null;
    }
}
