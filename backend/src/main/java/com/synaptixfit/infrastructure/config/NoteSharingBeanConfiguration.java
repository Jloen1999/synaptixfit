package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.academic.ExportNotePdfUseCase;
import com.synaptixfit.application.port.input.academic.GetNoteUseCase;
import com.synaptixfit.application.port.input.academic.GetSubjectDocumentAvailabilityUseCase;
import com.synaptixfit.application.port.input.academic.RevokeNoteRecipientsUseCase;
import com.synaptixfit.application.port.input.academic.SendNoteToFriendUseCase;
import com.synaptixfit.application.port.input.academic.ShareNoteOnWallUseCase;
import com.synaptixfit.application.port.input.notification.CreateNotificationUseCase;
import com.synaptixfit.application.port.input.social.PublishAchievementPostUseCase;
import com.synaptixfit.application.service.academic.NotePdfExportService;
import com.synaptixfit.application.service.academic.NoteSharingService;
import com.synaptixfit.application.service.academic.SubjectDocumentAvailabilityService;
import com.synaptixfit.domain.port.output.academic.AiDocumentRepositoryPort;
import com.synaptixfit.domain.port.output.academic.NotePdfRendererPort;
import com.synaptixfit.domain.port.output.academic.NoteRecipientRepositoryPort;
import com.synaptixfit.domain.port.output.academic.NoteRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectFileRepositoryPort;
import com.synaptixfit.domain.port.output.academic.SubjectRepositoryPort;
import com.synaptixfit.domain.port.output.social.FriendshipRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Composición de la lista «Material» y de «Compartir» un apunte (ADR 0064): disponibilidad de documentos de IA por
 * asignatura, pasar un apunte a un amigo, publicarlo en el muro y exportarlo a PDF.
 */
@Configuration
public class NoteSharingBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final NoteRepositoryPort notes;
    private final NoteRecipientRepositoryPort recipients;
    private final FriendshipRepositoryPort friendships;
    private final UserRepositoryPort users;
    private final CreateNotificationUseCase notifications;
    private final PublishAchievementPostUseCase posts;
    private final NotePdfRendererPort pdf;
    private final SubjectRepositoryPort subjects;
    private final SubjectFileRepositoryPort files;
    private final AiDocumentRepositoryPort aiDocuments;
    private final Clock clock;

    public NoteSharingBeanConfiguration(TransactionalUseCaseFactory tx, NoteRepositoryPort notes,
                                        NoteRecipientRepositoryPort recipients, FriendshipRepositoryPort friendships,
                                        UserRepositoryPort users, CreateNotificationUseCase notifications,
                                        PublishAchievementPostUseCase posts, NotePdfRendererPort pdf,
                                        SubjectRepositoryPort subjects, SubjectFileRepositoryPort files,
                                        AiDocumentRepositoryPort aiDocuments, Clock clock) {
        this.tx = tx;
        this.notes = notes;
        this.recipients = recipients;
        this.friendships = friendships;
        this.users = users;
        this.notifications = notifications;
        this.posts = posts;
        this.pdf = pdf;
        this.subjects = subjects;
        this.files = files;
        this.aiDocuments = aiDocuments;
        this.clock = clock;
    }

    @Bean(autowireCandidate = false)
    NoteSharingService noteSharingService() {
        return new NoteSharingService(notes, recipients, friendships, users, notifications, posts, clock);
    }

    @Bean
    SendNoteToFriendUseCase sendNoteToFriendUseCase() {
        return tx.wrap(SendNoteToFriendUseCase.class, noteSharingService());
    }

    @Bean
    ShareNoteOnWallUseCase shareNoteOnWallUseCase() {
        return tx.wrap(ShareNoteOnWallUseCase.class, noteSharingService());
    }

    @Bean
    RevokeNoteRecipientsUseCase revokeNoteRecipientsUseCase() {
        return tx.wrap(RevokeNoteRecipientsUseCase.class, noteSharingService());
    }

    /**
     * Sin transacción a propósito: lee el apunte con {@code GetNoteUseCase} (ya transaccional) y dibuja el PDF fuera
     * de ella (ADR 0064).
     */
    @Bean
    ExportNotePdfUseCase exportNotePdfUseCase(GetNoteUseCase getNote) {
        return new NotePdfExportService(getNote, pdf);
    }

    @Bean
    GetSubjectDocumentAvailabilityUseCase getSubjectDocumentAvailabilityUseCase() {
        return tx.wrap(GetSubjectDocumentAvailabilityUseCase.class,
                new SubjectDocumentAvailabilityService(subjects, notes, files, aiDocuments));
    }
}
