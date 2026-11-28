package com.synaptixfit.domain.model.wod;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.exception.InvalidInputException;
import java.time.Instant;
import java.time.LocalDate;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Reglas de la pizarra de un WOD por formato, su huella y qué marca es mejor (ADR 0069). */
class WodModelTest {

    private static final Instant AT = Instant.parse("2026-11-28T10:00:00Z");
    private static final List<WodMovement> SQUATS = List.of(new WodMovement(null, "Sentadillas", 10, null, null, null));

    private static WodResult result(WodScoreType type, int value, Integer extra, boolean capped, int secondsLater) {
        return new WodResult(UUID.randomUUID(), UUID.randomUUID(), UUID.randomUUID(), WodDivision.RX, type, value,
                extra, capped, 600, null, AT.plusSeconds(secondsLater));
    }

    @Test
    void eachFormatAppliesItsOwnRules() {
        assertThat(new WodDefinition(" Mi WOD ", " ", WodFormat.FOR_TIME, null, null, SQUATS))
                .satisfies(d -> {
                    assertThat(d.title()).isEqualTo("Mi WOD");
                    assertThat(d.strength()).isNull();
                    assertThat(d.rounds()).isEqualTo(1);
                    assertThat(d.timeCapSeconds()).isNull();
                });
        assertThat(new WodDefinition(null, null, WodFormat.AMRAP, 720, 5, SQUATS).rounds()).isNull();
        assertThat(new WodDefinition(null, null, WodFormat.EMOM, 600, null, SQUATS).rounds()).isEqualTo(10);
        assertThat(new WodDefinition(null, null, WodFormat.TABATA, 999, 3, SQUATS))
                .satisfies(d -> {
                    assertThat(d.timeCapSeconds()).isEqualTo(240);
                    assertThat(d.rounds()).isEqualTo(8);
                });
    }

    @Test
    void aBoardThatBreaksItsFormatIsRejected() {
        assertThatThrownBy(() -> new WodDefinition(null, null, WodFormat.AMRAP, null, null, SQUATS))
                .isInstanceOf(InvalidInputException.class);
        assertThatThrownBy(() -> new WodDefinition(null, null, WodFormat.EMOM, 630, null, SQUATS))
                .isInstanceOf(FieldValidationException.class);
        assertThatThrownBy(() -> new WodDefinition(null, null, WodFormat.FOR_TIME, 30, 1, SQUATS))
                .isInstanceOf(InvalidInputException.class);
        assertThatThrownBy(() -> new WodDefinition(null, null, WodFormat.FOR_TIME, null, 1, List.of()))
                .isInstanceOf(FieldValidationException.class);
        assertThatThrownBy(() -> new WodMovement(null, "  ", 10, WodUnit.REPS, null, null))
                .isInstanceOf(FieldValidationException.class);
    }

    @Test
    void theSignatureIgnoresTitleAccentsAndCaseButNotWhatIsDone() {
        WodDefinition a = new WodDefinition("Lunes", null, WodFormat.AMRAP, 720, null,
                List.of(new WodMovement(null, "Zancadas  atrás", 20, WodUnit.REPS, null, null)));
        WodDefinition b = new WodDefinition("Otro nombre", "5x5 sentadilla", WodFormat.AMRAP, 720, null,
                List.of(new WodMovement(null, "zancadas ATRAS", 20, WodUnit.REPS, null, null)));
        WodDefinition more = new WodDefinition("Lunes", null, WodFormat.AMRAP, 720, null,
                List.of(new WodMovement(null, "Zancadas atrás", 30, WodUnit.REPS, null, null)));

        assertThat(a.signature()).isEqualTo(b.signature());
        assertThat(a.signature()).isNotEqualTo(more.signature());
    }

    @Test
    void theFormatSaysHowItIsScored() {
        assertThat(WodFormat.FOR_TIME.scoreType(false)).isEqualTo(WodScoreType.TIME);
        assertThat(WodFormat.FOR_TIME.scoreType(true)).isEqualTo(WodScoreType.REPS);
        assertThat(WodFormat.AMRAP.scoreType(false)).isEqualTo(WodScoreType.ROUNDS_REPS);
        assertThat(WodFormat.EMOM.scoreType(false)).isEqualTo(WodScoreType.REPS);
        assertThat(WodFormat.TABATA.scoreType(false)).isEqualTo(WodScoreType.REPS);
    }

    @Test
    void theBestMarkIsTheFastestOrTheOneWithMoreWork() {
        WodResult slow = result(WodScoreType.TIME, 600, null, false, 0);
        WodResult fast = result(WodScoreType.TIME, 540, null, false, 10);
        WodResult capped = result(WodScoreType.REPS, 140, null, true, 20);
        assertThat(WodResult.best(List.of(slow, capped, fast))).contains(fast);
        // Quedarse en el límite nunca gana a terminar, por muchas repeticiones que lleve.
        assertThat(WodResult.best(List.of(capped, slow))).contains(slow);

        WodResult five = result(WodScoreType.ROUNDS_REPS, 5, 3, false, 0);
        WodResult fiveMore = result(WodScoreType.ROUNDS_REPS, 5, 12, false, 10);
        WodResult four = result(WodScoreType.ROUNDS_REPS, 4, 29, false, 20);
        assertThat(WodResult.best(List.of(five, four, fiveMore))).contains(fiveMore);

        // A igualdad se queda la primera; la carga de la fuerza no compite.
        WodResult same = result(WodScoreType.TIME, 540, null, false, 30);
        WodResult load = result(WodScoreType.LOAD, 80, null, false, 40);
        assertThat(WodResult.best(List.of(same, fast, load))).contains(fast);
        assertThat(WodResult.best(List.of(load))).isEmpty();
    }

    @Test
    void aResultKeepsOnlyWhatItsTypeAllows() {
        assertThat(result(WodScoreType.TIME, 300, 9, false, 0).extraReps()).isNull();
        assertThat(result(WodScoreType.ROUNDS_REPS, 4, null, false, 0).extraReps()).isZero();
        assertThatThrownBy(() -> result(WodScoreType.TIME, 0, null, false, 0))
                .isInstanceOf(InvalidInputException.class);
        assertThatThrownBy(() -> result(WodScoreType.TIME, 300, null, true, 0))
                .isInstanceOf(FieldValidationException.class);
    }

    @Test
    void thereAreEnoughDistinctExampleWodsAndOnePerDay() {
        Set<String> codes = new HashSet<>();
        Set<String> signatures = new HashSet<>();
        for (WodTemplates.Template t : WodTemplates.ALL) {
            codes.add(t.code());
            signatures.add(t.definition().signature());
            assertThat(t.definition().timeCapSeconds()).isBetween(240, 1200);
        }
        assertThat(codes).hasSizeBetween(6, 8).hasSameSizeAs(WodTemplates.ALL);
        assertThat(signatures).hasSameSizeAs(WodTemplates.ALL);

        LocalDate day = LocalDate.of(2026, 11, 28);
        assertThat(WodTemplates.ofDay(day)).isEqualTo(WodTemplates.ofDay(day));
        assertThat(WodTemplates.ofDay(day)).isNotEqualTo(WodTemplates.ofDay(day.plusDays(1)));
    }

    @Test
    void changingWhatIsDoneStopsBeingTheTemplate() {
        WodTemplates.Template template = WodTemplates.ALL.get(0);
        Wod wod = new Wod(UUID.randomUUID(), UUID.randomUUID(), LocalDate.of(2026, 11, 28), template.code(),
                template.definition(), AT, AT);

        assertThat(wod.changed(null, template.definition().titled("Tres dieces"), AT).templateCode())
                .isEqualTo(template.code());
        assertThat(wod.changed(null, new WodDefinition(null, null, WodFormat.FOR_TIME, null, 2, SQUATS), AT)
                .templateCode()).isNull();
    }
}
