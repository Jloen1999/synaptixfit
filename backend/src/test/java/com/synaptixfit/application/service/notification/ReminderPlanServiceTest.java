package com.synaptixfit.application.service.notification;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.academic.StudyMaterial;
import com.synaptixfit.domain.model.notification.NotificationMode;
import com.synaptixfit.domain.model.notification.NotificationPreferences;
import com.synaptixfit.domain.model.notification.NotificationType;
import com.synaptixfit.domain.model.notification.ReminderKind;
import com.synaptixfit.domain.model.notification.ReminderPlan;
import com.synaptixfit.domain.model.notification.ReminderPlanner;
import com.synaptixfit.domain.model.planner.ActivityType;
import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.Priority;
import com.synaptixfit.domain.model.planner.TimeRange;
import com.synaptixfit.domain.model.user.UsageFocus;
import com.synaptixfit.domain.port.output.academic.StudyMaterialRepositoryPort;
import com.synaptixfit.domain.port.output.notification.NotificationPreferencesRepositoryPort;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import com.synaptixfit.domain.port.output.planner.SubjectDirectoryPort;
import com.synaptixfit.domain.port.output.user.UsageFocusPort;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.util.EnumSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class ReminderPlanServiceTest {

    private static final ZoneId ZONE = ZoneId.of("Europe/Madrid");
    // 21/10/2026 10:00 en Madrid.
    private static final Instant NOW = Instant.parse("2026-10-21T08:00:00Z");
    private static final UUID USER = UUID.randomUUID();
    private static final UUID SUBJECT = UUID.randomUUID();

    private final NotificationPreferencesRepositoryPort preferences = mock(NotificationPreferencesRepositoryPort.class);
    private final UsageFocusPort focus = mock(UsageFocusPort.class);
    private final StudyMaterialRepositoryPort materials = mock(StudyMaterialRepositoryPort.class);
    private final CalendarBlockRepositoryPort blocks = mock(CalendarBlockRepositoryPort.class);
    private final SubjectDirectoryPort subjects = mock(SubjectDirectoryPort.class);
    private ReminderPlanService service;

    @BeforeEach
    void setUp() {
        service = new ReminderPlanService(preferences, focus, materials, blocks, subjects, new ReminderPlanner(),
                Clock.fixed(NOW, ZoneOffset.UTC), ZONE);
        when(preferences.findByUserId(USER)).thenReturn(Optional.empty());
        when(focus.focusOf(USER)).thenReturn(UsageFocus.BOTH);
        when(materials.findDue(eq(USER), eq(NOW), anyInt()))
                .thenReturn(List.of(mock(StudyMaterial.class), mock(StudyMaterial.class)));
        when(subjects.namesOf(eq(USER), any())).thenReturn(Map.of(SUBJECT, "Álgebra"));
    }

    private static CalendarBlock block(ActivityType type, Instant start, String topics, UUID subjectId) {
        return CalendarBlock.builder().id(UUID.randomUUID()).userId(USER).type(type)
                .range(TimeRange.ofMinutes(start, 60))
                .details(new CalendarBlock.Details(subjectId, topics, null, Priority.MEDIUM, false, null, null, null,
                        null, null, null, null))
                .createdAt(NOW).build();
    }

    @Test
    void combinesReviewsAndBlocksWithDefaultPreferences() {
        Instant tomorrow = NOW.plus(Duration.ofDays(1));
        when(blocks.findOverlapping(USER, NOW, NOW.plus(Duration.ofDays(7)), null)).thenReturn(List.of(
                block(ActivityType.STUDY, tomorrow, null, SUBJECT),
                block(ActivityType.SPORT, tomorrow.plus(Duration.ofHours(3)), "Pierna", null)));

        ReminderPlan plan = service.getReminderPlan(USER, 7);

        assertThat(plan.reminders()).filteredOn(r -> r.kind() == ReminderKind.REVIEWS).hasSize(3)
                .allSatisfy(r -> assertThat(r.count()).isEqualTo(2));
        assertThat(plan.reminders()).filteredOn(r -> r.kind() != ReminderKind.REVIEWS)
                .extracting(ReminderPlan.Item::title).containsExactly("Álgebra", "Pierna");
        // Por defecto el límite diario es 10: no recorta nada.
        assertThat(plan.reminders()).hasSize(5);
    }

    @Test
    void fitnessOnlyDoesNotReadReviews() {
        when(focus.focusOf(USER)).thenReturn(UsageFocus.FITNESS);
        when(blocks.findOverlapping(any(), any(), any(), any())).thenReturn(List.of());

        service.getReminderPlan(USER, 7);

        verify(materials, never()).findDue(any(), any(), anyInt());
        verify(blocks).findOverlapping(any(), any(), any(), any());
    }

    @Test
    void restModeReadsNothing() {
        when(preferences.findByUserId(USER)).thenReturn(Optional.of(new NotificationPreferences(UUID.randomUUID(),
                USER, EnumSet.allOf(NotificationType.class), null, null, 10, NotificationMode.REST, NOW, NOW)));

        ReminderPlan plan = service.getReminderPlan(USER, 7);

        assertThat(plan.reminders()).isEmpty();
        verify(materials, never()).findDue(any(), any(), anyInt());
        verify(blocks, never()).findOverlapping(any(), any(), any(), any());
    }

    @Test
    void rejectsAWindowOutOfRangeBeforeReading() {
        assertThatThrownBy(() -> service.getReminderPlan(USER, 8)).isInstanceOf(FieldValidationException.class);
        verify(preferences, never()).findByUserId(any());
    }

    @Test
    void doesNotAskSubjectNamesWhenBlocksHaveTopics() {
        when(preferences.findByUserId(USER)).thenReturn(Optional.of(new NotificationPreferences(UUID.randomUUID(),
                USER, Set.of(NotificationType.MILESTONE), null, null, 10, NotificationMode.NORMAL, NOW, NOW)));
        when(blocks.findOverlapping(any(), any(), any(), any())).thenReturn(List.of(
                block(ActivityType.SPORT, NOW.plus(Duration.ofDays(1)), "Pierna", SUBJECT)));

        assertThat(service.getReminderPlan(USER, 7).reminders()).singleElement()
                .satisfies(r -> assertThat(r.kind()).isEqualTo(ReminderKind.TRAINING));
        verify(subjects, never()).namesOf(any(), any());
    }
}
