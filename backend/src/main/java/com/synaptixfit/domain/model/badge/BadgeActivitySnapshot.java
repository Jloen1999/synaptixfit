package com.synaptixfit.domain.model.badge;

import com.synaptixfit.domain.model.social.PostType;
import java.time.LocalDate;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;

/**
 * Datos de actividad del usuario (de varios módulos) con los que se calculan las métricas de las
 * insignias. Las fechas ya están en la zona horaria del usuario.
 */
public record BadgeActivitySnapshot(int sessionsCompleted, int highRpeSessions, Set<LocalDate> sessionDays,
                                    Set<LocalDate> checkInDays, int studyBlocksCompleted, int studyPlans,
                                    int notesCreated, int feedPosts, int likesReceived, int challengesCompleted,
                                    List<WeeklyStudyLoad> weeklyStudyLoads) {

    /**
     * RPE desde el que una sesión cuenta como de alto esfuerzo ({@code highRpeSessions}): en la escala
     * CR-10 de Borg, 8 ya es «muy duro».
     */
    public static final int HIGH_RPE_MIN = 8;

    /**
     * Publicaciones automáticas que no cuentan en {@code feedPosts}: si contaran, cada insignia
     * «publicada» acercaría a la insignia de publicaciones sin publicar nada.
     */
    public static final Set<PostType> AUTOMATIC_POSTS = EnumSet.of(PostType.CHALLENGE_COMPLETED, PostType.BADGE_UNLOCKED);

    public BadgeActivitySnapshot {
        sessionDays = Set.copyOf(sessionDays);
        checkInDays = Set.copyOf(checkInDays);
        weeklyStudyLoads = List.copyOf(weeklyStudyLoads);
    }
}
