package com.synaptixfit.domain.model.user;

import com.synaptixfit.domain.exception.FieldValidationException;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.shared.Visibility;
import java.time.Instant;
import java.util.Locale;
import java.util.Objects;
import java.util.UUID;
import java.util.regex.Pattern;

/**
 * Cuenta de usuario y su progresión (nivel y experiencia).
 *
 * <p>Regla de progresión: completar el nivel {@code n} exige {@code 100 * n} puntos. La
 * experiencia sobrante pasa al nivel siguiente y, al restar, se puede bajar de nivel (nunca por
 * debajo de 1 ni con experiencia negativa).
 */
public final class User {

    private static final Pattern EMAIL = Pattern.compile("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$");

    private final UUID id;
    private String email;
    private String fullName;
    private String avatarUrl;
    private int level;
    private int levelXp;
    private int streak;
    private Visibility privacy;
    private Role role;
    private boolean shadowbanned;
    private String passwordHash;
    private String googleSubject;
    private UsageFocus usageFocus;
    private boolean onboardingCompleted;
    private final Instant createdAt;
    private Instant deletedAt;

    private User(Builder b) {
        this.id = Objects.requireNonNull(b.id, "id");
        this.email = normalizeEmail(b.email);
        this.fullName = Guard.length(b.fullName, "fullName", 2, 120);
        this.avatarUrl = b.avatarUrl;
        this.level = Math.max(1, b.level);
        this.levelXp = Math.max(0, b.levelXp);
        this.streak = Math.max(0, b.streak);
        this.privacy = b.privacy == null ? Visibility.PRIVATE : b.privacy;
        this.role = b.role == null ? Role.USER : b.role;
        this.shadowbanned = b.shadowbanned;
        this.passwordHash = b.passwordHash;
        this.googleSubject = b.googleSubject;
        this.usageFocus = b.usageFocus;
        this.onboardingCompleted = b.onboardingCompleted;
        this.createdAt = b.createdAt == null ? Instant.now() : b.createdAt;
        this.deletedAt = b.deletedAt;
        if (passwordHash == null && googleSubject == null && deletedAt == null) {
            throw new FieldValidationException("credentials", "REQUIRED",
                    "a password or a Google identity is required");
        }
    }

    public static Builder builder() {
        return new Builder();
    }

    /** Puntos necesarios para completar el nivel indicado. */
    public static int thresholdFor(int level) {
        return 100 * level;
    }

    public static String normalizeEmail(String email) {
        String value = Guard.notBlank(email, "email").toLowerCase(Locale.ROOT);
        if (!EMAIL.matcher(value).matches()) {
            throw new FieldValidationException("email", "INVALID_FORMAT", "email has an invalid format");
        }
        return value;
    }

    /** Suma experiencia. Las cantidades no positivas no tienen efecto. */
    public ExperienceChange gainExperience(int amount) {
        if (amount <= 0) {
            return new ExperienceChange(level, levelXp, 0, 0);
        }
        int startLevel = level;
        levelXp += amount;
        while (levelXp >= thresholdFor(level)) {
            levelXp -= thresholdFor(level);
            level++;
        }
        return new ExperienceChange(level, levelXp, level - startLevel, amount);
    }

    /** Resta experiencia bajando de nivel si hace falta. Las cantidades no positivas no tienen efecto. */
    public ExperienceChange loseExperience(int amount) {
        if (amount <= 0) {
            return new ExperienceChange(level, levelXp, 0, 0);
        }
        int startLevel = level;
        int remaining = levelXp - amount;
        while (remaining < 0 && level > 1) {
            level--;
            remaining += thresholdFor(level);
        }
        levelXp = Math.max(0, remaining);
        return new ExperienceChange(level, levelXp, level - startLevel, -amount);
    }

    public void rename(String newFullName) {
        this.fullName = Guard.length(newFullName, "fullName", 2, 120);
    }

    public void changeEmail(String newEmail) {
        this.email = normalizeEmail(newEmail);
    }

    public void changeAvatar(String newAvatarUrl) {
        this.avatarUrl = newAvatarUrl;
    }

    public void changePrivacy(Visibility newPrivacy) {
        this.privacy = Guard.notNull(newPrivacy, "privacy");
    }

    public void changePasswordHash(String newPasswordHash) {
        this.passwordHash = Guard.notBlank(newPasswordHash, "password");
    }

    public void linkGoogle(String subject) {
        this.googleSubject = Guard.notBlank(subject, "googleSubject");
    }

    /** Elige o cambia para qué usa la app (estudios, deporte o ambos). */
    public void chooseFocus(UsageFocus focus) {
        this.usageFocus = Guard.notNull(focus, "usageFocus");
    }

    /** Marca el onboarding como cerrado por el usuario. */
    public void completeOnboarding() {
        this.onboardingCompleted = true;
    }

    public void updateStreak(int newStreak) {
        this.streak = Math.max(0, newStreak);
    }

    public void changeRole(Role newRole) {
        this.role = Guard.notNull(newRole, "role");
    }

    public void setShadowbanned(boolean value) {
        this.shadowbanned = value;
    }

    /** Fija nivel y experiencia directamente (operación administrativa). */
    public void resetProgress(int newLevel, int newLevelXp) {
        this.level = Math.max(1, newLevel);
        this.levelXp = Math.max(0, Math.min(newLevelXp, thresholdFor(this.level) - 1));
    }

    /** Anonimiza la cuenta (RGPD): borra datos personales y credenciales. */
    public void anonymize(Instant when) {
        this.email = "deleted+" + id + "@synaptixfit.invalid";
        this.fullName = "Usuario eliminado";
        this.avatarUrl = null;
        this.passwordHash = null;
        this.googleSubject = null;
        this.privacy = Visibility.PRIVATE;
        this.deletedAt = Objects.requireNonNull(when);
    }

    public boolean isAdmin() {
        return role == Role.ADMIN;
    }

    public boolean isActive() {
        return deletedAt == null;
    }

    public boolean hasPassword() {
        return passwordHash != null;
    }

    /** Enfoque con el que se filtra el contenido: sin elegir equivale a ambos (la app completa). */
    public UsageFocus effectiveFocus() {
        return usageFocus == null ? UsageFocus.BOTH : usageFocus;
    }

    public boolean focusChosen() {
        return usageFocus != null;
    }

    public UUID id() { return id; }
    public String email() { return email; }
    public String fullName() { return fullName; }
    public String avatarUrl() { return avatarUrl; }
    public int level() { return level; }
    public int levelXp() { return levelXp; }
    public int levelThreshold() { return thresholdFor(level); }
    public int streak() { return streak; }
    public Visibility privacy() { return privacy; }
    public Role role() { return role; }
    public boolean shadowbanned() { return shadowbanned; }
    public String passwordHash() { return passwordHash; }
    public String googleSubject() { return googleSubject; }
    public UsageFocus usageFocus() { return usageFocus; }
    public boolean onboardingCompleted() { return onboardingCompleted; }
    public Instant createdAt() { return createdAt; }
    public Instant deletedAt() { return deletedAt; }

    /** Constructor fluido para crear o reconstruir el usuario. */
    public static final class Builder {
        private UUID id;
        private String email;
        private String fullName;
        private String avatarUrl;
        private int level = 1;
        private int levelXp;
        private int streak;
        private Visibility privacy;
        private Role role;
        private boolean shadowbanned;
        private String passwordHash;
        private String googleSubject;
        private UsageFocus usageFocus;
        private boolean onboardingCompleted;
        private Instant createdAt;
        private Instant deletedAt;

        public Builder id(UUID v) { this.id = v; return this; }
        public Builder email(String v) { this.email = v; return this; }
        public Builder fullName(String v) { this.fullName = v; return this; }
        public Builder avatarUrl(String v) { this.avatarUrl = v; return this; }
        public Builder level(int v) { this.level = v; return this; }
        public Builder levelXp(int v) { this.levelXp = v; return this; }
        public Builder streak(int v) { this.streak = v; return this; }
        public Builder privacy(Visibility v) { this.privacy = v; return this; }
        public Builder role(Role v) { this.role = v; return this; }
        public Builder shadowbanned(boolean v) { this.shadowbanned = v; return this; }
        public Builder passwordHash(String v) { this.passwordHash = v; return this; }
        public Builder googleSubject(String v) { this.googleSubject = v; return this; }
        public Builder usageFocus(UsageFocus v) { this.usageFocus = v; return this; }
        public Builder onboardingCompleted(boolean v) { this.onboardingCompleted = v; return this; }
        public Builder createdAt(Instant v) { this.createdAt = v; return this; }
        public Builder deletedAt(Instant v) { this.deletedAt = v; return this; }

        public User build() {
            return new User(this);
        }
    }
}
