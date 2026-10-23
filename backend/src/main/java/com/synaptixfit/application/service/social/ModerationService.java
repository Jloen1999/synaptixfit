package com.synaptixfit.application.service.social;

import com.synaptixfit.application.port.input.social.DismissReportUseCase;
import com.synaptixfit.application.port.input.social.ListReportedContentUseCase;
import com.synaptixfit.application.port.input.social.RemoveReportedContentUseCase;
import com.synaptixfit.domain.exception.social.CommentNotFoundException;
import com.synaptixfit.domain.exception.social.PostNotFoundException;
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
import java.util.Map;
import java.util.UUID;

/**
 * Moderación de contenido reportado (solo administradores; la ruta ya está protegida). Cada
 * acción queda en {@code admin_auditoria} con las mismas acciones que el sistema anterior.
 */
public class ModerationService implements ListReportedContentUseCase, DismissReportUseCase,
        RemoveReportedContentUseCase {

    static final String ACTION_DISMISS = "aprobar_contenido";
    static final String ACTION_REMOVE = "eliminar_contenido";
    static final String ENTITY_POST = "actividades_sociales";
    static final String ENTITY_COMMENT = "comentarios_feed";

    private final PostRepositoryPort posts;
    private final CommentRepositoryPort comments;
    private final ReportedContentQueryPort reported;
    private final ModerationAuditPort audit;

    public ModerationService(PostRepositoryPort posts, CommentRepositoryPort comments,
                             ReportedContentQueryPort reported, ModerationAuditPort audit) {
        this.posts = posts;
        this.comments = comments;
        this.reported = reported;
        this.audit = audit;
    }

    @Override
    public PageResult<ReportedContent> listReported(ReportedContentType type, PageRequest page) {
        return reported.findReported(type, page);
    }

    @Override
    public void dismiss(UUID adminId, ReportedContentType type, UUID contentId) {
        if (Guard.notNull(type, "type") == ReportedContentType.POST) {
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
        if (Guard.notNull(type, "type") == ReportedContentType.POST) {
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
