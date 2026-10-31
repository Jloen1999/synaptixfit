package com.synaptixfit.application.service.planner;

import static com.synaptixfit.application.service.planner.PlannerFakes.at;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.planner.CreateDeadlineUseCase;
import com.synaptixfit.application.port.input.planner.CreateDeadlinesFromGuideUseCase;
import com.synaptixfit.application.port.input.planner.GetDeadlinesUseCase;
import com.synaptixfit.application.port.input.planner.UpdateDeadlineUseCase;
import com.synaptixfit.domain.event.planner.DeadlineCompletionChanged;
import com.synaptixfit.domain.model.planner.Deadline;
import com.synaptixfit.domain.model.planner.ItemTimeStatus;
import com.synaptixfit.domain.model.planner.DeadlineType;
import com.synaptixfit.domain.model.planner.Priority;
import com.synaptixfit.domain.model.planner.SubjectRef;
import com.synaptixfit.domain.model.shared.PageRequest;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class DeadlineServiceTest {

    private PlannerFakes f;
    private DeadlineService service;

    @BeforeEach
    void setUp() {
        f = new PlannerFakes();
        service = new DeadlineService(f.deadlines, f.directory, f.xp, f.xp, f.publisher, f.weeklyLoadService(),
                PlannerFakes.ZONE, PlannerFakes.CLOCK);
    }

    private Deadline create(String title, DeadlineType type, Instant dueAt, UUID subjectId) {
        return service.createDeadline(new CreateDeadlineUseCase.Command(f.user, title, type, dueAt, Priority.HIGH,
                null, subjectId));
    }

    @Test
    void completionGrantsThirtyOnceAndRevokesOnUncomplete() {
        Deadline d = create("Práctica 1", DeadlineType.ASSIGNMENT, at(3, 23, 59), null);

        assertThat(service.setCompletion(f.user, d.id(), true).xpDelta()).isEqualTo(30);
        assertThat(service.setCompletion(f.user, d.id(), true).xpDelta()).isZero();
        assertThat(f.xp.of(f.user)).isEqualTo(30);
        assertThat(f.events).singleElement().isInstanceOfSatisfying(DeadlineCompletionChanged.class,
                e -> assertThat(e.completed()).isTrue());

        assertThat(service.setCompletion(f.user, d.id(), false).xpDelta()).isEqualTo(-30);
        assertThat(f.xp.of(f.user)).isZero();
        assertThat(f.events).hasSize(2);
    }

    @Test
    void challengeSyncIsIdempotentAndIgnoresForeignDeadlines() {
        Deadline d = create("Examen final", DeadlineType.EXAM, at(4, 9, 0), null);

        service.syncFromChallenge(f.user, d.id(), true);
        service.syncFromChallenge(f.user, d.id(), true);
        service.syncFromChallenge(f.otherUser, d.id(), false);
        service.syncFromChallenge(f.user, UUID.randomUUID(), true);

        assertThat(f.deadlines.store.get(d.id()).completed()).isTrue();
        assertThat(f.events).hasSize(1);
        assertThat(f.xp.of(f.user)).isEqualTo(30);
    }

    @Test
    void deletingACompletedDeadlineRevokesItsExperience() {
        Deadline d = create("Entrega", DeadlineType.ASSIGNMENT, at(3, 12, 0), null);
        service.setCompletion(f.user, d.id(), true);
        service.deleteDeadline(f.user, d.id());
        assertThat(f.xp.of(f.user)).isZero();
        assertThat(f.deadlines.store).isEmpty();
    }

    @Test
    void subjectMustBeOwnedAndCanBeCleared() {
        SubjectRef own = f.directory.addSubject(f.user, "Álgebra", "ALG", 3);
        SubjectRef foreign = f.directory.addSubject(f.otherUser, "Física", "FIS", 3);
        assertThatThrownBy(() -> create("x", DeadlineType.OTHER, at(3, 12, 0), foreign.id()))
                .extracting("code").isEqualTo("PLANNER_SUBJECT_NOT_FOUND");

        Deadline d = create("Entrega", DeadlineType.ASSIGNMENT, at(3, 12, 0), own.id());
        Deadline updated = service.updateDeadline(new UpdateDeadlineUseCase.Command(f.user, d.id(), "Entrega final",
                null, null, Priority.LOW, null, null, true));
        assertThat(updated.subjectId()).isNull();
        assertThat(updated.title()).isEqualTo("Entrega final");
        assertThat(updated.type()).isEqualTo(DeadlineType.ASSIGNMENT);
        assertThat(updated.difficulty()).isEqualTo(Priority.LOW);
    }

    @Test
    void pendingIncludesRecentOverdueFirstAndHidesCompleted() {
        Deadline past = create("Pasada", DeadlineType.ASSIGNMENT, at(-2, 12, 0), null);
        Deadline done = create("Hecha", DeadlineType.ASSIGNMENT, at(2, 12, 0), null);
        Deadline pending = create("Pendiente", DeadlineType.EXAM, at(3, 12, 0), null);
        Deadline earlyToday = create("Hoy temprano", DeadlineType.EXAM, at(0, 1, 0), null);
        service.setCompletion(f.user, done.id(), true);

        var page = service.getDeadlines(new GetDeadlinesUseCase.Query(f.user, null, null, null, true, true,
                new PageRequest(0, 20)));
        // La vencida sin entregar no desaparece de «Pendientes»: sale la primera.
        assertThat(page.items()).extracting(Deadline::id).containsExactly(past.id(), earlyToday.id(), pending.id());
        // Sin includeOverdue, «upcoming» sigue empezando hoy.
        var upcoming = service.getDeadlines(new GetDeadlinesUseCase.Query(f.user, null, null, null, true,
                new PageRequest(0, 20)));
        assertThat(upcoming.items()).extracting(Deadline::id).containsExactly(earlyToday.id(), pending.id());
        assertThat(past.timeStatus(PlannerFakes.NOW)).isEqualTo(ItemTimeStatus.MISSED);
        assertThat(pending.timeStatus(PlannerFakes.NOW)).isEqualTo(ItemTimeStatus.UPCOMING);
    }

    @Test
    void anotherUsersDeadlineIsNotFound() {
        Deadline d = create("Entrega", DeadlineType.ASSIGNMENT, at(3, 12, 0), null);
        assertThatThrownBy(() -> service.setCompletion(f.otherUser, d.id(), true))
                .extracting("code").isEqualTo("DEADLINE_NOT_FOUND");
    }

    @Test
    void weeklyLoadCountsExamsAndDeliveries() {
        create("Examen", DeadlineType.EXAM, at(2, 9, 0), null);
        create("Entrega", DeadlineType.ASSIGNMENT, at(3, 9, 0), null);
        create("Presentación", DeadlineType.PRESENTATION, at(4, 9, 0), null);
        assertThat(f.loads.findByUserAndWeek(f.user, PlannerFakes.MONDAY)).hasValueSatisfying(l -> {
            assertThat(l.exams()).isEqualTo(1);
            assertThat(l.deliveries()).isEqualTo(2);
        });
    }

    @Test
    void guideDeadlinesAreCreatedOnceWithDifficultyByType() {
        SubjectRef subject = f.directory.addSubject(f.user, "Hardware", "502376", 3);
        CreateDeadlinesFromGuideUseCase.Command command = new CreateDeadlinesFromGuideUseCase.Command(f.user,
                subject.id(), List.of(
                        new CreateDeadlinesFromGuideUseCase.Item("Prueba 1", DeadlineType.EXAM, at(5, 9, 0), "30 %"),
                        new CreateDeadlinesFromGuideUseCase.Item("Trabajo 1", DeadlineType.ASSIGNMENT, at(6, 9, 0),
                                null)));

        assertThat(service.createFromGuide(command)).isEqualTo(2);
        assertThat(service.createFromGuide(command)).isZero();

        List<Deadline> all = f.deadlines.store.values().stream().toList();
        assertThat(all).hasSize(2);
        assertThat(all).filteredOn(d -> d.type() == DeadlineType.EXAM).singleElement()
                .satisfies(d -> assertThat(d.difficulty()).isEqualTo(Priority.HIGH));
        assertThat(all).filteredOn(d -> d.type() == DeadlineType.ASSIGNMENT).singleElement()
                .satisfies(d -> assertThat(d.difficulty()).isEqualTo(Priority.MEDIUM));
    }
}
