package com.synaptixfit.domain.model.user;

import com.synaptixfit.domain.exception.user.InvalidBirthDateException;
import java.time.LocalDate;
import java.time.Month;
import java.time.MonthDay;
import java.time.Period;
import java.time.Year;
import java.util.Objects;

/**
 * Fecha de nacimiento de la cuenta (opcional, ADR 0036). La edad nunca se guarda: se calcula el día que hace falta
 * (kcal, propuestas de rutina, objetivos) y el cumpleaños se felicita con {@link #isBirthday}.
 *
 * <p>Reglas: no puede ser futura y la edad debe estar entre {@link #MIN_AGE} y {@link #MAX_AGE} (14 es la edad mínima
 * para consentir el tratamiento de datos en España, LOPDGDD art. 7; 100 descarta errores al teclear el año). Quien
 * nació el 29 de febrero cumple el 28 en los años no bisiestos.
 */
public record BirthDate(LocalDate value) {

    public static final int MIN_AGE = 14;
    public static final int MAX_AGE = 100;

    /**
     * Edad de referencia cuando no se sabe ni la fecha de nacimiento ni la edad que se dio antes: la típica de un
     * estudiante universitario (mediana del grado en España). Solo la usan las fórmulas; a la persona no se le muestra.
     */
    public static final int REFERENCE_AGE = 21;

    private static final MonthDay LEAP_DAY = MonthDay.of(Month.FEBRUARY, 29);

    public BirthDate {
        Objects.requireNonNull(value, "value");
    }

    /** Valida la fecha con el día de hoy de la persona. */
    public static BirthDate of(LocalDate value, LocalDate today) {
        Objects.requireNonNull(value, "value");
        if (value.isAfter(today)) {
            throw new InvalidBirthDateException("birth date is in the future");
        }
        int age = Period.between(value, today).getYears();
        if (age < MIN_AGE || age > MAX_AGE) {
            throw new InvalidBirthDateException("age must be between " + MIN_AGE + " and " + MAX_AGE);
        }
        return new BirthDate(value);
    }

    /** Años cumplidos el día {@code day}. */
    public int ageOn(LocalDate day) {
        int years = Period.between(value, day).getYears();
        // Period ya trata el 29 de febrero como cumplido el 1 de marzo; el cumpleaños se celebra el 28.
        if (isLeapDay() && !day.isLeapYear() && day.getMonth() == Month.FEBRUARY && day.getDayOfMonth() == 28
                && day.getYear() > value.getYear()) {
            years++;
        }
        return Math.max(0, years);
    }

    /** Día en que se celebra el cumpleaños el año {@code year} (28 de febrero si nació un 29 y el año no es bisiesto). */
    public LocalDate birthdayIn(int year) {
        if (isLeapDay() && !Year.isLeap(year)) {
            return LocalDate.of(year, Month.FEBRUARY, 28);
        }
        return value.withYear(year);
    }

    /** ¿Es {@code day} su cumpleaños? El mismo día de nacer no cuenta. */
    public boolean isBirthday(LocalDate day) {
        return day.getYear() > value.getYear() && birthdayIn(day.getYear()).equals(day);
    }

    private boolean isLeapDay() {
        return MonthDay.from(value).equals(LEAP_DAY);
    }

    /**
     * Edad para las fórmulas: la calculada si hay fecha de nacimiento; si no, la que la persona dio antes de existir
     * la fecha (perfil físico); si tampoco, {@link #REFERENCE_AGE}.
     */
    public static int effectiveAge(LocalDate birthDate, Integer declaredAge, LocalDate today) {
        Integer known = knownAge(birthDate, declaredAge, today);
        return known != null ? known : REFERENCE_AGE;
    }

    /** Edad que se sabe: la calculada con la fecha o la que se dio; {@code null} si no hay ninguna. */
    public static Integer knownAge(LocalDate birthDate, Integer declaredAge, LocalDate today) {
        if (birthDate != null && !birthDate.isAfter(today)) {
            return new BirthDate(birthDate).ageOn(today);
        }
        return declaredAge;
    }
}
