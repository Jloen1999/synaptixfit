package com.synaptixfit.application.service.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.InvalidInputException;
import com.synaptixfit.domain.exception.training.ExerciseNotFoundException;
import com.synaptixfit.domain.model.training.Exercise;
import com.synaptixfit.domain.model.training.ExerciseNote;
import com.synaptixfit.domain.model.training.ExerciseTips;
import com.synaptixfit.domain.port.output.training.ExerciseNoteRepositoryPort;
import com.synaptixfit.domain.port.output.training.ExerciseTipsRepositoryPort;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/** «Las claves», «Errores comunes» y la nota propia de un ejercicio (ADR 0031). */
class ExerciseGuideServiceTest {

    private static final Instant NOW = Instant.parse("2026-11-04T10:00:00Z");
    private static final UUID USER = UUID.randomUUID();
    private static final UUID OTHER = UUID.randomUUID();

    private final TrainingFakes.Exercises exercises = new TrainingFakes.Exercises();
    private final Map<String, ExerciseTips> tips = new HashMap<>();
    private final Map<String, ExerciseNote> notes = new HashMap<>();
    private ExerciseGuideService service;
    private Exercise bench;

    @BeforeEach
    void setUp() {
        ExerciseTipsRepositoryPort tipsPort = (id, lang) -> Optional.ofNullable(tips.get(id + "/" + lang));
        ExerciseNoteRepositoryPort notesPort = new ExerciseNoteRepositoryPort() {
            public Optional<ExerciseNote> find(UUID userId, UUID exerciseId) {
                return Optional.ofNullable(notes.get(userId + "/" + exerciseId));
            }
            public void save(UUID userId, ExerciseNote note) { notes.put(userId + "/" + note.exerciseId(), note); }
            public void delete(UUID userId, UUID exerciseId) { notes.remove(userId + "/" + exerciseId); }
        };
        service = new ExerciseGuideService(exercises, tipsPort, notesPort, Clock.fixed(NOW, ZoneOffset.UTC));
        bench = exercises.add(TrainingFakes.strength("Press de banca", "Pectoral mayor"));
    }

    @Test
    void tipsComeInTheAppLanguageOrFallBackToSpanish() {
        tips.put(bench.id() + "/es", new ExerciseTips(List.of("Junta los omóplatos"), List.of("Rebotar")));
        tips.put(bench.id() + "/en", new ExerciseTips(List.of("Squeeze your shoulder blades"), List.of()));

        assertThat(service.tips(bench.id(), "en").keyPoints()).containsExactly("Squeeze your shoulder blades");
        assertThat(service.tips(bench.id(), "fr").keyPoints()).containsExactly("Junta los omóplatos");
        assertThat(service.tips(bench.id(), null).commonMistakes()).containsExactly("Rebotar");
    }

    @Test
    void anExerciseWithoutTipsReturnsEmptyListsAndAnUnknownOneIsNotFound() {
        assertThat(service.tips(bench.id(), "es").isEmpty()).isTrue();
        assertThatThrownBy(() -> service.tips(UUID.randomUUID(), "es")).isInstanceOf(ExerciseNotFoundException.class);
    }

    @Test
    void theNoteIsPrivateTrimmedAndAnEmptyTextDeletesIt() {
        Optional<ExerciseNote> saved = service.save(USER, bench.id(), "  Asiento en el 4  ");

        assertThat(saved).get().satisfies(n -> {
            assertThat(n.text()).isEqualTo("Asiento en el 4");
            assertThat(n.updatedAt()).isEqualTo(NOW);
        });
        assertThat(service.note(USER, bench.id())).isPresent();
        assertThat(service.note(OTHER, bench.id())).isEmpty();

        assertThat(service.save(USER, bench.id(), "   ")).isEmpty();
        assertThat(service.note(USER, bench.id())).isEmpty();
    }

    @Test
    void aTooLongNoteIsRejected() {
        assertThatThrownBy(() -> service.save(USER, bench.id(), "x".repeat(ExerciseNote.MAX_LENGTH + 1)))
                .isInstanceOf(InvalidInputException.class);
    }
}
