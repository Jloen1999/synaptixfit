package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.notification.CreateNotificationUseCase;
import com.synaptixfit.application.port.input.together.AcceptFriendStreakUseCase;
import com.synaptixfit.application.port.input.together.CreateFriendChallengeUseCase;
import com.synaptixfit.application.port.input.together.CreateWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.DeclineFriendChallengeUseCase;
import com.synaptixfit.application.port.input.together.DeclineFriendStreakUseCase;
import com.synaptixfit.application.port.input.together.DeclineWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.EndFriendStreakUseCase;
import com.synaptixfit.application.port.input.together.FindWorkoutTogetherBySessionUseCase;
import com.synaptixfit.application.port.input.together.GetFriendChallengeUseCase;
import com.synaptixfit.application.port.input.together.GetWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.JoinFriendChallengeUseCase;
import com.synaptixfit.application.port.input.together.JoinWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.LeaveFriendChallengeUseCase;
import com.synaptixfit.application.port.input.together.LeaveSharedWithUserUseCase;
import com.synaptixfit.application.port.input.together.LeaveWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.ListFriendChallengeTemplatesUseCase;
import com.synaptixfit.application.port.input.together.ListTogetherUseCase;
import com.synaptixfit.application.port.input.together.NudgeFriendStreakUseCase;
import com.synaptixfit.application.port.input.together.ProposeFriendStreakUseCase;
import com.synaptixfit.application.port.input.together.ReactFriendChallengeUseCase;
import com.synaptixfit.application.port.input.together.RemoveFriendChallengeReactionUseCase;
import com.synaptixfit.application.port.input.together.StartWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.training.CopyRoutineForFriendUseCase;
import com.synaptixfit.application.port.input.training.StartTrainingSessionUseCase;
import com.synaptixfit.application.service.together.FriendChallengeService;
import com.synaptixfit.application.service.together.FriendStreakService;
import com.synaptixfit.application.service.together.TogetherCleanupService;
import com.synaptixfit.application.service.together.TogetherNotifier;
import com.synaptixfit.application.service.together.TogetherOverviewService;
import com.synaptixfit.application.service.together.TogetherPeople;
import com.synaptixfit.application.service.together.WorkoutTogetherService;
import com.synaptixfit.domain.port.output.badge.StreakPauseRepositoryPort;
import com.synaptixfit.domain.port.output.challenge.ChallengeReferencePort;
import com.synaptixfit.domain.port.output.challenge.ChallengeTemplateRepositoryPort;
import com.synaptixfit.domain.port.output.notification.ReminderOptionsRepositoryPort;
import com.synaptixfit.domain.port.output.social.FriendshipRepositoryPort;
import com.synaptixfit.domain.port.output.together.FriendChallengeReactionPort;
import com.synaptixfit.domain.port.output.together.FriendChallengeRepositoryPort;
import com.synaptixfit.domain.port.output.together.FriendStreakRepositoryPort;
import com.synaptixfit.domain.port.output.together.WorkoutTogetherRepositoryPort;
import com.synaptixfit.domain.port.output.training.RoutineRepositoryPort;
import com.synaptixfit.domain.port.output.training.TrainingSessionRepositoryPort;
import com.synaptixfit.domain.port.output.user.UserRepositoryPort;
import java.time.Clock;
import java.time.ZoneId;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Composición de «Con amigos» asíncrono (ADR 0044): retos con amigos, rachas con un amigo y «Entrenamos juntos».
 * Lee lo hecho con el mismo puerto que los retos que se cuentan solos ({@link ChallengeReferencePort}) y usa la
 * zona de la gamificación para decidir qué día es hoy.
 */
@Configuration
public class TogetherBeanConfiguration {

    private final TransactionalUseCaseFactory tx;
    private final FriendChallengeRepositoryPort challenges;
    private final FriendChallengeReactionPort reactions;
    private final FriendStreakRepositoryPort streaks;
    private final WorkoutTogetherRepositoryPort workouts;
    private final ChallengeTemplateRepositoryPort templates;
    private final ChallengeReferencePort activity;
    private final StreakPauseRepositoryPort pauses;
    private final ReminderOptionsRepositoryPort reminderOptions;
    private final FriendshipRepositoryPort friendships;
    private final UserRepositoryPort users;
    private final RoutineRepositoryPort routines;
    private final TrainingSessionRepositoryPort sessions;
    private final CopyRoutineForFriendUseCase copyRoutine;
    private final StartTrainingSessionUseCase startSession;
    private final CreateNotificationUseCase notifications;
    private final Clock clock;
    private final ZoneId zone;

    @SuppressWarnings("java:S107")
    public TogetherBeanConfiguration(TransactionalUseCaseFactory tx, FriendChallengeRepositoryPort challenges,
                                     FriendChallengeReactionPort reactions, FriendStreakRepositoryPort streaks,
                                     WorkoutTogetherRepositoryPort workouts, ChallengeTemplateRepositoryPort templates,
                                     ChallengeReferencePort activity, StreakPauseRepositoryPort pauses,
                                     ReminderOptionsRepositoryPort reminderOptions,
                                     FriendshipRepositoryPort friendships, UserRepositoryPort users,
                                     RoutineRepositoryPort routines, TrainingSessionRepositoryPort sessions,
                                     CopyRoutineForFriendUseCase copyRoutine, StartTrainingSessionUseCase startSession,
                                     CreateNotificationUseCase notifications, Clock clock,
                                     @Value("${synaptixfit.gamification.zone:Europe/Madrid}") String zone) {
        this.tx = tx;
        this.challenges = challenges;
        this.reactions = reactions;
        this.streaks = streaks;
        this.workouts = workouts;
        this.templates = templates;
        this.activity = activity;
        this.pauses = pauses;
        this.reminderOptions = reminderOptions;
        this.friendships = friendships;
        this.users = users;
        this.routines = routines;
        this.sessions = sessions;
        this.copyRoutine = copyRoutine;
        this.startSession = startSession;
        this.notifications = notifications;
        this.clock = clock;
        this.zone = ZoneId.of(zone);
    }

    private TogetherPeople people() {
        return new TogetherPeople(friendships, users);
    }

    private TogetherNotifier notifier() {
        return new TogetherNotifier(notifications, users);
    }

    @Bean(autowireCandidate = false)
    FriendChallengeService friendChallengeService() {
        return new FriendChallengeService(challenges, reactions, templates, activity, users, people(), notifier(),
                clock, zone);
    }

    @Bean(autowireCandidate = false)
    FriendStreakService friendStreakService() {
        return new FriendStreakService(streaks, activity, pauses, reminderOptions, people(), notifier(), clock, zone);
    }

    @Bean(autowireCandidate = false)
    WorkoutTogetherService workoutTogetherService() {
        return new WorkoutTogetherService(workouts, routines, sessions, copyRoutine, startSession, people(),
                notifier(), clock, zone);
    }

    @Bean
    ListTogetherUseCase listTogetherUseCase() {
        return tx.wrap(ListTogetherUseCase.class, new TogetherOverviewService(friendChallengeService(),
                friendStreakService(), workoutTogetherService(), people()));
    }

    @Bean
    LeaveSharedWithUserUseCase leaveSharedWithUserUseCase() {
        return tx.wrap(LeaveSharedWithUserUseCase.class,
                new TogetherCleanupService(streaks, challenges, workouts, clock, zone));
    }

    // ---------------------------------------------------------------- retos con amigos

    @Bean
    ListFriendChallengeTemplatesUseCase listFriendChallengeTemplatesUseCase() {
        return tx.wrap(ListFriendChallengeTemplatesUseCase.class, friendChallengeService());
    }

    @Bean
    CreateFriendChallengeUseCase createFriendChallengeUseCase() {
        return tx.wrap(CreateFriendChallengeUseCase.class, friendChallengeService());
    }

    @Bean
    GetFriendChallengeUseCase getFriendChallengeUseCase() {
        return tx.wrap(GetFriendChallengeUseCase.class, friendChallengeService());
    }

    @Bean
    JoinFriendChallengeUseCase joinFriendChallengeUseCase() {
        return tx.wrap(JoinFriendChallengeUseCase.class, friendChallengeService());
    }

    @Bean
    DeclineFriendChallengeUseCase declineFriendChallengeUseCase() {
        return tx.wrap(DeclineFriendChallengeUseCase.class, friendChallengeService());
    }

    @Bean
    LeaveFriendChallengeUseCase leaveFriendChallengeUseCase() {
        return tx.wrap(LeaveFriendChallengeUseCase.class, friendChallengeService());
    }

    @Bean
    ReactFriendChallengeUseCase reactFriendChallengeUseCase() {
        return tx.wrap(ReactFriendChallengeUseCase.class, friendChallengeService());
    }

    @Bean
    RemoveFriendChallengeReactionUseCase removeFriendChallengeReactionUseCase() {
        return tx.wrap(RemoveFriendChallengeReactionUseCase.class, friendChallengeService());
    }

    // ---------------------------------------------------------------- rachas con un amigo

    @Bean
    ProposeFriendStreakUseCase proposeFriendStreakUseCase() {
        return tx.wrap(ProposeFriendStreakUseCase.class, friendStreakService());
    }

    @Bean
    AcceptFriendStreakUseCase acceptFriendStreakUseCase() {
        return tx.wrap(AcceptFriendStreakUseCase.class, friendStreakService());
    }

    @Bean
    DeclineFriendStreakUseCase declineFriendStreakUseCase() {
        return tx.wrap(DeclineFriendStreakUseCase.class, friendStreakService());
    }

    @Bean
    EndFriendStreakUseCase endFriendStreakUseCase() {
        return tx.wrap(EndFriendStreakUseCase.class, friendStreakService());
    }

    @Bean
    NudgeFriendStreakUseCase nudgeFriendStreakUseCase() {
        return tx.wrap(NudgeFriendStreakUseCase.class, friendStreakService());
    }

    // ---------------------------------------------------------------- entrenar juntos

    @Bean
    CreateWorkoutTogetherUseCase createWorkoutTogetherUseCase() {
        return tx.wrap(CreateWorkoutTogetherUseCase.class, workoutTogetherService());
    }

    @Bean
    GetWorkoutTogetherUseCase getWorkoutTogetherUseCase() {
        return tx.wrap(GetWorkoutTogetherUseCase.class, workoutTogetherService());
    }

    @Bean
    FindWorkoutTogetherBySessionUseCase findWorkoutTogetherBySessionUseCase() {
        return tx.wrap(FindWorkoutTogetherBySessionUseCase.class, workoutTogetherService());
    }

    @Bean
    JoinWorkoutTogetherUseCase joinWorkoutTogetherUseCase() {
        return tx.wrap(JoinWorkoutTogetherUseCase.class, workoutTogetherService());
    }

    @Bean
    DeclineWorkoutTogetherUseCase declineWorkoutTogetherUseCase() {
        return tx.wrap(DeclineWorkoutTogetherUseCase.class, workoutTogetherService());
    }

    @Bean
    LeaveWorkoutTogetherUseCase leaveWorkoutTogetherUseCase() {
        return tx.wrap(LeaveWorkoutTogetherUseCase.class, workoutTogetherService());
    }

    @Bean
    StartWorkoutTogetherUseCase startWorkoutTogetherUseCase() {
        return tx.wrap(StartWorkoutTogetherUseCase.class, workoutTogetherService());
    }
}
