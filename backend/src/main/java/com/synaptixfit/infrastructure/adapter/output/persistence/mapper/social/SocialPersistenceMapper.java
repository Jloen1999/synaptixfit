package com.synaptixfit.infrastructure.adapter.output.persistence.mapper.social;

import com.synaptixfit.domain.model.social.Comment;
import com.synaptixfit.domain.model.social.Friendship;
import com.synaptixfit.domain.model.social.FriendshipStatus;
import com.synaptixfit.domain.model.social.Post;
import com.synaptixfit.domain.model.social.PostType;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.social.CommentEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.social.FriendshipEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.social.PostEntity;

/** Modelos sociales de dominio ↔ entidades, y enums ↔ valores de la base de datos. */
public final class SocialPersistenceMapper {

    private SocialPersistenceMapper() {
    }

    // ---------------------------------------------------------------- enums

    public static String postTypeToDb(PostType type) {
        return switch (type) {
            case SESSION_COMPLETED -> "session_completed";
            case CHALLENGE_COMPLETED -> "challenge_completed";
            case MILESTONE_REACHED -> "milestone_reached";
            case BADGE_UNLOCKED -> "badge_unlocked";
            case ROUTINE -> "rutina";
            case CHALLENGE -> "reto";
        };
    }

    public static PostType postTypeFromDb(String value) {
        return switch (value) {
            case "session_completed" -> PostType.SESSION_COMPLETED;
            case "challenge_completed" -> PostType.CHALLENGE_COMPLETED;
            case "badge_unlocked" -> PostType.BADGE_UNLOCKED;
            case "rutina" -> PostType.ROUTINE;
            case "reto" -> PostType.CHALLENGE;
            default -> PostType.MILESTONE_REACHED;
        };
    }

    public static String statusToDb(FriendshipStatus status) {
        return switch (status) {
            case PENDING -> "pendiente";
            case ACCEPTED -> "aceptada";
            case REJECTED -> "rechazada";
            case BLOCKED -> "bloqueada";
        };
    }

    public static FriendshipStatus statusFromDb(String value) {
        return switch (value) {
            case "aceptada" -> FriendshipStatus.ACCEPTED;
            case "rechazada" -> FriendshipStatus.REJECTED;
            case "bloqueada" -> FriendshipStatus.BLOCKED;
            default -> FriendshipStatus.PENDING;
        };
    }

    // ---------------------------------------------------------------- publicaciones

    public static Post toDomain(PostEntity e) {
        return new Post(e.getId(), e.getUsuarioId(), postTypeFromDb(e.getTipo()), e.getDescripcion(), e.getUrlImagen(),
                e.getMetadata(), e.getCreadoEn(), e.getEditadoEn(), Boolean.TRUE.equals(e.getReportado()),
                e.getReportadoPor());
    }

    public static void copyToEntity(Post p, PostEntity e) {
        e.setId(p.id());
        e.setUsuarioId(p.authorId());
        e.setTipo(postTypeToDb(p.type()));
        e.setDescripcion(p.description());
        e.setUrlImagen(p.imageUrl());
        e.setMetadata(p.metadata());
        e.setCreadoEn(p.createdAt());
        e.setEditadoEn(p.editedAt());
        e.setReportado(p.reported());
        e.setReportadoPor(p.reportedBy());
    }

    // ---------------------------------------------------------------- comentarios

    public static Comment toDomain(CommentEntity e) {
        return new Comment(e.getId(), e.getActividadId(), e.getUsuarioId(), e.getTexto(), e.getCreadoEn(),
                e.getEditadoEn(), e.isEliminado(), Boolean.TRUE.equals(e.getReportado()), e.getReportadoPor());
    }

    public static void copyToEntity(Comment c, CommentEntity e) {
        e.setId(c.id());
        e.setActividadId(c.postId());
        e.setUsuarioId(c.authorId());
        e.setTexto(c.text());
        e.setCreadoEn(c.createdAt());
        e.setEditadoEn(c.editedAt());
        e.setEliminado(c.deleted());
        e.setReportado(c.reported());
        e.setReportadoPor(c.reportedBy());
    }

    // ---------------------------------------------------------------- amistades

    public static Friendship toDomain(FriendshipEntity e) {
        return new Friendship(e.getId(), e.getSolicitanteId(), e.getReceptorId(), statusFromDb(e.getEstado()),
                e.getCreadoEn(), e.getActualizadoEn());
    }

    public static void copyToEntity(Friendship f, FriendshipEntity e) {
        e.setId(f.id());
        e.setSolicitanteId(f.requesterId());
        e.setReceptorId(f.addresseeId());
        e.setEstado(statusToDb(f.status()));
        e.setCreadoEn(f.createdAt());
        e.setActualizadoEn(f.updatedAt());
    }
}
