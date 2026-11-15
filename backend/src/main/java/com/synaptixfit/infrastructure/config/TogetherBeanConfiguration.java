package com.synaptixfit.infrastructure.config;

import com.synaptixfit.application.port.input.notification.CreateNotificationUseCase;
import com.synaptixfit.application.port.input.planner.RecordFocusSessionUseCase;
import com.synaptixfit.application.port.input.together.ChangeStudyRoomTimesUseCase;
import com.synaptixfit.application.port.input.together.ChooseStudyRoomSubjectUseCase;
import com.synaptixfit.application.port.input.together.CreateStudyRoomUseCase;
import com.synaptixfit.application.port.input.together.CreditStudyRoomRoundsUseCase;
import com.synaptixfit.application.port.input.together.DeclineStudyRoomUseCase;
import com.synaptixfit.application.port.input.together.FindStudyRoomsToCreditUseCase;
import com.synaptixfit.application.port.input.together.GetStudyRoomUseCase;
import com.synaptixfit.application.port.input.together.GetTogetherLimitsUseCase;
import com.synaptixfit.application.port.input.together.JoinStudyRoomUseCase;
import com.synaptixfit.application.port.input.together.LeaveStudyRoomUseCase;
import com.synaptixfit.application.port.input.together.ReactStudyRoomUseCase;
import com.synaptixfit.application.port.input.together.StartStudyRoomUseCase;
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
import com.synaptixfit.application.port.input.together.NotifyWorkoutTogetherProgressUseCase;
import com.synaptixfit.application.port.input.together.PauseWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.together.ResumeWorkoutTogetherUseCase;
import com.synaptixfit.application.port.input.training.CopyRoutineForFriendUseCase;
import com.synaptixfit.application.port.input.training.PauseTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.ResumeTrainingSessionUseCase;
import com.synaptixfit.application.port.input.training.StartTrainingSessionUseCase;
import com.synaptixfit.application.service.together.FriendChallengeService;
import com.synaptixfit.application.service.together.FriendStreakService;
import com.synaptixfit.application.service.together.StudyRoomService;
import com.synaptixfit.application.service.together.TogetherCleanupService;
import com.synaptixfit.application.service.together.TogetherLimitsService;
import com.synaptixfit.application.service.together.TogetherNotifier;
import com.synaptixfit.application.service.together.TogetherOverviewService;
import com.synaptixfit.application.service.together.TogetherPeople;
import com.synaptixfit.application.service.together.WorkoutTogetherService;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.port.output.badge.StreakPauseRepositoryPort;
import com.synaptixfit.domain.port.output.challenge.ChallengeReferencePort;
import com.synaptixfit.domain.port.output.challenge.ChallengeTemplateRepositoryPort;
import com.synaptixfit.domain.port.output.notification.ReminderOptionsRepositoryPort;
import com.synaptixfit.domain.port.output.planner.SubjectDirectoryPort;
import com.synaptixfit.domain.port.output.social.FriendshipRepositoryPort;
import com.synaptixfit.domain.port.output.together.FriendChallengeReactionPort;
import com.synaptixfit.domain.port.output.together.FriendChallengeRepositoryPort;
import com.synaptixfit.domain.port.output.together.FriendStreakRepositoryPort;
import com.synaptixfit.domain.port.output.together.StudyRoomRepositoryPort;
import com.synaptixfit.domain.port.output.together.TogetherLivePort;
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
 * Composición de «Con amigos» (ADR 0044 y 0045): retos con amigos, rachas con un amigo, «Entrenamos juntos» y
 * «Estudiamos juntos» (cuyas rondas se apuntan con el registro de Pomodoro de siempre, {@link RecordFocusSessionUseCase}).
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
    private final StudyRoomRepositoryPort studyRooms;
    private final SubjectDirectoryPort subjects;
    private final RecordFocusSessionUseCase recordFocus;
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
    private final PauseTrainingSessionUseCase pauseSession;
    private final ResumeTrainingSessionUseCase resumeSession;
    private final CreateNotificationUseCase notifications;
    private final TogetherLivePort live;
    private final Clock clock;
    private final ZoneId zone;
    private final PlannerZone plannerZone;

    @SuppressWarnings("java:S107")
    public TogetherBeanConfiguration(TransactionalUseCaseFactory tx, FriendChallengeRepositoryPort challenges,
                                     FriendChallengeReactionPort reactions, FriendStreakRepositoryPort streaks,
                                     WorkoutTogetherRepositoryPort workouts, StudyRoomRepositoryPort studyRooms,
                                     SubjectDirectoryPort subjects, RecordFocusSessionUseCase recordFocus,
                                     ChallengeTemplateRepositoryPort templates,
                                     ChallengeReferencePort activity, StreakPauseRepositoryPort pauses,
                                     ReminderOptionsRepositoryPort reminderOptions,
                                     FriendshipRepositoryPort friendships, UserRepositoryPort users,
                                     RoutineRepositoryPort routines, TrainingSessionRepositoryPort sessions,
                                     CopyRoutineForFriendUseCase copyRoutine, StartTrainingSessionUseCase startSession,
                                     PauseTrainingSessionUseCase pauseSession,
                                     ResumeTrainingSessionUseCase resumeSession,
                                     CreateNotificationUseCase notifications, TogetherLivePort live, Clock clock,
                                     @Value("${synaptixfit.gamification.zone:Europe/Madrid}") String zone,
                                     @Value("${synaptixfit.planner.zone:Europe/Madrid}") String plannerZone) {
        this.tx = tx;
        this.challenges = challenges;
        this.reactions = reactions;
        this.streaks = streaks;
        this.workouts = workouts;
        this.studyRooms = studyRooms;
        this.subjects = subjects;
        this.recordFocus = recordFocus;
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
        this.pauseSession = pauseSession;
        this.resumeSession = resumeSession;
        this.notifications = notifications;
        this.live = live;
        this.clock = clock;
        this.zone = ZoneId.of(zone);
        this.plannerZone = PlannerZone.of(plannerZone);
    }

    private TogetherPeople people() {
        return new TogetherPeople(friendships, users);
    }

    private TogetherNotifier notifier() {
        return new TogetherNotifier(notifications, users, live);
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
        return new WorkoutTogetherService(workouts, routines, sessions, copyRoutine, startSession, pauseSession,
                resumeSession, people(), notifier(), clock, zone);
    }

    @Bean(autowireCandidate = false)
    StudyRoomService studyRoomService() {
        return new StudyRoomService(studyRooms, subjects, recordFocus, people(), notifier(), clock, plannerZone);
    }

    @Bean
    ListTogetherUseCase listTogetherUseCase() {
        return tx.wrap(ListTogetherUseCase.class, new TogetherOverviewService(friendChallengeService(),
                friendStreakService(), workoutTogetherService(), studyRoomService(), people()));
    }

    @Bean
    GetTogetherLimitsUseCase getTogetherLimitsUseCase() {
        return new TogetherLimitsService();
    }

    @Bean
    LeaveSharedWithUserUseCase leaveSharedWithUserUseCase() {
        return tx.wrap(LeaveSharedWithUserUseCase.class,
                new TogetherCleanupService(streaks, challenges, workouts, studyRoomService(), clock, zone));
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

    @Bean
    PauseWorkoutTogetherUseCase pauseWorkoutTogetherUseCase() {
        return tx.wrap(PauseWorkoutTogetherUseCase.class, workoutTogetherService());
    }

    @Bean
    ResumeWorkoutTogetherUseCase resumeWorkoutTogetherUseCase() {
        return tx.wrap(ResumeWorkoutTogetherUseCase.class, workoutTogetherService());
    }

    @Bean
    NotifyWorkoutTogetherProgressUseCase notifyWorkoutTogetherProgressUseCase() {
        return tx.wrap(NotifyWorkoutTogetherProgressUseCase.class, workoutTogetherService());
    }

    // ---------------------------------------------------------------- estudiar juntos

    @Bean
    CreateStudyRoomUseCase createStudyRoomUseCase() {
        return tx.wrap(CreateStudyRoomUseCase.class, studyRoomService());
    }

    @Bean
    GetStudyRoomUseCase getStudyRoomUseCase() {
        return tx.wrap(GetStudyRoomUseCase.class, studyRoomService());
    }

    @Bean
    JoinStudyRoomUseCase joinStudyRoomUseCase() {
        return tx.wrap(JoinStudyRoomUseCase.class, studyRoomService());
    }

    @Bean
    DeclineStudyRoomUseCase declineStudyRoomUseCase() {
        return tx.wrap(DeclineStudyRoomUseCase.class, studyRoomService());
    }

    @Bean
    LeaveStudyRoomUseCase leaveStudyRoomUseCase() {
        return tx.wrap(LeaveStudyRoomUseCase.class, studyRoomService());
    }

    @Bean
    StartStudyRoomUseCase startStudyRoomUseCase() {
        return tx.wrap(StartStudyRoomUseCase.class, studyRoomService());
    }

    @Bean
    ChangeStudyRoomTimesUseCase changeStudyRoomTimesUseCase() {
        return tx.wrap(ChangeStudyRoomTimesUseCase.class, studyRoomService());
    }

    @Bean
    ChooseStudyRoomSubjectUseCase chooseStudyRoomSubjectUseCase() {
        return tx.wrap(ChooseStudyRoomSubjectUseCase.class, studyRoomService());
    }

    @Bean
    ReactStudyRoomUseCase reactStudyRoomUseCase() {
        return tx.wrap(ReactStudyRoomUseCase.class, studyRoomService());
    }

    @Bean
    FindStudyRoomsToCreditUseCase findStudyRoomsToCreditUseCase() {
        return tx.wrap(FindStudyRoomsToCreditUseCase.class, studyRoomService());
    }

    @Bean
    CreditStudyRoomRoundsUseCase creditStudyRoomRoundsUseCase() {
        return tx.wrap(CreditStudyRoomRoundsUseCase.class, studyRoomService());
    }
}
