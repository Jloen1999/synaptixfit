package com.synaptixfit.infrastructure.adapter.output.persistence.mapper;

import com.synaptixfit.domain.model.user.Role;
import com.synaptixfit.domain.model.user.UsageFocus;
import com.synaptixfit.domain.model.user.User;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.UserEntity;

/** Usuario de dominio ↔ {@link UserEntity}. */
public final class UserPersistenceMapper {

    private UserPersistenceMapper() {
    }

    public static User toDomain(UserEntity e) {
        return User.builder()
                .id(e.getId())
                .email(e.getEmail())
                .fullName(e.getNombreCompleto())
                .avatarUrl(e.getUrlAvatar())
                .level(e.getNivel())
                .levelXp(e.getXpNivelActual())
                .streak(e.getRachaActual())
                .privacy(VisibilityDbMapper.toDomain(e.getNivelPrivacidad()))
                .role("admin".equals(e.getRol()) ? Role.ADMIN : Role.USER)
                .shadowbanned(e.isShadowbanned())
                .passwordHash(e.getPasswordHash())
                .googleSubject(e.getGoogleSub())
                .usageFocus(focusToDomain(e.getEnfoque()))
                .birthDate(e.getFechaNacimiento())
                .onboardingCompleted(e.isOnboardingCompletado())
                .createdAt(e.getCreadoEn())
                .deletedAt(e.getEliminadoEn())
                .build();
    }

    public static void copyToEntity(User u, UserEntity e) {
        e.setId(u.id());
        e.setEmail(u.email());
        e.setNombreCompleto(u.fullName());
        e.setUrlAvatar(u.avatarUrl());
        e.setNivel(u.level());
        e.setXpNivelActual(u.levelXp());
        e.setRachaActual(u.streak());
        e.setNivelPrivacidad(VisibilityDbMapper.toDb(u.privacy()));
        e.setRol(u.role() == Role.ADMIN ? "admin" : "usuario");
        e.setShadowbanned(u.shadowbanned());
        e.setPasswordHash(u.passwordHash());
        e.setGoogleSub(u.googleSubject());
        e.setEnfoque(focusToDb(u.usageFocus()));
        e.setFechaNacimiento(u.birthDate());
        e.setOnboardingCompletado(u.onboardingCompleted());
        e.setCreadoEn(u.createdAt());
        e.setEliminadoEn(u.deletedAt());
    }

    /** En la base de datos el enfoque se guarda en español: 'academico', 'deporte' o 'ambos'. */
    static UsageFocus focusToDomain(String value) {
        if (value == null) {
            return null;
        }
        return switch (value) {
            case "academico" -> UsageFocus.ACADEMIC;
            case "deporte" -> UsageFocus.FITNESS;
            default -> UsageFocus.BOTH;
        };
    }

    static String focusToDb(UsageFocus focus) {
        if (focus == null) {
            return null;
        }
        return switch (focus) {
            case ACADEMIC -> "academico";
            case FITNESS -> "deporte";
            case BOTH -> "ambos";
        };
    }
}
