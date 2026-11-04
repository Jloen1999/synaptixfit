package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.challenge.CloneChallengeUseCase;
import com.synaptixfit.application.port.input.challenge.CompleteChallengeUseCase;
import com.synaptixfit.application.port.input.challenge.CompleteMilestoneUseCase;
import com.synaptixfit.application.port.input.challenge.CreateChallengeUseCase;
import com.synaptixfit.application.port.input.challenge.DeleteChallengeUseCase;
import com.synaptixfit.application.port.input.challenge.GetChallengeSummaryUseCase;
import com.synaptixfit.application.port.input.challenge.GetChallengeUseCase;
import com.synaptixfit.application.port.input.challenge.HideUserChallengesUseCase;
import com.synaptixfit.application.port.input.challenge.ListChallengeProgressUseCase;
import com.synaptixfit.application.port.input.challenge.ListCommunityChallengesUseCase;
import com.synaptixfit.application.port.input.challenge.ListMyChallengesUseCase;
import com.synaptixfit.application.port.input.challenge.ListPendingMilestonesUseCase;
import com.synaptixfit.application.port.input.challenge.RecordChallengeProgressUseCase;
import com.synaptixfit.application.port.input.challenge.ReorderMilestonesUseCase;
import com.synaptixfit.application.port.input.challenge.ReplaceMilestonesUseCase;
import com.synaptixfit.application.port.input.challenge.SyncLinkedEntityChallengesUseCase;
import com.synaptixfit.application.port.input.challenge.SyncMilestoneStudyBlocksUseCase;
import com.synaptixfit.application.port.input.challenge.SyncTrainingSessionChallengesUseCase;
import com.synaptixfit.application.port.input.challenge.UncompleteChallengeUseCase;
import com.synaptixfit.application.port.input.challenge.UncompleteMilestoneUseCase;
import com.synaptixfit.application.port.input.challenge.UpdateChallengeUseCase;
import com.synaptixfit.application.port.input.gamification.AwardExperienceUseCase;
import com.synaptixfit.application.port.input.gamification.RevokeExperienceUseCase;
import com.synaptixfit.application.service.challenge.ChallengeEffects;
import com.synaptixfit.application.service.challenge.ChallengeProgressService;
import com.synaptixfit.application.service.challenge.ChallengeReferenceValidator;
import com.synaptixfit.application.service.challenge.ChallengeService;
import com.synaptixfit.domain.port.output.challenge.ChallengeAudiencePort;
import com.synaptixfit.domain.port.output.challenge.ChallengeReferencePort;
import com.synaptixfit.domain.port.output.challenge.ChallengeRepositoryPort;
import com.synaptixfit.domain.port.output.event.DomainEventPublisherPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.ZoneId;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Composición de los retos y sus tareas (patrón de {@link BeanConfiguration}). */
@Configuration
public class ChallengeBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final ChallengeRepositoryPort challenges;
    private final ChallengeAudiencePort audience;
    private final ChallengeReferencePort references;
    private final UserRepositoryPort users;
    private final AwardExperienceUseCase awardExperience;
    private final RevokeExperienceUseCase revokeExperience;
    private final DomainEventPublisherPort events;
    private final Clock clock;
    private final ZoneId zone;

    public ChallengeBeanConfiguration(TransactionalUseCaseFactory tx, ChallengeRepositoryPort challenges,
                                      ChallengeAudiencePort audience, ChallengeReferencePort references,
                                      UserRepositoryPort users, AwardExperienceUseCase awardExperience,
                                      RevokeExperienceUseCase revokeExperience, DomainEventPublisherPort events,
                                      Clock clock,
                                      @Value("${synaptixfit.gamification.zone:Europe/Madrid}") String zone) {
        this.tx = tx;
        this.challenges = challenges;
        this.audience = audience;
        this.references = references;
        this.users = users;
        this.awardExperience = awardExperience;
        this.revokeExperience = revokeExperience;
        this.events = events;
        this.clock = clock;
        this.zone = ZoneId.of(zone);
    }

    // ---------------------------------------------------------------- servicios

    @Bean(autowireCandidate = false)
    ChallengeService challengeService() {
        return new ChallengeService(challenges, audience, users, new ChallengeReferenceValidator(references),
                references, challengeEffects(), clock, zone);
    }

    @Bean(autowireCandidate = false)
    ChallengeProgressService challengeProgressService() {
        return new ChallengeProgressService(challenges, references, new ChallengeReferenceValidator(references),
                challengeEffects(), clock, zone);
    }

    @Bean(autowireCandidate = false)
    ChallengeEffects challengeEffects() {
        return new ChallengeEffects(awardExperience, revokeExperience, events, clock);
    }

    // ---------------------------------------------------------------- retos

    @Bean
    CreateChallengeUseCase createChallengeUseCase() {
        return tx.wrap(CreateChallengeUseCase.class, challengeService());
    }

    @Bean
    GetChallengeUseCase getChallengeUseCase() {
        return tx.wrap(GetChallengeUseCase.class, challengeService());
    }

    @Bean
    ListMyChallengesUseCase listMyChallengesUseCase() {
        return tx.wrap(ListMyChallengesUseCase.class, challengeService());
    }

    @Bean
    GetChallengeSummaryUseCase getChallengeSummaryUseCase() {
        return tx.wrap(GetChallengeSummaryUseCase.class, challengeService());
    }

    @Bean
    ListCommunityChallengesUseCase listCommunityChallengesUseCase() {
        return tx.wrap(ListCommunityChallengesUseCase.class, challengeService());
    }

    @Bean
    ListPendingMilestonesUseCase listPendingMilestonesUseCase() {
        return tx.wrap(ListPendingMilestonesUseCase.class, challengeService());
    }

    @Bean
    UpdateChallengeUseCase updateChallengeUseCase() {
        return tx.wrap(UpdateChallengeUseCase.class, challengeService());
    }

    @Bean
    DeleteChallengeUseCase deleteChallengeUseCase() {
        return tx.wrap(DeleteChallengeUseCase.class, challengeService());
    }

    @Bean
    CloneChallengeUseCase cloneChallengeUseCase() {
        return tx.wrap(CloneChallengeUseCase.class, challengeService());
    }

    @Bean
    ListChallengeProgressUseCase listChallengeProgressUseCase() {
        return tx.wrap(ListChallengeProgressUseCase.class, challengeService());
    }

    // ---------------------------------------------------------------- estado y tareas

    @Bean
    CompleteChallengeUseCase completeChallengeUseCase() {
        return tx.wrap(CompleteChallengeUseCase.class, challengeProgressService());
    }

    @Bean
    UncompleteChallengeUseCase uncompleteChallengeUseCase() {
        return tx.wrap(UncompleteChallengeUseCase.class, challengeProgressService());
    }

    @Bean
    ReplaceMilestonesUseCase replaceMilestonesUseCase() {
        return tx.wrap(ReplaceMilestonesUseCase.class, challengeProgressService());
    }

    @Bean
    ReorderMilestonesUseCase reorderMilestonesUseCase() {
        return tx.wrap(ReorderMilestonesUseCase.class, challengeProgressService());
    }

    @Bean
    CompleteMilestoneUseCase completeMilestoneUseCase() {
        return tx.wrap(CompleteMilestoneUseCase.class, challengeProgressService());
    }

    @Bean
    UncompleteMilestoneUseCase uncompleteMilestoneUseCase() {
        return tx.wrap(UncompleteMilestoneUseCase.class, challengeProgressService());
    }

    @Bean
    RecordChallengeProgressUseCase recordChallengeProgressUseCase() {
        return tx.wrap(RecordChallengeProgressUseCase.class, challengeProgressService());
    }

    // ---------------------------------------------------------------- sincronización (oyentes)

    @Bean
    SyncLinkedEntityChallengesUseCase syncLinkedEntityChallengesUseCase() {
        return tx.wrap(SyncLinkedEntityChallengesUseCase.class, challengeProgressService());
    }

    @Bean
    SyncMilestoneStudyBlocksUseCase syncMilestoneStudyBlocksUseCase() {
        return tx.wrap(SyncMilestoneStudyBlocksUseCase.class, challengeProgressService());
    }

    @Bean
    SyncTrainingSessionChallengesUseCase syncTrainingSessionChallengesUseCase() {
        return tx.wrap(SyncTrainingSessionChallengesUseCase.class, challengeProgressService());
    }

    @Bean
    HideUserChallengesUseCase hideUserChallengesUseCase() {
        return tx.wrap(HideUserChallengesUseCase.class, challengeProgressService());
    }
}
