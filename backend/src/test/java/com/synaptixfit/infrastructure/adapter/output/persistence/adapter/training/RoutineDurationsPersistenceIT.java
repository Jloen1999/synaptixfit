package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.domain.model.training.PlannedExercise;
import com.synaptixfit.domain.model.training.RecordedDuration;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.port.output.training.RoutineRepositoryPort;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

/**
 * Estimación que aprende (ADR 0048) sobre PostgreSQL real: V1070 crea {@code duraciones_ejercicio_rutina} y quita
 * la columna vieja; {@link RoutinePersistenceAdapter} guarda las tres últimas duraciones de cada ejercicio, descarta
 * la cuarta y no reescribe las que no cambian; la API devuelve la estimación aprendida (mediana acotada) y la
 * exportación de datos las incluye.
 */
@SpringBootTest
@AutoConfigureMockMvc
class RoutineDurationsPersistenceIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;

    @Autowired
    private JdbcClient jdbc;

    @Autowired
    private RoutineRepositoryPort routines;

    @Autowired
    private PlatformTransactionManager transactions;

    @Test
    void keepsTheLastThreeDurationsAndTheEstimateUsesTheirMedian() throws Exception {
        String suffix = UUID.randomUUID().toString().substring(0, 8);
        String registered = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"dur" + suffix + "@example.com\",\"password\":\"secret123\","
                                + "\"fullName\":\"Dur " + suffix + "\"}"))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        String token = JsonPath.read(registered, "$.accessToken");
        String exerciseId = jdbc.sql("SELECT CAST(id AS text) FROM ejercicios WHERE 'repeticiones' = ANY (tipo_medicion)"
                + " AND COALESCE(activo, true) ORDER BY nombre LIMIT 1").query(String.class).single();
        // 4 × (10 reps × 3 s + 90 s) = 480 s de base: cada dato real se acota a [240, 1200].
        String routine = mvc.perform(post("/api/v1/routines").header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Dur\",\"goal\":\"HYPERTROPHY\",\"visibility\":\"PRIVATE\",\"weeks\":[{\"days\":["
                                + "{\"dayNumber\":1,\"exercises\":[{\"exerciseId\":\"" + exerciseId
                                + "\",\"sets\":4,\"reps\":10,\"restSeconds\":90}]}]}]}"))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        UUID routineId = UUID.fromString(JsonPath.read(routine, "$.id"));
        UUID plannedId = UUID.fromString(JsonPath.read(routine, "$.weeks[0].days[0].exercises[0].id"));

        assertThat(jdbc.sql("SELECT count(*) FROM information_schema.columns WHERE table_name = 'seleccion_de_ejercicios'"
                + " AND column_name = 'duracion_real_segundos'").query(Long.class).single()).isZero();

        Instant t = Instant.parse("2026-11-01T10:00:00.123456789Z");
        int[] seconds = {10_800, 500, 520, 560};
        for (int i = 0; i < seconds.length; i++) {
            int s = seconds[i];
            Instant at = t.plusSeconds(86_400L * i);
            inTransaction(() -> {
                Routine r = routines.findById(routineId).orElseThrow();
                r.plannedExercise(plannedId).recordRealDuration(s, at);
                routines.save(r);
            });
        }

        List<Integer> stored = jdbc.sql("SELECT segundos FROM duraciones_ejercicio_rutina"
                        + " WHERE ejercicio_seleccionado_id = :id ORDER BY registrada_en")
                .param("id", plannedId).query(Integer.class).list();
        assertThat(stored).containsExactly(500, 520, 560);
        List<UUID> idsBefore = rowIds(plannedId);

        // Guardar otra vez sin cambios no reescribe las filas (mismo id).
        inTransaction(() -> routines.save(routines.findById(routineId).orElseThrow()));
        assertThat(rowIds(plannedId)).containsExactlyElementsOf(idsBefore);

        PlannedExercise reloaded = routines.findById(routineId).orElseThrow().plannedExercise(plannedId);
        assertThat(reloaded.recentDurations()).extracting(RecordedDuration::seconds).containsExactly(500, 520, 560);
        assertThat(reloaded.estimatedSeconds()).isEqualTo(520);

        String read = mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                        .get("/api/v1/routines/" + routineId).header("Authorization", "Bearer " + token))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        assertThat((Integer) JsonPath.read(read, "$.weeks[0].days[0].exercises[0].estimatedSeconds")).isEqualTo(520);
        assertThat((Integer) JsonPath.read(read, "$.weeks[0].days[0].exercises[0].realDurationSeconds")).isEqualTo(520);
        assertThat((Integer) JsonPath.read(read, "$.weeks[0].days[0].estimatedMinutes")).isEqualTo(9);

        // Son datos de la persona: salen en su exportación.
        String export = mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                        .get("/api/v1/me/export").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        assertThat(export).contains("routineExerciseDurations")
                .containsPattern("\"segundos\"\\s*:\\s*520");
    }

    private List<UUID> rowIds(UUID plannedId) {
        return jdbc.sql("SELECT id FROM duraciones_ejercicio_rutina WHERE ejercicio_seleccionado_id = :id"
                + " ORDER BY registrada_en").param("id", plannedId).query(UUID.class).list();
    }

    private void inTransaction(Runnable action) {
        new TransactionTemplate(transactions).executeWithoutResult(status -> action.run());
    }
}
