package com.synaptixfit.infrastructure.adapter.input.rest.planner;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.synaptixfit.infrastructure.adapter.input.scheduler.ClassAttendanceScheduler;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.TimeRange;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import com.synaptixfit.support.EmbeddedPostgresSupport;
import java.time.Duration;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.web.servlet.MockMvc;

/** Clases dadas por asistidas al terminar y «No fui» (ADR 0029), sobre la base de datos real (V1030). */
@SpringBootTest
@AutoConfigureMockMvc
class ClassAttendanceIT {

    @DynamicPropertySource
    static void datasource(DynamicPropertyRegistry registry) {
        EmbeddedPostgresSupport.register(registry);
    }

    @Autowired
    private MockMvc mvc;
    @Autowired
    private CalendarBlockRepositoryPort blocks;
    @Autowired
    private ClassAttendanceScheduler scheduler;

    @Test
    void anEndedClassIsAttendedAndNotAttendingKeepsItUnmarked() throws Exception {
        String body = mvc.perform(post("/api/v1/auth/register").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"class-" + UUID.randomUUID()
                                + "@example.com\",\"password\":\"secret123\",\"fullName\":\"Ana\"}"))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        String auth = "Bearer " + JsonPath.read(body, "$.accessToken");
        UUID userId = UUID.fromString(JsonPath.read(body, "$.user.id"));
        Instant start = Instant.now().truncatedTo(ChronoUnit.MINUTES).minus(Duration.ofHours(2));
        CalendarBlock lecture = blocks.save(CalendarBlock.builder().id(UUID.randomUUID()).userId(userId)
                .range(TimeRange.ofMinutes(start, 60)).type(ActivityType.CLASS).fixed(true).createdAt(start)
                .build());

        scheduler.attendEndedClasses();
        assertThat(blocks.findById(lecture.id())).hasValueSatisfying(b -> {
            assertThat(b.completed()).isTrue();
            assertThat(b.xpAwarded()).isTrue();
        });

        mvc.perform(put("/api/v1/planner/blocks/" + lecture.id() + "/completion").header("Authorization", auth)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"completed\":false}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.block.completed").value(false))
                .andExpect(jsonPath("$.block.absent").value(true));

        scheduler.attendEndedClasses();
        assertThat(blocks.findById(lecture.id())).hasValueSatisfying(b -> {
            assertThat(b.completed()).isFalse();
            assertThat(b.absent()).isTrue();
        });
    }
}
