package com.synaptixfit.infrastructure.adapter.input.rest.academic;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyList;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.domain.model.academic.QuestionBatch;
import com.synaptixfit.domain.model.academic.QuestionDraft;
import com.synaptixfit.domain.model.academic.QuestionType;
import com.synaptixfit.domain.port.output.academic.StudyAssistantPort;
import com.synaptixfit.domain.port.output.storage.FileStoragePort;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.util.List;
import java.util.stream.IntStream;
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
 * «No lo sé», la entrega del simulacro y las preguntas de la asignatura (ADR 0063) sobre la app real y
 * PostgreSQL embebido.
 */
@SpringBootTest
@AutoConfigureMockMvc
class QuestionPracticeIT {

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
    void dontKnowMockExamSubmissionAndSubjectQuestions() throws Exception {
        String token = register("practice-it@example.com");
        String subjectId = JsonPath.read(body(perform(post("/api/v1/subjects"), token,
                "{\"name\":\"Bases de Datos\",\"credits\":6}").andExpect(status().isCreated())), "$.id");
        String noteId = JsonPath.read(body(perform(post("/api/v1/notes"), token,
                "{\"subjectId\":\"" + subjectId + "\",\"title\":\"SQL\",\"content\":\"Claves y consultas\"}")
                .andExpect(status().isCreated())), "$.id");
        String materialId = JsonPath.read(body(perform(post("/api/v1/study-materials"), token,
                "{\"originType\":\"NOTE\",\"originId\":\"" + noteId + "\"}").andExpect(status().isCreated())), "$.id");
        when(assistant.practiceQuestions(anyList(), any(QuestionBatch.class), anyList())).thenReturn(
                new StudyAssistantPort.PracticeQuestions("SQL", IntStream.range(0, 5).mapToObj(i ->
                        new QuestionDraft(QuestionType.FILL_IN_BLANK, "Pregunta " + i + " ___", null,
                                "respuesta" + i, null)).toList()));
        perform(post("/api/v1/study-materials/" + materialId + "/question-bank"), token,
                "{\"format\":\"FILL_IN_BLANK\",\"newQuestions\":5,\"mode\":\"ADD\"}")
                .andExpect(status().isCreated());

        // Todas nuevas en la lista de la asignatura.
        String list = body(perform(get("/api/v1/subjects/" + subjectId + "/questions"), token, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.subjectName").value("Bases de Datos"))
                .andExpect(jsonPath("$.total").value(5))
                .andExpect(jsonPath("$.toReview").value(0))
                .andExpect(jsonPath("$.questions[0].standing").value("NEW"))
                .andExpect(jsonPath("$.questions[0].materialId").value(materialId)));
        List<String> ids = JsonPath.read(list, "$.questions[*].question.id");

        // «No lo sé» fuera de una sesión: enseña la solución y la pregunta pasa la primera.
        perform(post("/api/v1/questions/" + ids.get(3) + "/attempts"), token, "{\"dontKnow\":true}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.dontKnow").value(true))
                .andExpect(jsonPath("$.correct").value(false))
                .andExpect(jsonPath("$.correctAnswers.length()").value(1));
        perform(get("/api/v1/subjects/" + subjectId + "/questions"), token, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.toReview").value(1))
                .andExpect(jsonPath("$.questions[0].question.id").value(ids.get(3)))
                .andExpect(jsonPath("$.questions[0].standing").value("DONT_KNOW"));
        perform(post("/api/v1/questions/" + ids.get(3) + "/attempts"), token, "{}")
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));

        // Simulacro entregado sin respuestas: no cuenta, queda abandonado y fuera del historial.
        String empty = JsonPath.read(body(perform(post("/api/v1/test-sessions"), token,
                "{\"materialIds\":[\"" + materialId + "\"]}").andExpect(status().isCreated())
                .andExpect(jsonPath("$.countsIfSubmitted").value(false))), "$.id");
        perform(post("/api/v1/test-sessions/" + empty + "/complete"), token, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.counted").value(false))
                .andExpect(jsonPath("$.status").value("ABANDONED"))
                .andExpect(jsonPath("$.xpGranted").value(0));
        perform(get("/api/v1/test-sessions"), token, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));
        perform(get("/api/v1/test-sessions/" + empty), token, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.counted").value(false));
        perform(post("/api/v1/test-sessions/" + empty + "/complete"), token, null)
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("QUIZ_SESSION_NOT_IN_PROGRESS"));

        // Simulacro con un «No lo sé» y una respuesta: lo sin contestar pasa a «No lo sé» al entregar.
        String session = body(perform(post("/api/v1/test-sessions"), token,
                "{\"materialIds\":[\"" + materialId + "\"]}").andExpect(status().isCreated()));
        String sessionId = JsonPath.read(session, "$.id");
        String first = JsonPath.read(session, "$.questions[0].id");
        String second = JsonPath.read(session, "$.questions[1].id");
        perform(post("/api/v1/test-sessions/" + sessionId + "/answers"), token,
                "{\"questionId\":\"" + first + "\",\"dontKnow\":true}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.result.dontKnow").value(true))
                .andExpect(jsonPath("$.session.questions[0].dontKnow").value(true))
                .andExpect(jsonPath("$.session.questions[0].correctAnswers.length()").value(1))
                .andExpect(jsonPath("$.session.countsIfSubmitted").value(true));
        // Con la solución a la vista no se puede cambiar.
        perform(post("/api/v1/test-sessions/" + sessionId + "/answers"), token,
                "{\"questionId\":\"" + first + "\",\"answer\":\"x\"}")
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("QUIZ_QUESTION_ALREADY_ANSWERED"));
        perform(post("/api/v1/test-sessions/" + sessionId + "/answers"), token,
                "{\"questionId\":\"" + second + "\",\"answer\":\"no\"}")
                .andExpect(status().isOk());
        perform(post("/api/v1/test-sessions/" + sessionId + "/complete"), token, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.counted").value(true))
                .andExpect(jsonPath("$.status").value("COMPLETED"))
                .andExpect(jsonPath("$.answeredCount").value(2))
                .andExpect(jsonPath("$.xpGranted").value(0))
                .andExpect(jsonPath("$.questions[0].unanswered").value(false))
                .andExpect(jsonPath("$.questions[4].unanswered").value(true))
                .andExpect(jsonPath("$.questions[4].dontKnow").value(true));
        perform(get("/api/v1/test-sessions/" + sessionId), token, null)
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.questions[4].unanswered").value(true));
        perform(get("/api/v1/subjects/" + subjectId + "/questions"), token, null)
                .andExpect(jsonPath("$.toReview").value(5));

        // Práctica libre: el «No lo sé» cuenta como respondido.
        String bankId = JsonPath.read(body(perform(get("/api/v1/study-materials/" + materialId + "/question-bank"),
                token, null)), "$.id");
        StringBuilder answers = new StringBuilder();
        for (int i = 1; i < ids.size(); i++) {
            answers.append(i > 1 ? "," : "").append("\"").append(ids.get(i)).append("\":\"x\"");
        }
        perform(post("/api/v1/question-banks/" + bankId + "/practice-completions"), token,
                "{\"answers\":{" + answers + "},\"dontKnow\":[\"" + ids.getFirst() + "\"]}")
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.total").value(5))
                .andExpect(jsonPath("$.xpAwarded").value(20));
    }

    private String register(String email) throws Exception {
        String response = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\"Estudiante\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(response, "$.accessToken");
    }

    private ResultActions perform(MockHttpServletRequestBuilder request, String token, String json)
            throws Exception {
        request.header("Authorization", "Bearer " + token);
        request.header("X-Question-Types", ALL_TYPES);
        if (json != null) {
            request.contentType(MediaType.APPLICATION_JSON).content(json);
        }
        return mvc.perform(request);
    }

    private static String body(ResultActions actions) throws Exception {
        return actions.andReturn().getResponse().getContentAsString();
    }
}
