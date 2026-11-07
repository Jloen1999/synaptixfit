package com.synaptixfit.application.service.challenge;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.challenge.ChallengeLinkNotFoundException;
import com.synaptixfit.domain.exception.challenge.ChallengeRoutineDayNotLinkableException;
import com.synaptixfit.domain.model.challenge.ChallengeLink;
import com.synaptixfit.domain.model.challenge.LinkType;
import com.synaptixfit.domain.model.challenge.RoutineDayTarget;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Tareas vinculadas a un día de rutina (ADR 0032): días ofrecidos y comprobación de propiedad. */
class RoutineDayLinkTest {

    private final ChallengeFixtures f = new ChallengeFixtures();

    @Test
    void offersOnlyTrainableDaysThatAreStillPending() {
        RoutineDayTarget pending = new RoutineDayTarget(UUID.randomUUID(), "Fuerza", 1, 1, null, false, true);
        RoutineDayTarget done = new RoutineDayTarget(UUID.randomUUID(), "Fuerza", 1, 3, null, true, true);
        RoutineDayTarget empty = new RoutineDayTarget(UUID.randomUUID(), "Fuerza", 1, 5, null, false, false);
        f.routineDays.add(pending);
        f.routineDays.add(done);
        f.routineDays.add(empty);

        assertThat(new RoutineDayLinkTargetService(f.references).routineDayTargets(UUID.randomUUID()))
                .containsExactly(pending);
    }

    @Test
    void aRoutineDayLinkMustBelongToTheUser() {
        ChallengeReferenceValidator validator = new ChallengeReferenceValidator(f.references);
        UUID mine = UUID.randomUUID();
        f.ownedRefs.add(mine);
        f.routineDays.add(new RoutineDayTarget(mine, "Fuerza", 1, 1, null, false, true));

        assertThatCode(() -> validator.checkLink(UUID.randomUUID(), new ChallengeLink(LinkType.ROUTINE_DAY, mine)))
                .doesNotThrowAnyException();
        assertThatThrownBy(() -> validator.checkLink(UUID.randomUUID(),
                new ChallengeLink(LinkType.ROUTINE_DAY, UUID.randomUUID())))
                .isInstanceOf(ChallengeLinkNotFoundException.class);
    }

    @Test
    void aRoutineDayThatIsDoneOrOutsideTheCurrentRoutineCannotBeLinked() {
        ChallengeReferenceValidator validator = new ChallengeReferenceValidator(f.references);
        UUID done = UUID.randomUUID();
        UUID otherRoutine = UUID.randomUUID();
        f.ownedRefs.add(done);
        f.ownedRefs.add(otherRoutine);
        f.routineDays.add(new RoutineDayTarget(done, "Fuerza", 1, 3, null, true, true));

        assertThatThrownBy(() -> validator.checkLink(UUID.randomUUID(), new ChallengeLink(LinkType.ROUTINE_DAY, done)))
                .isInstanceOf(ChallengeRoutineDayNotLinkableException.class);
        assertThatThrownBy(() -> validator.checkLink(UUID.randomUUID(),
                new ChallengeLink(LinkType.ROUTINE_DAY, otherRoutine)))
                .isInstanceOf(ChallengeRoutineDayNotLinkableException.class);
    }
}
