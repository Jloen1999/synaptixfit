package com.synaptixfit.application.service.training;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.application.port.input.training.CreateRoutineShareLinkUseCase;
import com.synaptixfit.domain.exception.training.RoutineNotFoundException;
import com.synaptixfit.domain.exception.training.RoutineShareLinkLimitException;
import com.synaptixfit.domain.exception.training.RoutineShareLinkNotFoundException;
import com.synaptixfit.domain.model.shared.Visibility;
import com.synaptixfit.domain.model.training.ExerciseParameters;
import com.synaptixfit.domain.model.training.Routine;
import com.synaptixfit.domain.model.training.RoutineDay;
import com.synaptixfit.domain.model.training.RoutineShareLink;
import com.synaptixfit.domain.model.training.RoutineWeek;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.model.training.WeekType;
import com.synaptixfit.domain.port.output.training.RoutineShareLinkRepositoryPort;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

/**
 * Compartir una rutina por enlace (ADR 0043): solo el dueño crea y revoca, se guarda la huella y no el token, el enlace
 * caduca, respeta el tope de enlaces vigentes y la copia es privada, sin progreso ni datos del dueño.
 */
class RoutineShareLinkServiceTest {

    private static final Instant NOW = Instant.parse("2026-11-15T10:00:00Z");
    private static final UUID OWNER = UUID.randomUUID();
    private static final UUID FRIEND = UUID.randomUUID();

    private final TrainingFakes.Routines routines = new TrainingFakes.Routines();
    private final List<RoutineShareLink> stored = new ArrayList<>();
    private final AtomicReference<Instant> clockNow = new AtomicReference<>(NOW);
    private Routine routine;
    private RoutineShareLinkService service;

    private final RoutineShareLinkRepositoryPort links = new RoutineShareLinkRepositoryPort() {
        public RoutineShareLink save(RoutineShareLink link) {
            stored.removeIf(l -> l.id().equals(link.id()));
            stored.add(link);
            return link;
        }
        public Optional<RoutineShareLink> findByTokenHash(String hash) {
            return stored.stream().filter(l -> l.tokenHash().equals(hash)).findFirst();
        }
        public void lockRoutine(UUID routineId) {
        }
        public List<RoutineShareLink> findActiveByRoutine(UUID routineId, Instant now) {
            return stored.stream().filter(l -> l.routineId().equals(routineId) && l.isActiveAt(now)).toList();
        }
        public int revokeAllOfRoutine(UUID routineId, Instant now) {
            List<RoutineShareLink> active = findActiveByRoutine(routineId, now);
            active.forEach(l -> save(new RoutineShareLink(l.id(), l.routineId(), l.ownerId(), l.tokenHash(),
                    l.createdAt(), l.expiresAt(), now)));
            return active.size();
        }
    };

    @BeforeEach
    void setUp() {
        Clock clock = new Clock() {
            public ZoneOffset getZone() { return ZoneOffset.UTC; }
            public Clock withZone(java.time.ZoneId zone) { return this; }
            public Instant instant() { return clockNow.get(); }
        };
        service = new RoutineShareLinkService(routines, links, event -> { }, clock);
        RoutineDay day = RoutineDay.create(1, "Torso");
        day.addExercise(TrainingFakes.strength("Press de banca", "Pectoral mayor").toRef(),
                new ExerciseParameters(3, 10, 90, 40.0, null, null, null, null));
        routine = routines.save(Routine.create(OWNER, "Mi rutina", "Tres días", Visibility.PRIVATE,
                TrainingGoal.HYPERTROPHY, null, null, List.of(RoutineWeek.create(1, null, WeekType.LOAD,
                        List.of(day))), NOW));
        routines.authors.put(OWNER, "Dueña");
    }

    @Test
    void ownerCreatesALinkThatStoresOnlyTheHashAndLasts30Days() {
        CreateRoutineShareLinkUseCase.Created created = service.createShareLink(OWNER, routine.id());

        assertThat(created.token()).hasSizeGreaterThanOrEqualTo(43);
        assertThat(created.expiresAt()).isEqualTo(NOW.plus(Duration.ofDays(30)));
        assertThat(stored).singleElement().satisfies(l -> {
            assertThat(l.tokenHash()).isEqualTo(RoutineShareLink.hash(created.token())).isNotEqualTo(created.token());
            assertThat(l.ownerId()).isEqualTo(OWNER);
        });
        assertThat(service.sharedUntil(OWNER, routine.id())).contains(created.expiresAt());
    }

    @Test
    void someoneElseCannotCreateOrSeeTheLinksOfARoutine() {
        assertThatThrownBy(() -> service.createShareLink(FRIEND, routine.id()))
                .isInstanceOf(RoutineNotFoundException.class);
        assertThatThrownBy(() -> service.sharedUntil(FRIEND, routine.id()))
                .isInstanceOf(RoutineNotFoundException.class);
    }

    @Test
    void aFriendWithTheLinkSeesAndCopiesAPrivateRoutineWithoutTheOwnerData() {
        String token = service.createShareLink(OWNER, routine.id()).token();

        assertThat(service.previewSharedRoutine(FRIEND, token).name()).isEqualTo("Mi rutina");
        Routine copy = service.copySharedRoutine(FRIEND, token);

        assertThat(copy.ownerId()).isEqualTo(FRIEND);
        assertThat(copy.name()).isEqualTo("Mi rutina");
        assertThat(copy.visibility()).isEqualTo(Visibility.PRIVATE);
        assertThat(copy.origin()).isNull();
        assertThat(copy.exerciseCount()).isEqualTo(1);
        assertThat(copy.completedDays()).isZero();
    }

    @Test
    void revokedExpiredOrUnknownLinksAllLookTheSame() {
        String token = service.createShareLink(OWNER, routine.id()).token();
        service.revokeShareLinks(OWNER, routine.id());
        assertThatThrownBy(() -> service.previewSharedRoutine(FRIEND, token))
                .isInstanceOf(RoutineShareLinkNotFoundException.class);
        assertThat(service.sharedUntil(OWNER, routine.id())).isEmpty();

        String fresh = service.createShareLink(OWNER, routine.id()).token();
        clockNow.set(NOW.plus(Duration.ofDays(31)));
        assertThatThrownBy(() -> service.copySharedRoutine(FRIEND, fresh))
                .isInstanceOf(RoutineShareLinkNotFoundException.class);

        assertThatThrownBy(() -> service.previewSharedRoutine(FRIEND, "inventado"))
                .isInstanceOf(RoutineShareLinkNotFoundException.class);
        assertThatThrownBy(() -> service.previewSharedRoutine(FRIEND, " "))
                .isInstanceOf(RoutineShareLinkNotFoundException.class);
    }

    @Test
    void aSilencedOwnerOrADeletedRoutineClosesTheLink() {
        String token = service.createShareLink(OWNER, routine.id()).token();
        routines.shadowbanned.add(OWNER);
        assertThatThrownBy(() -> service.previewSharedRoutine(FRIEND, token))
                .isInstanceOf(RoutineShareLinkNotFoundException.class);
        // El dueño sí puede abrir su propio enlace.
        assertThat(service.previewSharedRoutine(OWNER, token).id()).isEqualTo(routine.id());

        routines.shadowbanned.clear();
        routine.softDelete(NOW);
        assertThatThrownBy(() -> service.previewSharedRoutine(FRIEND, token))
                .isInstanceOf(RoutineShareLinkNotFoundException.class);
    }

    @Test
    void aRoutineHasAtMostFiveActiveLinks() {
        for (int i = 0; i < RoutineShareLink.MAX_ACTIVE_PER_ROUTINE; i++) {
            service.createShareLink(OWNER, routine.id());
        }
        assertThatThrownBy(() -> service.createShareLink(OWNER, routine.id()))
                .isInstanceOf(RoutineShareLinkLimitException.class)
                .hasFieldOrPropertyWithValue("code", "ROUTINE_SHARE_LINK_LIMIT");

        service.revokeShareLinks(OWNER, routine.id());
        assertThat(service.createShareLink(OWNER, routine.id()).token()).isNotBlank();
    }
}
