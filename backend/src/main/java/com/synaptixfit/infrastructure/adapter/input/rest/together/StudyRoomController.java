package com.synaptixfit.infrastructure.adapter.input.rest.together;

import com.synaptixfit.application.port.input.together.ChooseStudyRoomSubjectUseCase;
import com.synaptixfit.application.port.input.together.CreateStudyRoomUseCase;
import com.synaptixfit.application.port.input.together.DeclineStudyRoomUseCase;
import com.synaptixfit.application.port.input.together.GetStudyRoomUseCase;
import com.synaptixfit.application.port.input.together.JoinStudyRoomUseCase;
import com.synaptixfit.application.port.input.together.LeaveStudyRoomUseCase;
import com.synaptixfit.application.port.input.together.ReactStudyRoomUseCase;
import com.synaptixfit.application.port.input.together.StartStudyRoomUseCase;
import com.synaptixfit.infrastructure.adapter.input.rest.support.CurrentUserId;
import com.synaptixfit.infrastructure.adapter.input.rest.together.dto.CreateStudyRoomRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.together.dto.StudyRoomReactionRequest;
import com.synaptixfit.infrastructure.adapter.input.rest.together.dto.StudyRoomResponse;
import com.synaptixfit.infrastructure.adapter.input.rest.together.dto.StudyRoomSubjectRequest;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/**
 * «Estudiamos juntos» (ADR 0045): sala de 2 a 5 amigos con un temporizador común calculado por el servidor. El
 * cliente consulta cada pocos segundos mientras la pantalla está abierta (sin WebSocket). Solo entre amigos mutuos;
 * lo ajeno, o de lo que se salió, es 404.
 */
@Tag(name = "Social - Together")
@RestController
@RequestMapping("/api/v1/together/study-rooms")
public class StudyRoomController {

    private final CreateStudyRoomUseCase create;
    private final GetStudyRoomUseCase get;
    private final JoinStudyRoomUseCase join;
    private final DeclineStudyRoomUseCase decline;
    private final LeaveStudyRoomUseCase leave;
    private final StartStudyRoomUseCase start;
    private final ChooseStudyRoomSubjectUseCase chooseSubject;
    private final ReactStudyRoomUseCase react;

    @SuppressWarnings("java:S107")
    public StudyRoomController(CreateStudyRoomUseCase create, GetStudyRoomUseCase get, JoinStudyRoomUseCase join,
                               DeclineStudyRoomUseCase decline, LeaveStudyRoomUseCase leave,
                               StartStudyRoomUseCase start, ChooseStudyRoomSubjectUseCase chooseSubject,
                               ReactStudyRoomUseCase react) {
        this.create = create;
        this.get = get;
        this.join = join;
        this.decline = decline;
        this.leave = leave;
        this.start = start;
        this.chooseSubject = chooseSubject;
        this.react = react;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public StudyRoomResponse create(@CurrentUserId UUID userId, @Valid @RequestBody CreateStudyRoomRequest request) {
        return StudyRoomResponse.from(create.create(new CreateStudyRoomUseCase.Command(userId, request.length(),
                request.rounds(), request.friendIds(), request.subjectId())));
    }

    @GetMapping("/{roomId}")
    public StudyRoomResponse room(@CurrentUserId UUID userId, @PathVariable UUID roomId) {
        return StudyRoomResponse.from(get.get(userId, roomId));
    }

    /** Acepta la invitación (o vuelve tras salir: «Deshacer»). */
    @PostMapping("/{roomId}/join")
    public StudyRoomResponse join(@CurrentUserId UUID userId, @PathVariable UUID roomId) {
        return StudyRoomResponse.from(join.join(userId, roomId));
    }

    @PostMapping("/{roomId}/decline")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void decline(@CurrentUserId UUID userId, @PathVariable UUID roomId) {
        decline.decline(userId, roomId);
    }

    @PostMapping("/{roomId}/leave")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void leave(@CurrentUserId UUID userId, @PathVariable UUID roomId) {
        leave.leave(userId, roomId);
    }

    /** Empieza el temporizador común (cualquiera de dentro, una vez). */
    @PostMapping("/{roomId}/start")
    public StudyRoomResponse start(@CurrentUserId UUID userId, @PathVariable UUID roomId) {
        return StudyRoomResponse.from(start.start(userId, roomId));
    }

    @PutMapping("/{roomId}/subject")
    public StudyRoomResponse subject(@CurrentUserId UUID userId, @PathVariable UUID roomId,
                                     @RequestBody StudyRoomSubjectRequest request) {
        return StudyRoomResponse.from(chooseSubject.chooseSubject(userId, roomId, request.subjectId()));
    }

    @PutMapping("/{roomId}/reaction")
    public StudyRoomResponse reaction(@CurrentUserId UUID userId, @PathVariable UUID roomId,
                                      @Valid @RequestBody StudyRoomReactionRequest request) {
        return StudyRoomResponse.from(react.react(userId, roomId, request.reaction()));
    }
}
