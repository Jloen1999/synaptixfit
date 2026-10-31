package com.synaptixfit.infrastructure.adapter.input.rest.academic;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.domain.port.output.academic.StudyAssistantPort;
import com.synaptixfit.domain.port.output.storage.FileStoragePort;
import com.synaptixfit.domain.port.output.storage.PresignedUrl;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/**
 * Flujo académico completo sobre la app real y PostgreSQL embebido: asignatura → apunte →
 * material → repaso SM-2 (con carga física), archivos, documentos de IA (puerto sustituido),
 * cuestionario guardado → sesión de test con XP, y propiedad entre usuarios.
 */
@SpringBootTest
@AutoConfigureMockMvc
class AcademicFlowIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    @Autowired
    private JdbcClient jdbc;

    @MockitoBean
    private FileStoragePort storage;

    @MockitoBean
    private StudyAssistantPort assistant;

    @Test
    void subjectNoteMaterialReviewAndQuizFlow() throws Exception {
        String token = register("academic-it@example.com");
        String other = register("academic-other@example.com");

        // Asignatura
        String subject = body(perform(post("/api/v1/subjects"), token,
                "{\"name\":\"Bases de Datos\",\"credits\":6,\"perceivedDifficulty\":4,\"priority\":\"HIGH\"}")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.priority").value("HIGH")));
        String subjectId = JsonPath.read(subject, "$.id");

        // Apunte
        String note = body(perform(post("/api/v1/notes"), token,
                "{\"subjectId\":\"" + subjectId + "\",\"title\":\"Normalización\",\"content\":\"# 1FN\\nAtómicos\","
                        + "\"visibility\":\"PUBLIC\"}")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.visibility").value("PUBLIC")));
        String noteId = JsonPath.read(note, "$.id");

        perform(get("/api/v1/subjects/" + subjectId), token, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.noteCount").value(1));
        perform(get("/api/v1/notes?subjectId=" + subjectId), token, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalItems").value(1));
        perform(get("/api/v1/notes/shared"), other, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].id").value(noteId));

        // Propiedad: el otro usuario no ve ni edita la asignatura ni el apunte
        perform(get("/api/v1/subjects/" + subjectId), other, null)
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("SUBJECT_NOT_FOUND"));
        perform(patch("/api/v1/notes/" + noteId), other, "{\"title\":\"x\"}")
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("NOTE_NOT_FOUND"));

        // Material y repaso SM-2 con fatiga física (carga de hoy = máxima → +0.5)
        String material = body(perform(post("/api/v1/study-materials"), token,
                "{\"originType\":\"NOTE\",\"originId\":\"" + noteId + "\"}")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.masteryState").value("NOT_EVALUATED")));
        String materialId = JsonPath.read(material, "$.id");
        String userId = JsonPath.read(body(perform(get("/api/v1/me"), token, null)), "$.id");
        jdbc.sql("INSERT INTO registros_carga_fisica (usuario_id, fecha_registro, rpe_sesion, duracion_minutos) "
                        + "VALUES (:u, :d, 8, 60)")
                .param("u", UUID.fromString(userId))
                // «Hoy» en la zona de los indicadores: con UTC falla de 00:00 a 02:00 en Madrid.
                .param("d", LocalDate.now(ZoneId.of("Europe/Madrid")))
                .update();

        perform(get("/api/v1/study-materials/" + materialId + "/review-preview"), token, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.fatigueCoefficient").value(0.5))
                .andExpect(jsonPath("$.options.length()").value(6))
                .andExpect(jsonPath("$.options[2].adjustedQuality").value(2.5))
                .andExpect(jsonPath("$.options[2].resultingState").value("IN_PROGRESS"));

        perform(post("/api/v1/study-materials/" + materialId + "/reviews"), token, "{\"quality\":4}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.material.intervalDays").value(1))
                .andExpect(jsonPath("$.material.completedReviews").value(1))
                .andExpect(jsonPath("$.review.adjustedQuality").value(4.5))
                .andExpect(jsonPath("$.review.fatigueCoefficient").value(0.5));
        perform(get("/api/v1/study-materials/" + materialId + "/reviews"), token, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1));
        perform(get("/api/v1/subjects/" + subjectId + "/retention"), token, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.inProgress").value(1));
        perform(post("/api/v1/study-materials/" + materialId + "/reviews"), other, "{\"quality\":4}")
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("STUDY_MATERIAL_NOT_FOUND"));

        // Documento de IA: cargar o generar (puerto de IA sustituido)
        when(assistant.summarize(any())).thenReturn(new StudyAssistantPort.Summary("Normalización", "## Resumen"));
        perform(get("/api/v1/study/sources/NOTE/" + noteId + "/documents/SUMMARY"), token, null)
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("STUDY_DOCUMENT_NOT_FOUND"));
        perform(post("/api/v1/study/sources/NOTE/" + noteId + "/documents/SUMMARY"), token, null)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.markdown").value("## Resumen"));
        perform(get("/api/v1/study/sources/NOTE/" + noteId + "/documents"), token, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.summary").value(true))
                .andExpect(jsonPath("$.mindMap").value(false));

        // Archivos (almacenamiento sustituido)
        when(storage.presignUpload(anyString(), anyString(), anyLong(), any()))
                .thenReturn(new PresignedUrl("https://r2.test/put", "PUT", Map.of("Content-Type", "application/pdf"),
                        Instant.now().plusSeconds(900)));
        String ticket = body(perform(post("/api/v1/subjects/" + subjectId + "/files/upload-url"), token,
                "{\"fileName\":\"Guía docente.pdf\",\"mimeType\":\"application/pdf\",\"sizeBytes\":1024}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.method").value("PUT")));
        String objectKey = JsonPath.read(ticket, "$.objectKey");
        perform(post("/api/v1/subjects/" + subjectId + "/files/upload-url"), token,
                "{\"fileName\":\"virus.exe\",\"mimeType\":\"application/x-msdownload\",\"sizeBytes\":10}")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("FILE_TYPE_NOT_ALLOWED"));
        perform(post("/api/v1/subjects/" + subjectId + "/files"), token,
                "{\"objectKey\":\"" + objectKey + "\",\"fileName\":\"Guía docente.pdf\","
                        + "\"mimeType\":\"application/pdf\",\"sizeBytes\":1024}")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.aiReadable").value(true));
        perform(get("/api/v1/subjects/" + subjectId + "/files"), token, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1));

        // Cuestionario guardado → sesión de test → XP
        String quiz = body(perform(post("/api/v1/study/generations/quizzes"), token,
                "{\"subjectId\":\"" + subjectId + "\",\"title\":\"Test SQL\",\"questions\":["
                        + "{\"type\":\"MULTIPLE_CHOICE\",\"statement\":\"¿1FN?\",\"options\":[\"Atómicos\",\"Listas\"],"
                        + "\"correctAnswer\":\"Atómicos\"},"
                        + "{\"type\":\"FILL_IN_BLANK\",\"statement\":\"SELECT ___ FROM t\",\"correctAnswer\":\"*\"}]}")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.questionCount").value(2)));
        String quizMaterialId = JsonPath.read(quiz, "$.materialId");

        String bank = body(perform(get("/api/v1/study-materials/" + quizMaterialId + "/question-bank"), token, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.questions.length()").value(2)));
        List<String> questionIds = JsonPath.read(bank, "$.questions[*].id");
        List<String> answers = JsonPath.read(bank, "$.questions[*].correctAnswer");

        String session = body(perform(post("/api/v1/test-sessions"), token,
                "{\"materialIds\":[\"" + quizMaterialId + "\"]}")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.totalQuestions").value(2))
                .andExpect(jsonPath("$.questions[0].correctAnswer").doesNotExist()));
        String sessionId = JsonPath.read(session, "$.id");
        perform(get("/api/v1/test-sessions/active?materialId=" + quizMaterialId), token, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(sessionId));
        for (int i = 0; i < questionIds.size(); i++) {
            perform(post("/api/v1/test-sessions/" + sessionId + "/answers"), token,
                    "{\"questionId\":\"" + questionIds.get(i) + "\",\"answer\":\"" + answers.get(i) + "\"}")
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.result.correct").value(true));
        }
        perform(post("/api/v1/test-sessions/" + sessionId + "/complete"), token, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("COMPLETED"))
                .andExpect(jsonPath("$.score").value(2))
                // Un test de menos de 5 preguntas ya no da XP (PracticeRewards, contra el farmeo).
                .andExpect(jsonPath("$.xpGranted").value(0));
        perform(post("/api/v1/test-sessions/" + sessionId + "/complete"), token, null)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("QUIZ_SESSION_NOT_IN_PROGRESS"));
        // Solo los 5 del primer repaso SM-2 (tocaba: material sin repasar); el test de 2 preguntas no puntúa.
        perform(get("/api/v1/me"), token, null)
                .andExpect(jsonPath("$.levelXp").value(5));
        perform(get("/api/v1/test-sessions/" + sessionId), other, null)
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("QUIZ_SESSION_NOT_FOUND"));

        // Flashcards: XP una sola vez por material
        perform(post("/api/v1/study-materials/" + quizMaterialId + "/flashcard-reviews"), token,
                "{\"mastered\":2,\"doubtful\":0,\"failed\":0}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.quality").value(4))
                .andExpect(jsonPath("$.xpAwarded").value(6));
        perform(post("/api/v1/study-materials/" + quizMaterialId + "/flashcard-reviews"), token,
                "{\"mastered\":2,\"doubtful\":0,\"failed\":0}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.xpAwarded").value(0));

        // Semestre y borrado
        perform(put("/api/v1/subjects/" + subjectId + "/semester"), token, "{\"course\":2,\"semester\":1}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.course").value(2));
        perform(delete("/api/v1/notes/" + noteId), token, null).andExpect(status().isNoContent());
        perform(get("/api/v1/study-materials/" + materialId), token, null)
                .andExpect(status().isNotFound());
        perform(delete("/api/v1/subjects/" + subjectId), token, null).andExpect(status().isNoContent());
        perform(get("/api/v1/subjects"), token, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
    }

    @Test
    void catalogSelectionCreatesAndReactivatesSubjects() throws Exception {
        String token = register("academic-catalog@example.com");
        UUID catalogId = jdbc.sql("SELECT id FROM asignaturas_catalogo ORDER BY nombre LIMIT 1")
                .query(UUID.class).single();
        String created = body(perform(post("/api/v1/subjects/from-catalog"), token,
                "{\"catalogSubjectIds\":[\"" + catalogId + "\"]}")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$[0].catalogSubjectId").value(catalogId.toString())));
        String subjectId = JsonPath.read(created, "$[0].id");
        perform(patch("/api/v1/subjects/" + subjectId), token, "{\"archived\":true}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.archived").value(true));
        perform(post("/api/v1/subjects/from-catalog"), token, "{\"catalogSubjectIds\":[\"" + catalogId + "\"]}")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$[0].id").value(subjectId))
                .andExpect(jsonPath("$[0].archived").value(false));
        perform(post("/api/v1/subjects/from-catalog"), token,
                "{\"catalogSubjectIds\":[\"" + UUID.randomUUID() + "\"]}")
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("SUBJECT_CATALOG_NOT_FOUND"));
        perform(get("/api/v1/subjects/catalog"), token, null).andExpect(status().isOk());
    }

    private String register(String email) throws Exception {
        String response = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\"Estudiante\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(response, "$.accessToken");
    }

    private org.springframework.test.web.servlet.ResultActions perform(MockHttpServletRequestBuilder request,
                                                                       String token, String json) throws Exception {
        request.header("Authorization", "Bearer " + token);
        if (json != null) {
            request.contentType(MediaType.APPLICATION_JSON).content(json);
        }
        return mvc.perform(request);
    }

    private static String body(org.springframework.test.web.servlet.ResultActions actions) throws Exception {
        return actions.andReturn().getResponse().getContentAsString();
    }
}
