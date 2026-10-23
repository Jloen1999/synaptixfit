package com.synaptixfit.infrastructure.adapter.input.rest.profile;

import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

/**
 * Flujo completo del módulo de perfil y catálogo sobre PostgreSQL real (valida también el mapeo
 * JPA de arrays y la migración V100).
 */
@SpringBootTest
@AutoConfigureMockMvc
class ProfileFlowIT {

    /** Datos sembrados por V2: Grado en Ingeniería Informática (UGR) y su asignatura Estructura de Computadores. */
    private static final String UGR = "acebdf1d-c914-4e5c-8282-3fd4643402e4";
    private static final String INFORMATICA = "1bdec8da-b0b8-45f5-99de-d28050008e0c";
    private static final String COMPUTER_STRUCTURE = "ba9dfacb-47d7-4976-9ecf-09344908372d";

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    private String register(String email) throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"secret123\",\"fullName\":\"Perfil\"}"))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(body, "$.accessToken");
    }

    private static MockHttpServletRequestBuilder auth(MockHttpServletRequestBuilder b, String token) {
        return b.header("Authorization", "Bearer " + token).contentType(MediaType.APPLICATION_JSON);
    }

    @Test
    void wellnessOnboardingAndHistories() throws Exception {
        String token = register("profile-it@example.com");

        mvc.perform(auth(get("/api/v1/profile/onboarding"), token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.completed").value(false))
                .andExpect(jsonPath("$.accountCompleted").value(true))
                .andExpect(jsonPath("$.nextStep").value("FOCUS"))
                .andExpect(jsonPath("$.pendingSteps", hasSize(4)));

        // Elegir solo deporte deja como único paso el perfil físico.
        mvc.perform(auth(patch("/api/v1/me"), token).content("{\"usageFocus\":\"FITNESS\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.usageFocus").value("FITNESS"))
                .andExpect(jsonPath("$.usageFocusChosen").value(true));
        mvc.perform(auth(get("/api/v1/profile/onboarding"), token))
                .andExpect(jsonPath("$.nextStep").value("WELLNESS_PROFILE"))
                .andExpect(jsonPath("$.pendingSteps", hasSize(1)));

        mvc.perform(auth(get("/api/v1/profile/wellness"), token))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("PROFILE_WELLNESS_NOT_FOUND"));

        mvc.perform(auth(post("/api/v1/profile/onboarding/complete"), token))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.code").value("PROFILE_ONBOARDING_WELLNESS_REQUIRED"));

        mvc.perform(auth(put("/api/v1/profile/wellness"), token).content("""
                        {"age":22,"sex":"FEMALE","city":"Granada","weightKg":60,"heightCm":165,
                         "activityLevel":"MODERATE","primaryGoal":"HYPERTROPHY",
                         "equipment":["mancuerna","barra"],"availableDays":[5,1,3],"minutesPerSession":45}
                        """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.bmi").value(22.0))
                .andExpect(jsonPath("$.primaryGoalLabel").value("Hipertrofia Muscular"))
                .andExpect(jsonPath("$.availableDays", hasSize(3)))
                .andExpect(jsonPath("$.availableDays[0]").value(1))
                .andExpect(jsonPath("$.daysPerWeek").value(3))
                .andExpect(jsonPath("$.goals[0]").value("Hipertrofia Muscular"));

        mvc.perform(auth(patch("/api/v1/profile/wellness"), token)
                        .content("{\"weightKg\":63.5,\"primaryGoal\":\"MOBILITY\",\"availableDays\":[2]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.bmi").value(23.3))
                .andExpect(jsonPath("$.primaryGoal").value("MOBILITY"))
                .andExpect(jsonPath("$.daysPerWeek").value(1));

        mvc.perform(auth(get("/api/v1/profile/wellness/weight-history"), token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].weightKg").value(60.0))
                .andExpect(jsonPath("$[1].weightKg").value(63.5));

        mvc.perform(auth(get("/api/v1/profile/wellness/goal-history"), token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].goal").value("MOBILITY"))
                .andExpect(jsonPath("$[0].previousGoal").value("HYPERTROPHY"))
                .andExpect(jsonPath("$[0].active").value(true))
                .andExpect(jsonPath("$[1].active").value(false));

        mvc.perform(auth(patch("/api/v1/profile/wellness"), token).content("{\"availableDays\":[9]}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));

        // Sin clave de IA en los tests: se responde con las reglas deterministas.
        mvc.perform(auth(post("/api/v1/profile/wellness/goal-suggestions"), token).content("{\"activityLevel\":\"HIGH\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.source").value("RULES"))
                .andExpect(jsonPath("$.suggestions[0].goal").value("MAX_STRENGTH"))
                .andExpect(jsonPath("$.suggestions[0].label").value("Fuerza Máxima"));

        mvc.perform(auth(post("/api/v1/profile/onboarding/complete"), token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.completed").value(true));
    }

    @Test
    void catalogAndAcademicProfile() throws Exception {
        String token = register("profile-academic-it@example.com");

        mvc.perform(auth(get("/api/v1/catalog/universities").param("q", "granada"), token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[*].id", hasItem(UGR)));

        mvc.perform(auth(get("/api/v1/catalog/universities/" + UGR + "/degrees"), token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[*].id", hasItem(INFORMATICA)));

        String centers = mvc.perform(auth(get("/api/v1/catalog/universities/" + UGR + "/centers"), token))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        String centerId = JsonPath.read(centers, "$[0].id");
        mvc.perform(auth(get("/api/v1/catalog/centers/" + centerId + "/degrees"), token))
                .andExpect(status().isOk());

        mvc.perform(auth(get("/api/v1/catalog/degrees/" + INFORMATICA + "/subjects")
                        .param("q", "estructura de computadóres").param("course", "2"), token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalItems").value(1))
                .andExpect(jsonPath("$.items[0].id").value(COMPUTER_STRUCTURE))
                .andExpect(jsonPath("$.items[0].credits").value(6.0));

        mvc.perform(auth(get("/api/v1/catalog/degrees/" + INFORMATICA + "/subjects")
                        .param("character", "obligatoria").param("size", "5"), token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].character").value("Obligatoria"));

        mvc.perform(auth(get("/api/v1/catalog/degrees/" + INFORMATICA + "/subjects")
                        .param("character", "optativa"), token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalItems").value(0));

        mvc.perform(auth(get("/api/v1/catalog/subjects/" + COMPUTER_STRUCTURE), token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.subject.name").value("Estructura de Computadores"))
                .andExpect(jsonPath("$.degree.universityName").value("Universidad de Granada"))
                .andExpect(jsonPath("$.evaluation").exists());

        mvc.perform(auth(get("/api/v1/catalog/degrees/00000000-0000-0000-0000-000000000000"), token))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value("CATALOG_DEGREE_NOT_FOUND"));

        mvc.perform(auth(put("/api/v1/profile/academic"), token).content("""
                        {"degreeId":"%s","semester":5,"modality":"HYBRID","semesterCredits":30,
                         "weeklyStudyHoursGoal":20,"targetGpa":4.5,
                         "classesStartDate":"2026-09-15","classesEndDate":"2027-01-20"}
                        """.formatted(INFORMATICA)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.university").value("Universidad de Granada"))
                .andExpect(jsonPath("$.degree").value("Grado en Ingeniería Informática"))
                .andExpect(jsonPath("$.modality").value("HYBRID"))
                .andExpect(jsonPath("$.hasSemesterDates").value(true));

        mvc.perform(auth(patch("/api/v1/profile/academic"), token).content("{\"classesEndDate\":\"2026-01-01\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("PROFILE_INVALID_CLASS_DATES"));

        mvc.perform(auth(get("/api/v1/profile/degrees"), token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].degree.id").value(INFORMATICA));

        mvc.perform(auth(get("/api/v1/profile/degrees/subjects").param("q", "estructura de comp"), token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].subject.id").value(COMPUTER_STRUCTURE))
                .andExpect(jsonPath("$.items[0].active").value(false));

        mvc.perform(auth(get("/api/v1/profile"), token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.academic.semester").value(5))
                .andExpect(jsonPath("$.degrees", hasSize(1)))
                .andExpect(jsonPath("$.onboarding.subjectsCompleted").value(false));

        mvc.perform(auth(delete("/api/v1/profile/degrees/" + INFORMATICA), token))
                .andExpect(status().isNoContent());
        mvc.perform(auth(put("/api/v1/profile/degrees/" + INFORMATICA), token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.degree.centerName").exists());
    }
}
