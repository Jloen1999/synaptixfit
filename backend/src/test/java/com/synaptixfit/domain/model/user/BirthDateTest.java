package com.synaptixfit.domain.model.user;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.synaptixfit.domain.exception.user.InvalidBirthDateException;
import java.time.LocalDate;
import org.junit.jupiter.api.Test;

/** Reglas de la fecha de nacimiento (ADR 0036): validación, edad calculada y cumpleaños. */
class BirthDateTest {

    private static final LocalDate TODAY = LocalDate.of(2026, 11, 7);

    @Test
    void rejectsFutureDatesAndUnreasonableAges() {
        assertThatThrownBy(() -> BirthDate.of(TODAY.plusDays(1), TODAY))
                .isInstanceOf(InvalidBirthDateException.class)
                .extracting("code").isEqualTo("INVALID_BIRTH_DATE");
        assertThatThrownBy(() -> BirthDate.of(LocalDate.of(2013, 1, 1), TODAY))
                .isInstanceOf(InvalidBirthDateException.class);
        assertThatThrownBy(() -> BirthDate.of(LocalDate.of(1920, 1, 1), TODAY))
                .isInstanceOf(InvalidBirthDateException.class);
        assertThat(BirthDate.of(LocalDate.of(2005, 3, 4), TODAY).value()).isEqualTo(LocalDate.of(2005, 3, 4));
        assertThat(BirthDate.of(TODAY.minusYears(BirthDate.MIN_AGE), TODAY)).isNotNull();
    }

    @Test
    void ageCountsCompletedYears() {
        BirthDate date = new BirthDate(LocalDate.of(2004, 11, 8));
        assertThat(date.ageOn(TODAY)).isEqualTo(21);
        assertThat(date.ageOn(TODAY.plusDays(1))).isEqualTo(22);
    }

    @Test
    void leapDayBirthdaysAreCelebratedOnThe28thInCommonYears() {
        BirthDate leap = new BirthDate(LocalDate.of(2004, 2, 29));
        assertThat(leap.birthdayIn(2027)).isEqualTo(LocalDate.of(2027, 2, 28));
        assertThat(leap.birthdayIn(2028)).isEqualTo(LocalDate.of(2028, 2, 29));
        assertThat(leap.isBirthday(LocalDate.of(2027, 2, 28))).isTrue();
        assertThat(leap.isBirthday(LocalDate.of(2028, 2, 28))).isFalse();
        assertThat(leap.ageOn(LocalDate.of(2027, 2, 28))).isEqualTo(23);
        assertThat(leap.ageOn(LocalDate.of(2027, 2, 27))).isEqualTo(22);
        assertThat(leap.ageOn(LocalDate.of(2028, 2, 28))).isEqualTo(23);
        assertThat(leap.ageOn(LocalDate.of(2028, 2, 29))).isEqualTo(24);
    }

    @Test
    void theDayOfBirthIsNotABirthday() {
        BirthDate date = new BirthDate(TODAY);
        assertThat(date.isBirthday(TODAY)).isFalse();
        assertThat(date.isBirthday(TODAY.plusYears(1))).isTrue();
    }

    @Test
    void effectiveAgePrefersTheBirthDateThenTheDeclaredAgeThenTheReference() {
        assertThat(BirthDate.effectiveAge(LocalDate.of(2000, 1, 1), 40, TODAY)).isEqualTo(26);
        assertThat(BirthDate.effectiveAge(null, 40, TODAY)).isEqualTo(40);
        assertThat(BirthDate.effectiveAge(null, null, TODAY)).isEqualTo(BirthDate.REFERENCE_AGE);
    }

    @Test
    void anonymizingTheAccountErasesTheBirthDate() {
        User user = User.builder().id(java.util.UUID.randomUUID()).email("ana@uni.es").fullName("Ana")
                .passwordHash("h").build();
        user.changeBirthDate(LocalDate.of(2004, 5, 6), TODAY);
        assertThat(user.ageOn(TODAY)).isEqualTo(22);
        assertThat(user.hasBirthdayOn(LocalDate.of(2027, 5, 6))).isTrue();

        user.anonymize(java.time.Instant.parse("2026-11-07T10:00:00Z"));

        assertThat(user.birthDate()).isNull();
        assertThat(user.ageOn(TODAY)).isNull();
    }
}
