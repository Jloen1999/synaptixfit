package com.synaptixfit.application.service.together;

import com.synaptixfit.application.port.input.planner.RecordFocusSessionUseCase;
import com.synaptixfit.application.port.input.together.ChooseStudyRoomSubjectUseCase;
import com.synaptixfit.application.port.input.together.CreateStudyRoomUseCase;
import com.synaptixfit.application.port.input.together.CreditStudyRoomRoundsUseCase;
import com.synaptixfit.application.port.input.together.DeclineStudyRoomUseCase;
import com.synaptixfit.application.port.input.together.FindStudyRoomsToCreditUseCase;
import com.synaptixfit.application.port.input.together.GetStudyRoomUseCase;
import com.synaptixfit.application.port.input.together.JoinStudyRoomUseCase;
import com.synaptixfit.application.port.input.together.LeaveStudyRoomUseCase;
import com.synaptixfit.application.port.input.together.ReactStudyRoomUseCase;
import com.synaptixfit.application.port.input.together.StartStudyRoomUseCase;
import com.synaptixfit.application.port.input.together.StudyRoomView;
import com.synaptixfit.domain.exception.planner.PlannerSubjectNotFoundException;
import com.synaptixfit.domain.exception.together.StudyRoomNotFoundException;
import com.synaptixfit.domain.model.planner.FocusSession;
import com.synaptixfit.domain.model.planner.PlannerZone;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.together.MemberStatus;
import com.synaptixfit.domain.model.together.StudyRoom;
import com.synaptixfit.domain.model.together.StudyRoomReaction;
import com.synaptixfit.domain.model.together.TogetherLiveChange;
import com.synaptixfit.domain.model.together.TogetherMember;
import com.synaptixfit.domain.port.output.planner.SubjectDirectoryPort;
import com.synaptixfit.domain.port.output.together.StudyRoomRepositoryPort;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.LocalDate;
import java.util.Comparator;
import java.util.List;
import java.util.Set;
import java.util.TreeSet;
import java.util.UUID;

/**
 * «Estudiamos juntos» (ADR 0045): crear la sala, aceptar, decir que no, salir, empezar, elegir asignatura y
 * reaccionar. Cada ronda terminada se apunta a cada persona de dentro con {@link RecordFocusSessionUseCase}, el
 * mismo registro que el Pomodoro de siempre: suma racha, retos, «Estudia y muévete» y lo de «Con amigos», con la XP
 * normal y su tope diario (sin XP extra por estar en grupo). Entrar, salir, empezar y reaccionar se avisan en directo a
 * quien esté en la sala (ADR 0047); el cambio de fase no, porque lo calcula cada móvil con la hora del servidor.
 */
public class StudyRoomService implements CreateStudyRoomUseCase, GetStudyRoomUseCase, JoinStudyRoomUseCase,
        DeclineStudyRoomUseCase, LeaveStudyRoomUseCase, StartStudyRoomUseCase, ChooseStudyRoomSubjectUseCase,
        ReactStudyRoomUseCase, FindStudyRoomsToCreditUseCase, CreditStudyRoomRoundsUseCase {

    /** Una sala vive como mucho 4 h esperando y unas 4 h en marcha: más allá no hay nada que enseñar ni contar. */
    static final Duration LOOK_BACK = Duration.ofHours(12);

    private final StudyRoomRepositoryPort rooms;
    private final SubjectDirectoryPort subjects;
    private final RecordFocusSessionUseCase recordFocus;
    private final TogetherPeople people;
    private final TogetherNotifier notifier;
    private final Clock clock;
    /** La zona del Pomodoro de siempre: el día de cada ronda se decide igual que en {@code FocusService}. */
    private final PlannerZone zone;

    public StudyRoomService(StudyRoomRepositoryPort rooms, SubjectDirectoryPort subjects,
                            RecordFocusSessionUseCase recordFocus, TogetherPeople people, TogetherNotifier notifier,
                            Clock clock, PlannerZone zone) {
        this.rooms = rooms;
        this.subjects = subjects;
        this.recordFocus = recordFocus;
        this.people = people;
        this.notifier = notifier;
        this.clock = clock;
        this.zone = zone;
    }

    @Override
    public StudyRoomView create(Command command) {
        Guard.notNull(command, "command");
        ensureOwnSubject(command.userId(), command.subjectId());
        Instant now = clock.instant();
        StudyRoom room = StudyRoom.create(command.userId(), command.friendIds() == null ? Set.of()
                : command.friendIds(), Guard.notNull(command.length(), "length"), command.rounds(),
                command.subjectId(), now);
        people.ensureFriends(command.userId(), room.members().invitedIds());
        StudyRoom saved = rooms.save(room);
        notifier.studyRoomInvited(saved.members().invitedIds(), command.userId(), saved.id());
        notifier.changed(TogetherLiveChange.Topic.TOGETHER, saved.id(), audience(saved, command.userId()));
        return view(saved, command.userId(), people.lookup(), now);
    }

    @Override
    public StudyRoomView get(UUID userId, UUID roomId) {
        return view(visible(userId, roomId), userId, people.lookup(), clock.instant());
    }

    @Override
    public StudyRoomView join(UUID userId, UUID roomId) {
        // Como en los retos: volver tras salir solo si sigue siendo amigo de quien la creó y sin bloqueos con nadie
        // de dentro.
        StudyRoom room = rooms.findByIdForUpdate(roomId)
                .filter(r -> r.members().find(userId).isPresent())
                .filter(r -> people.canJoin(userId, r.creatorId(), r.members().joinedIds()))
                .orElseThrow(() -> new StudyRoomNotFoundException(roomId));
        Instant now = clock.instant();
        credit(room, now);
        room.join(userId, now);
        StudyRoom saved = rooms.save(room);
        changed(saved, userId);
        return view(saved, userId, people.lookup(), now);
    }

    @Override
    public void decline(UUID userId, UUID roomId) {
        StudyRoom room = visibleForUpdate(userId, roomId);
        room.decline(userId, clock.instant());
        changed(rooms.save(room), userId);
    }

    @Override
    public void leave(UUID userId, UUID roomId) {
        StudyRoom room = visibleForUpdate(userId, roomId);
        Instant now = clock.instant();
        // Salir no apunta nada: las rondas que terminaron con la persona dentro las apunta el programador al minuto
        // (StudyRoom.creditsDue la sigue contando). Así un fallo al apuntar un Pomodoro nunca impide salir.
        if (room.leave(userId, now)) {
            changed(rooms.save(room), userId);
        }
    }

    @Override
    public StudyRoomView start(UUID userId, UUID roomId) {
        StudyRoom room = visibleForUpdate(userId, roomId);
        Instant now = clock.instant();
        room.start(userId, now);
        StudyRoom saved = rooms.save(room);
        changed(saved, userId);
        return view(saved, userId, people.lookup(), now);
    }

    @Override
    public StudyRoomView chooseSubject(UUID userId, UUID roomId, UUID subjectId) {
        StudyRoom room = visibleForUpdate(userId, roomId);
        ensureOwnSubject(userId, subjectId);
        room.chooseSubject(userId, subjectId);
        return view(rooms.save(room), userId, people.lookup(), clock.instant());
    }

    @Override
    public StudyRoomView react(UUID userId, UUID roomId, StudyRoomReaction reaction) {
        StudyRoom room = visibleForUpdate(userId, roomId);
        Instant now = clock.instant();
        room.react(userId, reaction, now);
        StudyRoom saved = rooms.save(room);
        changed(saved, userId);
        return view(saved, userId, people.lookup(), now);
    }

    @Override
    public List<UUID> roomsToCredit() {
        return rooms.findWithRoundsToCredit(clock.instant().minus(LOOK_BACK));
    }

    @Override
    public int creditRounds(UUID roomId) {
        return rooms.findByIdForUpdate(roomId).map(r -> credit(r, clock.instant())).orElse(0);
    }

    /** Las salas sin terminar en las que la persona está invitada o dentro (para «Con amigos»). */
    List<StudyRoomView> overview(UUID userId, TogetherPeople.Lookup lookup) {
        Instant now = clock.instant();
        return rooms.findVisibleTo(userId, now.minus(LOOK_BACK)).stream()
                .filter(r -> r.canView(userId) && !r.isOver(now))
                .map(r -> view(r, userId, lookup, now))
                .toList();
    }

    /**
     * Al bloquear o dejar de ser amigos (ADR 0044): en cada sala sin terminar que comparten, sale quien diga
     * {@link com.synaptixfit.domain.model.together.TogetherMembers#leavingWhenSeparated}. Las rondas terminadas con
     * esa persona dentro las apunta después el programador, como al salir a mano.
     */
    void separate(UUID userId, UUID otherUserId, boolean blocked) {
        Instant now = clock.instant();
        for (StudyRoom found : rooms.findVisibleTo(userId, now.minus(LOOK_BACK))) {
            StudyRoom room = found.isOver(now) ? null : rooms.findByIdForUpdate(found.id()).orElse(null);
            if (room == null) {
                continue;
            }
            room.members().leavingWhenSeparated(room.creatorId(), userId, otherUserId, blocked)
                    .ifPresent(leaving -> {
                        // Como al salir a mano: lo terminado lo apunta el programador; bloquear nunca falla por ello.
                        if (room.leave(leaving, now)) {
                            changed(rooms.save(room), leaving);
                        }
                    });
        }
    }

    /** Aviso en directo a quien esté en la sala (o invitado) y a quien actuó (ADR 0047). */
    private void changed(StudyRoom room, UUID actorId) {
        notifier.changed(TogetherLiveChange.Topic.STUDY_ROOM, room.id(), audience(room, actorId));
    }

    private static Set<UUID> audience(StudyRoom room, UUID actorId) {
        Set<UUID> result = new TreeSet<>(room.members().visibleIds());
        result.add(actorId);
        return result;
    }

    /**
     * Apunta las rondas terminadas y aún sin contar. Solo la petición que reserva las rondas
     * ({@link StudyRoomRepositoryPort#claimCredits}) las apunta; las demás no hacen nada.
     */
    private int credit(StudyRoom room, Instant now) {
        int upTo = room.roundsToCredit(now);
        if (upTo <= room.creditedRounds()) {
            return 0;
        }
        List<StudyRoom.Credit> due = room.creditsDue(now);
        if (!rooms.claimCredits(room.id(), room.creditedRounds(), upTo)) {
            return 0;
        }
        room.markCredited(upTo);
        LocalDate oldest = zone.today(now).minusDays(FocusSession.MAX_DAYS_BACK);
        int recorded = 0;
        for (StudyRoom.Credit c : due) {
            LocalDate day = zone.localDate(c.endedAt());
            // El Pomodoro de siempre no acepta fases de antes de ayer; una ronda tan vieja (servidor parado) no cuenta.
            if (!day.isBefore(oldest)) {
                record(c, day);
                recorded++;
            }
        }
        return recorded;
    }

    private void record(StudyRoom.Credit c, LocalDate day) {
        // Si la asignatura se eliminó durante la sala, la ronda cuenta igual, sin asignatura. Se comprueba antes en vez
        // de capturar el error: una excepción dentro del registro marcaría la transacción para deshacerse.
        UUID subjectId = c.subjectId() != null && subjects.findOwned(c.userId(), c.subjectId()).isPresent()
                ? c.subjectId() : null;
        recordFocus.record(new RecordFocusSessionUseCase.Command(c.userId(), FocusSession.FocusPhase.FOCUS,
                c.minutes(), 1, true, day, null, subjectId));
    }

    private void ensureOwnSubject(UUID userId, UUID subjectId) {
        if (subjectId != null && subjects.findOwned(userId, subjectId).isEmpty()) {
            throw new PlannerSubjectNotFoundException(subjectId);
        }
    }

    private StudyRoom visible(UUID userId, UUID roomId) {
        return rooms.findById(roomId)
                .filter(r -> r.canView(userId))
                .orElseThrow(() -> new StudyRoomNotFoundException(roomId));
    }

    /** Como {@link #visible}, pero bloqueada: para las acciones que la cambian. */
    private StudyRoom visibleForUpdate(UUID userId, UUID roomId) {
        return rooms.findByIdForUpdate(roomId)
                .filter(r -> r.canView(userId))
                .orElseThrow(() -> new StudyRoomNotFoundException(roomId));
    }

    /**
     * Quién sale: yo primero; después quien está dentro, quien está invitado y quien se ha ido. Quien dijo que no a la
     * invitación no aparece.
     */
    private StudyRoomView view(StudyRoom room, UUID viewerId, TogetherPeople.Lookup lookup, Instant now) {
        StudyRoom.Moment moment = room.momentAt(now);
        List<StudyRoomView.Member> members = room.members().all().stream()
                .filter(m -> m.status() != MemberStatus.DECLINED)
                .sorted(Comparator.comparing((TogetherMember m) -> !m.userId().equals(viewerId))
                        .thenComparing(m -> order(m.status())))
                .map(m -> new StudyRoomView.Member(lookup.of(m.userId()), m.status(),
                        m.joined() ? room.reactionShown(m.userId(), now).orElse(null) : null,
                        m.userId().equals(viewerId)))
                .toList();
        MemberStatus myStatus = room.members().find(viewerId).map(TogetherMember::status).orElse(MemberStatus.LEFT);
        return new StudyRoomView(room.id(), lookup.of(room.creatorId()), room.length(), room.length().focusMinutes(),
                room.length().breakMinutes(), room.rounds(), moment.phase(), moment.round(), moment.endsAt(),
                room.startedAt(), room.endsAt(), now, myStatus, room.subjectOf(viewerId).orElse(null), members);
    }

    private static int order(MemberStatus status) {
        return switch (status) {
            case JOINED -> 0;
            case INVITED -> 1;
            default -> 2;
        };
    }
}
