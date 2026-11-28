package com.synaptixfit.domain.model.planner;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.FieldValidationException;
import java.time.Duration;
import java.time.Instant;
import org.junit.jupiter.api.Test;

class SportDetailsTest {

    private static final Instant YESTERDAY = Instant.parse("2026-11-27T17:00:00Z").minus(Duration.ofDays(1));

    @Test
    void aMatchSportDefaultsToMatchAndKeepsResultAndScore() {
        SportDetails padel = new SportDetails(Sport.PADEL, "se ignora", null, MatchResult.WIN, " 6-4 6-3 ");

        assertThat(padel.mode()).isEqualTo(SportMode.MATCH);
        assertThat(padel.result()).isEqualTo(MatchResult.WIN);
        assertThat(padel.scoreText()).isEqualTo("6-4 6-3");
        assertThat(padel.name()).isNull();
    }

    @Test
    void aTrainingHasNoResultNorScore() {
        SportDetails training = new SportDetails(Sport.FOOTBALL, null, SportMode.TRAINING, MatchResult.LOSS, "0-3");

        assertThat(training.result()).isNull();
        assertThat(training.scoreText()).isNull();
    }

    @Test
    void otherSportNormalizesItsNameAndHasNoMode() {
        SportDetails other = new SportDetails(Sport.OTHER, "  tiro   con arco ", SportMode.MATCH, MatchResult.WIN, "1");

        assertThat(other.name()).isEqualTo("tiro con arco");
        assertThat(other.mode()).isNull();
        assertThat(other.result()).isNull();
        assertThat(new SportDetails(Sport.OTHER, "x".repeat(60), null, null, null).name()).hasSize(40);
    }

    @Test
    void aTooLongScoreIsRejected() {
        assertThatThrownBy(() -> new SportDetails(Sport.TENNIS, null, SportMode.MATCH, null, "1".repeat(21)))
                .isInstanceOf(FieldValidationException.class);
    }

    @Test
    void theLegacyKindNamesItsSportAndAMatchIsReadFromItsTitle() {
        assertThat(Sport.fromLegacy(ActivityKind.RUN, "Rodaje")).isEqualTo(Sport.RUN);
        assertThat(Sport.fromLegacy(ActivityKind.SWIM, null)).isEqualTo(Sport.SWIM);
        assertThat(Sport.fromLegacy(ActivityKind.MATCH, "FÚTBOL sala")).isEqualTo(Sport.FOOTBALL);
        assertThat(Sport.fromLegacy(ActivityKind.MATCH, "Pádel con Ana")).isEqualTo(Sport.PADEL);
        assertThat(Sport.fromLegacy(ActivityKind.MATCH, "Basket")).isEqualTo(Sport.BASKETBALL);
        assertThat(Sport.fromLegacy(ActivityKind.MATCH, "Tenis")).isEqualTo(Sport.TENNIS);
        assertThat(Sport.fromLegacy(ActivityKind.MATCH, "Vóley playa")).isEqualTo(Sport.VOLLEYBALL);
        assertThat(Sport.fromLegacy(ActivityKind.MATCH, "Rugby")).isEqualTo(Sport.OTHER);
        assertThat(Sport.fromLegacy(ActivityKind.OTHER, "Fútbol")).isEqualTo(Sport.OTHER);
        assertThat(Sport.fromLegacy(null, null)).isEqualTo(Sport.OTHER);
    }

    @Test
    void anOldAppKeepsItsKindAndGetsASport() {
        PastActivity rugby = new PastActivity(YESTERDAY, 60, "Rugby", 6, ActivityType.SPORT, null,
                ActivityKind.MATCH, null);

        // La app de antes vuelve a leer MATCH aunque el deporte no esté en el catálogo.
        assertThat(rugby.kind()).isEqualTo(ActivityKind.MATCH);
        assertThat(rugby.sport().sport()).isEqualTo(Sport.OTHER);
        assertThat(rugby.sport().name()).isEqualTo("Rugby");
    }

    @Test
    void theSportDecidesTheLegacyKindAndTheDistance() {
        PastActivity swim = new PastActivity(YESTERDAY, 40, "Natación", 5, ActivityType.SPORT, null, null, 1500,
                ActivitySource.MANUAL, SportDetails.of(Sport.SWIM));
        PastActivity tennis = new PastActivity(YESTERDAY, 60, "Tenis", 5, ActivityType.SPORT, null, ActivityKind.RUN,
                1500, ActivitySource.MANUAL, SportDetails.of(Sport.TENNIS));
        PastActivity climbing = new PastActivity(YESTERDAY, 60, null, 5, ActivityType.SPORT, null, null, null,
                ActivitySource.MANUAL, new SportDetails(Sport.OTHER, "Escalada", null, null, null));

        assertThat(swim.kind()).isEqualTo(ActivityKind.SWIM);
        assertThat(swim.distanceMeters()).isEqualTo(1500);
        assertThat(tennis.kind()).isEqualTo(ActivityKind.MATCH);
        assertThat(tennis.distanceMeters()).isNull();
        assertThat(climbing.title()).isEqualTo("Escalada");
    }

    @Test
    void studyHasNoSport() {
        PastActivity study = new PastActivity(YESTERDAY, 60, "Tema 3", null, ActivityType.STUDY, null, null, null,
                ActivitySource.MANUAL, SportDetails.of(Sport.RUN));

        assertThat(study.sport()).isNull();
    }
}
