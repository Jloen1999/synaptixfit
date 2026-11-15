package com.synaptixfit.application.port.input.together;

import com.synaptixfit.domain.model.together.FriendStreak;
import com.synaptixfit.domain.model.together.Person;
import java.util.UUID;

/**
 * Una racha con un amigo tal como la ve una persona (ADR 0044): días seguidos, si cada uno ha hecho hoy su parte y
 * si se le puede recordar al amigo. {@code paused}: alguno de los dos tiene hoy la racha en pausa (sin decir quién
 * ni por qué).
 */
public record FriendStreakView(UUID id, FriendStreak.Status status, Person friend, boolean requestedByMe, int days,
                               boolean meDone, boolean friendDone, boolean paused, boolean canNudge) {
}
