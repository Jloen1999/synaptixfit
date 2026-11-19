package com.synaptixfit.infrastructure.adapter.input.rest.academic;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.domain.model.academic.DocumentQuestion;
import com.synaptixfit.domain.model.academic.QuestionBatch;
import com.synaptixfit.domain.model.academic.QuestionDraft;
import com.synaptixfit.domain.model.academic.QuestionType;
import com.synaptixfit.domain.port.output.academic.StudyAssistantPort;
import com.synaptixfit.domain.port.output.storage.FileStoragePort;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.util.List;
import org.hamcrest.Matchers;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/**
 * «Crear preguntas» (ADR 0058) sobre la app real y PostgreSQL embebido: preguntas del documento, tipo
 * «Varias correctas» guardado y corregido todo o nada, y apps antiguas que no lo reciben.
 */
@SpringBootTest
@AutoConfigureMockMvc
class QuestionCreationIT {

    private static final String ALL_TYPES = "MULTIPLE_CHOICE,FILL_IN_BLANK,MULTIPLE_ANSWER";

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    @MockitoBean
    private FileStoragePort storage;

    @MockitoBean
    private StudyAssistantPort assistant;

    @Test
    void documentQuestionsMultipleAnswerAndOldApps() throws Exception {
        String token = register("questions-it@example.com");
        String subjectId = JsonPath.read(body(perform(post("/api/v1/subjects"), token, null,
                "{\"name\":\"Bases de Datos\",\"credits\":6}").andExpect(status().isCreated())), "$.id");
        String noteId = JsonPath.read(body(perform(post("/api/v1/notes"), token, null,
                "{\"subjectId\":\"" + subjectId + "\",\"title\":\"SQL\",\"content\":\"1. ¿Qué filtra grupos?\"}")
                .andExpect(status().isCreated())), "$.id");
        String materialId = JsonPath.read(body(perform(post("/api/v1/study-materials"), token, null,
                "{\"originType\":\"NOTE\",\"originId\":\"" + noteId + "\"}").andExpect(status().isCreated())), "$.id");

        // Preguntas del documento: la de respuesta larga llega con su estado; nada se guarda todavía.
        when(assistant.documentQuestions(any(), anyInt(), anyInt())).thenReturn(
                new StudyAssistantPort.DocumentQuestionPage(2, List.of(
                        DocumentQuestion.of(QuestionType.MULTIPLE_CHOICE, "¿Qué filtra grupos?",
                                List.of("WHERE", "HAVING"), List.of("HAVING"), true, null),
                        DocumentQuestion.of(null, "Explica DELETE", null, List.of(), false, null))));
        perform(post("/api/v1/study-materials/" + materialId + "/document-questions"), token, ALL_TYPES, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.complete").value(true))
                .andExpect(jsonPath("$.questions[0].status").value("READY"))
                .andExpect(jsonPath("$.questions[0].correctAnswers[0]").value("HAVING"))
                .andExpect(jsonPath("$.questions[1].status").value("LONG_ANSWER"));
        perform(get("/api/v1/study-materials/" + materialId + "/question-bank"), token, ALL_TYPES, null)
                .andExpect(status().isNotFound());

        when(assistant.practiceQuestions(anyList(), any(QuestionBatch.class), anyList())).thenReturn(
                new StudyAssistantPort.PracticeQuestions("SQL", List.of(
                        QuestionDraft.multipleAnswer("¿Cuáles agregan filas?", List.of("COUNT", "JOIN", "AVG"),
                                List.of("COUNT", "AVG"), null),
                        new QuestionDraft(QuestionType.FILL_IN_BLANK, "Una clave ____", null, "primaria", null))));
        perform(post("/api/v1/study-materials/" + materialId + "/question-bank"), token, ALL_TYPES,
                "{\"format\":\"MIXED\",\"newQuestions\":5,\"mode\":\"ADD\",\"documentQuestions\":["
                        + "{\"type\":\"MULTIPLE_CHOICE\",\"statement\":\"¿Qué filtra grupos?\","
                        + "\"options\":[\"WHERE\",\"HAVING\"],\"correctAnswers\":[\"HAVING\"]}]}")
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.requestedQuestions").value(6))
                .andExpect(jsonPath("$.createdQuestions").value(3))
                .andExpect(jsonPath("$.questions[1].type").value("MULTIPLE_ANSWER"))
                .andExpect(jsonPath("$.questions[1].correctAnswers.length()").value(2));

        // Una app antigua (sin cabecera) no ve «Varias correctas».
        perform(get("/api/v1/study-materials/" + materialId + "/question-bank"), token, null, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.questions.length()").value(2))
                .andExpect(jsonPath("$.questions[*].type", Matchers.not(Matchers.hasItem("MULTIPLE_ANSWER"))));

        // En la sesión, todo o nada.
        String session = body(perform(post("/api/v1/test-sessions"), token, ALL_TYPES,
                "{\"materialIds\":[\"" + materialId + "\"]}").andExpect(status().isCreated()));
        String sessionId = JsonPath.read(session, "$.id");
        List<String> ids = JsonPath.read(session, "$.questions[?(@.type == 'MULTIPLE_ANSWER')].id");
        perform(post("/api/v1/test-sessions/" + sessionId + "/answers"), token, ALL_TYPES,
                "{\"questionId\":\"" + ids.getFirst() + "\",\"answers\":[\"COUNT\"]}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.correct").value(false))
                .andExpect(jsonPath("$.result.correctAnswers.length()").value(2));
        perform(post("/api/v1/test-sessions/" + sessionId + "/answers"), token, ALL_TYPES,
                "{\"questionId\":\"" + ids.getFirst() + "\"}")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));

        // Sin cuerpo (apps antiguas) se sustituyen como antes.
        perform(post("/api/v1/study-materials/" + materialId + "/question-bank"), token, null, null)
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.questions.length()").value(1));
    }

    private String register(String email) throws Exception {
        String response = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\"Estudiante\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(response, "$.accessToken");
    }

    private ResultActions perform(MockHttpServletRequestBuilder request, String token, String types, String json)
            throws Exception {
        request.header("Authorization", "Bearer " + token);
        if (types != null) {
            request.header("X-Question-Types", types);
        }
        if (json != null) {
            request.contentType(MediaType.APPLICATION_JSON).content(json);
        }
        return mvc.perform(request);
    }

    private static String body(ResultActions actions) throws Exception {
        return actions.andReturn().getResponse().getContentAsString();
    }
}
