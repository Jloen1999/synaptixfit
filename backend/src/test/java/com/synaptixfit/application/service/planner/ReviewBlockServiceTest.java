package com.synaptixfit.application.service.planner;

import static com.synaptixfit.application.service.planner.PlannerFakes.at;
import static org.assertj.core.api.Assertions.assertThat;

import com.synaptixfit.application.port.input.planner.ScheduleReviewBlockUseCase;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.SubjectRef;
import com.synaptixfit.domain.model.planner.TimeRange;
import java.util.Optional;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class ReviewBlockServiceTest {

    private PlannerFakes f;
    private ReviewBlockService service;
    private final UUID material = UUID.randomUUID();

    @BeforeEach
    void setUp() {
        f = new PlannerFakes();
        service = new ReviewBlockService(f.blocks, f.directory, PlannerFakes.ZONE, PlannerFakes.CLOCK);
    }

    @Test
    void createsANonFixedReviewBlockOnceForTheMaterialAndMovesItLater() {
        SubjectRef subject = f.directory.addSubject(f.user, "Historia", "HIS", 3);
        var command = new ScheduleReviewBlockUseCase.Command(f.user, material, subject.id(), "Tema 3", at(2, 17, 0));

        Optional<CalendarBlock> created = service.scheduleReview(command);
        Optional<CalendarBlock> again = service.scheduleReview(command);

        assertThat(created).hasValueSatisfying(b -> {
            assertThat(b.type()).isEqualTo(ActivityType.REVIEW);
            assertThat(b.fixed()).isFalse();
            assertThat(b.start()).isEqualTo(at(2, 17, 0));
            assertThat(b.range().minutes()).isEqualTo(30);
            assertThat(b.details().topics()).isEqualTo("Tema 3");
            assertThat(b.subjectId()).isEqualTo(subject.id());
        });
        assertThat(again).hasValueSatisfying(b -> assertThat(b.id()).isEqualTo(created.orElseThrow().id()));
        assertThat(f.blocks.store).hasSize(1);

        // Nueva fecha SM-2: el bloque pendiente se mueve en lugar de crear otro o quedarse en la antigua.
        CalendarBlock moved = service.scheduleReview(new ScheduleReviewBlockUseCase.Command(f.user, material,
                subject.id(), "Tema 3", at(4, 10, 0))).orElseThrow();
        assertThat(moved.id()).isEqualTo(created.orElseThrow().id());
        assertThat(moved.start()).isEqualTo(at(4, 10, 0));
        assertThat(moved.dayOfWeek()).isEqualTo(5);
        assertThat(f.blocks.store).hasSize(1);
    }

    @Test
    void shiftsToTheFirstFreeSlotOfTheDayWhenBusy() {
        f.blocks.save(CalendarBlock.builder().id(UUID.randomUUID()).userId(f.user)
                .range(new TimeRange(at(2, 17, 0), at(2, 18, 0))).type(ActivityType.CLASS).build());

        CalendarBlock b = service.scheduleReview(new ScheduleReviewBlockUseCase.Command(f.user, material, null,
                "Tema", at(2, 17, 0))).orElseThrow();

        assertThat(b.start()).isEqualTo(at(2, 18, 0));
        assertThat(b.hasConflict()).isFalse();
    }

    @Test
    void neverSchedulesInThePastNorBeforeEightAndDropsForeignSubjects() {
        SubjectRef foreign = f.directory.addSubject(f.otherUser, "Ajena", "AJ", 3);
        CalendarBlock overdue = service.scheduleReview(new ScheduleReviewBlockUseCase.Command(f.user, material,
                foreign.id(), "Tema", at(-3, 9, 0))).orElseThrow();
        assertThat(overdue.start()).isEqualTo(at(0, 10, 0));
        assertThat(overdue.subjectId()).isNull();

        CalendarBlock early = service.scheduleReview(new ScheduleReviewBlockUseCase.Command(f.user, UUID.randomUUID(),
                null, "Tema", at(3, 0, 0))).orElseThrow();
        assertThat(early.start()).isEqualTo(at(3, 8, 0));
    }
}
