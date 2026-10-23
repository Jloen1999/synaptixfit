package com.synaptixfit.domain.model.user;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.FieldValidationException;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class UserTest {

    private static User user(int level, int levelXp) {
        return User.builder().id(UUID.randomUUID()).email("Ana@Example.com").fullName("Ana")
                .passwordHash("hash").level(level).levelXp(levelXp).build();
    }

    @Test
    void normalizesEmail() {
        assertThat(user(1, 0).email()).isEqualTo("ana@example.com");
    }

    @Test
    void rejectsInvalidEmail() {
        assertThatThrownBy(() -> User.builder().id(UUID.randomUUID()).email("no-at").fullName("Ana")
                .passwordHash("h").build()).isInstanceOf(FieldValidationException.class);
    }

    @Test
    void requiresSomeCredential() {
        assertThatThrownBy(() -> User.builder().id(UUID.randomUUID()).email("a@b.co").fullName("Ana").build())
                .isInstanceOf(FieldValidationException.class);
    }

    @Test
    void gainCarriesOverflowAcrossSeveralLevels() {
        User u = user(1, 50);
        // Nivel 1 necesita 100, nivel 2 necesita 200: 50 + 300 = 350 → completa 1 (100) y 2 (200), sobran 50.
        ExperienceChange change = u.gainExperience(300);
        assertThat(change.level()).isEqualTo(3);
        assertThat(change.levelXp()).isEqualTo(50);
        assertThat(change.levelUps()).isEqualTo(2);
        assertThat(change.leveledUp()).isTrue();
    }

    @Test
    void gainBelowThresholdKeepsLevel() {
        ExperienceChange change = user(2, 10).gainExperience(20);
        assertThat(change.level()).isEqualTo(2);
        assertThat(change.levelXp()).isEqualTo(30);
        assertThat(change.leveledUp()).isFalse();
    }

    @Test
    void nonPositiveAmountsAreIgnored() {
        User u = user(2, 10);
        assertThat(u.gainExperience(0).xpDelta()).isZero();
        assertThat(u.loseExperience(-5).xpDelta()).isZero();
        assertThat(u.levelXp()).isEqualTo(10);
    }

    @Test
    void loseDropsLevelsWithCarry() {
        User u = user(3, 20);
        // 20 - 150 = -130 → baja a nivel 2 (+200) = 70.
        ExperienceChange change = u.loseExperience(150);
        assertThat(change.level()).isEqualTo(2);
        assertThat(change.levelXp()).isEqualTo(70);
        assertThat(change.levelUps()).isEqualTo(-1);
    }

    @Test
    void loseNeverGoesBelowLevelOneOrZeroXp() {
        ExperienceChange change = user(1, 30).loseExperience(500);
        assertThat(change.level()).isEqualTo(1);
        assertThat(change.levelXp()).isZero();
    }
}
