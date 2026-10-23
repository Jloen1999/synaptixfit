package com.synaptixfit.infrastructure.adapter.input.rest.academic;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.domain.model.academic.TeachingGuide;
import com.synaptixfit.domain.model.academic.TeachingGuide.AssessmentKind;
import com.synaptixfit.domain.model.academic.TeachingGuide.EvaluationMode;
import com.synaptixfit.domain.port.output.academic.StudyAssistantPort;
import com.synaptixfit.domain.port.output.storage.FileStoragePort;
import com.synaptixfit.domain.port.output.storage.PresignedUrl;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.time.Instant;
import java.time.LocalDate;
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
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/**
 * Importar un plan docente sobre la app real y PostgreSQL embebido: subida firmada → análisis en
 * segundo plano (IA sustituida) → aplicar (asignatura, guía, archivo y entregas con fecha) → un
 * segundo «aplicar» se rechaza → modalidad de evaluación → propiedad entre usuarios.
 */
@SpringBootTest
@AutoConfigureMockMvc
class TeachingGuideImportIT {

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
    void pdfIsAnalysedInBackgroundAppliedOnceAndCreatesDatedDeadlines() throws Exception {
        String token = register("guide-import-it@example.com");
        String stranger = register("guide-import-other@example.com");
        LocalDate examDay = LocalDate.now().plusDays(30);
        when(storage.presignUpload(anyString(), anyString(), anyLong(), any()))
                .thenReturn(new PresignedUrl("https://r2.test/put", "PUT", Map.of(), Instant.now().plusSeconds(900)));
        when(storage.download(anyString())).thenReturn(new byte[]{1, 2, 3});
        when(assistant.extractTeachingGuide(any())).thenReturn(new TeachingGuide(
                new TeachingGuide.SubjectInfo("Diseño y evaluación de tecnologías Hardware", "502376", 6.0, null, 6,
                        "Obligatoria", null, null, "Universidad de Extremadura", "2025/2026", null, null),
                List.of(new TeachingGuide.Professor("Juan Ángel García", null, "12")),
                List.of(new TeachingGuide.Topic("Tema 1", TeachingGuide.TopicKind.THEORY, false, List.of("SoC"), 27.0)),
                List.of(new TeachingGuide.Assessment("Prueba 1", 30, null, EvaluationMode.CONTINUOUS,
                                AssessmentKind.EXAM, 120, List.of(1), null, examDay),
                        new TeachingGuide.Assessment("Global", 100, null, EvaluationMode.GLOBAL, AssessmentKind.EXAM,
                                240, List.of(1), null, examDay)),
                List.of(), null));

        String ticket = body(perform(post("/api/v1/teaching-guide-imports/upload-url"), token,
                "{\"fileName\":\"plan docente.pdf\",\"mimeType\":\"application/pdf\",\"sizeBytes\":2048}")
                .andExpect(status().isOk()));
        String objectKey = JsonPath.read(ticket, "$.objectKey");
        assertThat(objectKey).contains("/planes-docentes/");

        String started = body(perform(post("/api/v1/teaching-guide-imports"), token,
                "{\"objectKey\":\"" + objectKey + "\",\"fileName\":\"plan docente.pdf\","
                        + "\"mimeType\":\"application/pdf\",\"sizeBytes\":2048}")
                .andExpect(status().isAccepted()));
        String importId = JsonPath.read(started, "$.id");

        String ready = awaitStatus(token, importId, "READY");
        assertThat((String) JsonPath.read(ready, "$.guide.subject.code")).isEqualTo("502376");
        perform(get("/api/v1/teaching-guide-imports/" + importId), stranger, null)
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("TEACHING_GUIDE_IMPORT_NOT_FOUND"));

        String applied = body(perform(post("/api/v1/teaching-guide-imports/" + importId + "/apply"), token,
                "{\"createDeadlines\":true}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.subjectCreated").value(true))
                .andExpect(jsonPath("$.deadlinesRequested").value(1)));
        String subjectId = JsonPath.read(applied, "$.subjectId");

        perform(post("/api/v1/teaching-guide-imports/" + importId + "/apply"), token, "{\"createDeadlines\":true}")
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("TEACHING_GUIDE_IMPORT_ALREADY_APPLIED"));

        UUID subject = UUID.fromString(subjectId);
        assertThat(jdbc.sql("SELECT COUNT(*) FROM asignaturas WHERE usuario_id = (SELECT usuario_id FROM "
                + "importaciones_plan_docente WHERE id = :id)").param("id", UUID.fromString(importId))
                .query(Long.class).single()).isEqualTo(1);
        assertThat(jdbc.sql("SELECT COUNT(*) FROM entregas_examenes WHERE asignatura_id = :s").param("s", subject)
                .query(Long.class).single()).isEqualTo(1);
        assertThat(jdbc.sql("SELECT COUNT(*) FROM archivos_asignatura WHERE asignatura_id = :s").param("s", subject)
                .query(Long.class).single()).isEqualTo(1);

        perform(get("/api/v1/subjects/" + subjectId + "/teaching-guide"), token, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.subject.ectsCredits").value(6.0))
                .andExpect(jsonPath("$.effectiveMode").value("CONTINUOUS"))
                .andExpect(jsonPath("$.assessments[1].active").value(false));
        perform(put("/api/v1/subjects/" + subjectId + "/teaching-guide/mode"), token, "{\"mode\":\"GLOBAL\"}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.effectiveMode").value("GLOBAL"))
                .andExpect(jsonPath("$.assessments[1].active").value(true));
    }

    @Test
    void officialCatalogIsLoadedWithoutDuplicates() throws Exception {
        String token = register("catalog-it@example.com");
        assertThat(jdbc.sql("SELECT COUNT(*) FROM universidades WHERE codigo_ruct IS NOT NULL").query(Long.class)
                .single()).isEqualTo(96);
        assertThat(jdbc.sql("SELECT COUNT(*) FROM universidades WHERE nombre LIKE '%UTEC%'").query(Long.class)
                .single()).isEqualTo(1);
        assertThat(jdbc.sql("SELECT COUNT(*) FROM asignaturas_catalogo WHERE codigo = '502376'").query(Long.class)
                .single()).isEqualTo(1);
        perform(get("/api/v1/catalog/universities").param("q", "extremadura"), token, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].type").value("Pública"))
                .andExpect(jsonPath("$[0].region").value("Extremadura"));
    }

    private String awaitStatus(String token, String importId, String expected) throws Exception {
        String last = null;
        for (int i = 0; i < 50; i++) {
            last = body(perform(get("/api/v1/teaching-guide-imports/" + importId), token, null)
                    .andExpect(status().isOk()));
            if (expected.equals(JsonPath.read(last, "$.status"))) {
                return last;
            }
            Thread.sleep(100);
        }
        throw new AssertionError("La importación no llegó a " + expected + ": " + last);
    }

    private String register(String email) throws Exception {
        String response = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\"Estudiante\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(response, "$.accessToken");
    }

    private ResultActions perform(MockHttpServletRequestBuilder request, String token, String json) throws Exception {
        request.header("Authorization", "Bearer " + token);
        if (json != null) {
            request.contentType(MediaType.APPLICATION_JSON).content(json);
        }
        return mvc.perform(request);
    }

    private static String body(ResultActions actions) throws Exception {
        return actions.andReturn().getResponse().getContentAsString();
    }
}
