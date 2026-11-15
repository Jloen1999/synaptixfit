package com.synaptixfit.domain.model.together;

/**
 * Duración de cada ronda de «Estudiamos juntos» (ADR 0045): concentración y el descanso que le sigue. Son los dos
 * Pomodoros de siempre (25 + 5 y 50 + 10); no se admiten otras duraciones para que la sala sea fácil de entender.
 */
public enum StudyRoomLength {
    SHORT(25, 5),
    LONG(50, 10);

    private final int focusMinutes;
    private final int breakMinutes;

    StudyRoomLength(int focusMinutes, int breakMinutes) {
        this.focusMinutes = focusMinutes;
        this.breakMinutes = breakMinutes;
    }

    public int focusMinutes() {
        return focusMinutes;
    }

    public int breakMinutes() {
        return breakMinutes;
    }
}
