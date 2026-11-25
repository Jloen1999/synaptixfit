package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.social;

import com.synaptixfit.domain.model.social.Post;
import com.synaptixfit.domain.model.social.PostType;
import com.synaptixfit.domain.port.output.social.PostRepositoryPort;
import com.synaptixfit.infrastructure.adapter.output.persistence.entity.social.PostEntity;
import com.synaptixfit.infrastructure.adapter.output.persistence.mapper.social.SocialPersistenceMapper;
import com.synaptixfit.infrastructure.adapter.output.persistence.repository.social.PostJpaRepository;
import java.sql.Timestamp;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Implementa {@link PostRepositoryPort} con JPA. Las escrituras se vuelcan al momento porque las
 * lecturas compuestas del módulo usan JDBC dentro de la misma transacción.
 */
@Repository
public class PostPersistenceAdapter implements PostRepositoryPort {

    private final PostJpaRepository repository;
    private final JdbcClient jdbc;

    public PostPersistenceAdapter(PostJpaRepository repository, JdbcClient jdbc) {
        this.repository = repository;
        this.jdbc = jdbc;
    }

    @Override
    public Optional<Post> findById(UUID id) {
        return repository.findById(id).map(SocialPersistenceMapper::toDomain);
    }

    @Override
    public Post save(Post post) {
        PostEntity entity = repository.findById(post.id()).orElseGet(PostEntity::new);
        SocialPersistenceMapper.copyToEntity(post, entity);
        return SocialPersistenceMapper.toDomain(repository.saveAndFlush(entity));
    }

    @Override
    public boolean existsByAuthorTypeAndMetadata(UUID userId, PostType type, String metadata) {
        return repository.existsByUsuarioIdAndTipoAndMetadata(userId, SocialPersistenceMapper.postTypeToDb(type),
                metadata);
    }

    /**
     * Inserta y deja que el índice único decida (`ON CONFLICT DO NOTHING`, propio de PostgreSQL, listado en
     * {@code database_portability.md}): dos peticiones a la vez no duplican la publicación de un apunte y la que llega
     * tarde se entera de que ya existía, sin romper la transacción.
     */
    @Override
    public boolean saveIfAbsent(Post post) {
        repository.flush();
        int inserted = jdbc.sql("""
                        INSERT INTO actividades_sociales (id, usuario_id, tipo, descripcion, url_imagen, creado_en,
                                                          metadata, reportado, reportado_por, editado_en)
                        VALUES (:id, :userId, :type, :description, :imageUrl, :createdAt, :metadata, :reported,
                                :reportedBy, :editedAt)
                        ON CONFLICT DO NOTHING""")
                .param("id", post.id())
                .param("userId", post.authorId())
                .param("type", SocialPersistenceMapper.postTypeToDb(post.type()))
                .param("description", post.description())
                .param("imageUrl", post.imageUrl())
                .param("createdAt", Timestamp.from(post.createdAt()))
                .param("metadata", post.metadata())
                .param("reported", post.reported())
                .param("reportedBy", post.reportedBy())
                .param("editedAt", post.editedAt() == null ? null : Timestamp.from(post.editedAt()))
                .update();
        return inserted > 0;
    }

    @Override
    public void deleteByAuthorTypeAndMetadata(UUID userId, PostType type, String metadata) {
        repository.deleteByAuthorTypeAndMetadata(userId, SocialPersistenceMapper.postTypeToDb(type), metadata);
    }

    @Override
    public void delete(UUID id) {
        repository.deleteById(id);
        repository.flush();
    }
}
