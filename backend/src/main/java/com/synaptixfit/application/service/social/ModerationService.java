package com.synaptixfit.application.service.social;

import com.synaptixfit.application.port.input.social.DismissReportUseCase;
import com.synaptixfit.application.port.input.social.ListReportedContentUseCase;
import com.synaptixfit.application.port.input.social.RemoveReportedContentUseCase;
import com.synaptixfit.domain.exception.social.CommentNotFoundException;
import com.synaptixfit.domain.exception.social.PostNotFoundException;
import com.synaptixfit.domain.exception.social.UserReportNotFoundException;
import com.synaptixfit.domain.model.shared.Guard;
import com.synaptixfit.domain.model.shared.PageRequest;
import com.synaptixfit.domain.model.shared.PageResult;
import com.synaptixfit.domain.model.social.Comment;
import com.synaptixfit.domain.model.social.Post;
import com.synaptixfit.domain.model.social.ReportedContent;
import com.synaptixfit.domain.model.social.ReportedContentType;
import com.synaptixfit.domain.port.output.social.CommentRepositoryPort;
import com.synaptixfit.domain.port.output.social.ModerationAuditPort;
import com.synaptixfit.domain.port.output.social.PostRepositoryPort;
import com.synaptixfit.domain.port.output.social.ReportedContentQueryPort;
import com.synaptixfit.domain.port.output.social.UserReportRepositoryPort;
import java.util.Map;
import java.util.UUID;

/**
 * Moderación de contenido reportado (solo administradores; la ruta ya está protegida). Cada
 * acción queda en {@code admin_auditoria} con las mismas acciones que el sistema anterior. Una denuncia de una persona
 * (ADR 0044) no tiene contenido que borrar: aprobarla o retirarla la quita de la cola, y lo que haga falta con la
 * cuenta se hace desde la administración de usuarios.
 */
public class ModerationService implements ListReportedContentUseCase, DismissReportUseCase,
        RemoveReportedContentUseCase {

    static final String ACTION_DISMISS = "aprobar_contenido";
    static final String ACTION_REMOVE = "eliminar_contenido";
    static final String ENTITY_POST = "actividades_sociales";
    static final String ENTITY_COMMENT = "comentarios_feed";
    static final String ENTITY_USER_REPORT = "denuncias_usuario";

    private final PostRepositoryPort posts;
    private final CommentRepositoryPort comments;
    private final ReportedContentQueryPort reported;
    private final ModerationAuditPort audit;
    private final UserReportRepositoryPort userReports;

    public ModerationService(PostRepositoryPort posts, CommentRepositoryPort comments,
                             ReportedContentQueryPort reported, ModerationAuditPort audit,
                             UserReportRepositoryPort userReports) {
        this.posts = posts;
        this.comments = comments;
        this.reported = reported;
        this.audit = audit;
        this.userReports = userReports;
    }

    @Override
    public PageResult<ReportedContent> listReported(ReportedContentType type, PageRequest page) {
        return reported.findReported(type, page);
    }

    @Override
    public void dismiss(UUID adminId, ReportedContentType type, UUID contentId) {
        if (Guard.notNull(type, "type") == ReportedContentType.USER) {
            resolveUserReport(adminId, ACTION_DISMISS, contentId);
        } else if (type == ReportedContentType.POST) {
            Post post = post(contentId);
            post.dismissReport();
            posts.save(post);
            record(adminId, ACTION_DISMISS, ENTITY_POST, contentId, post.authorId());
        } else {
            Comment comment = comment(contentId);
            comment.dismissReport();
            comments.save(comment);
            record(adminId, ACTION_DISMISS, ENTITY_COMMENT, contentId, comment.authorId());
        }
    }

    /** Las publicaciones se borran de verdad; los comentarios, de forma lógica. */
    @Override
    public void remove(UUID adminId, ReportedContentType type, UUID contentId) {
        if (Guard.notNull(type, "type") == ReportedContentType.USER) {
            resolveUserReport(adminId, ACTION_REMOVE, contentId);
        } else if (type == ReportedContentType.POST) {
            Post post = post(contentId);
            posts.delete(post.id());
            record(adminId, ACTION_REMOVE, ENTITY_POST, contentId, post.authorId());
        } else {
            Comment comment = comment(contentId);
            comment.removeByModerator();
            comments.save(comment);
            record(adminId, ACTION_REMOVE, ENTITY_COMMENT, contentId, comment.authorId());
        }
    }

    private void resolveUserReport(UUID adminId, String action, UUID reportId) {
        if (!userReports.delete(reportId)) {
            throw new UserReportNotFoundException(reportId);
        }
        audit.record(adminId, action, ENTITY_USER_REPORT, reportId, Map.of());
    }

    private Post post(UUID id) {
        return posts.findById(id).orElseThrow(() -> new PostNotFoundException(id));
    }

    private Comment comment(UUID id) {
        return comments.findById(id).filter(c -> !c.deleted()).orElseThrow(() -> new CommentNotFoundException(id));
    }

    private void record(UUID adminId, String action, String entity, UUID entityId, UUID authorId) {
        audit.record(adminId, action, entity, entityId, Map.of("autor_id", authorId.toString()));
    }
}
