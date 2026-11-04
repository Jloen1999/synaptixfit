package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import com.synaptixfit.domain.model.training.RoutineTemplate;
import com.synaptixfit.domain.model.training.TrainingGoal;
import com.synaptixfit.domain.port.output.training.RoutineTemplateRepositoryPort;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.TreeMap;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Component;

/**
 * Implementa {@link RoutineTemplateRepositoryPort} sobre {@code plantillas_rutina}, sus textos y sus ejercicios
 * (V1034-V1035). Los textos se toman en el idioma pedido y, si faltan, en español.
 */
@Component
public class RoutineTemplateJdbcAdapter implements RoutineTemplateRepositoryPort {

    private static final String FALLBACK = "es";

    private final JdbcClient jdbc;

    public RoutineTemplateJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    private record Head(UUID id, String code, TrainingGoal goal, boolean atHome, boolean forExams, int minutes,
                        int weeks) {
    }

    @Override
    public List<RoutineTemplate> findAll(String language) {
        List<Head> heads = jdbc.sql("SELECT id, codigo, objetivo, en_casa, para_examenes, minutos, semanas"
                        + " FROM plantillas_rutina ORDER BY orden, codigo")
                .query((rs, n) -> new Head(rs.getObject("id", UUID.class), rs.getString("codigo"),
                        TrainingGoal.valueOf(rs.getString("objetivo")), rs.getBoolean("en_casa"),
                        rs.getBoolean("para_examenes"), rs.getInt("minutos"), rs.getInt("semanas")))
                .list();
        return assemble(heads, language);
    }

    @Override
    public Optional<RoutineTemplate> findById(UUID templateId, String language) {
        return findAll(language).stream().filter(t -> t.id().equals(templateId)).findFirst();
    }

    private List<RoutineTemplate> assemble(List<Head> heads, String language) {
        if (heads.isEmpty()) {
            return List.of();
        }
        Collection<UUID> ids = heads.stream().map(Head::id).toList();
        Map<UUID, String[]> texts = new LinkedHashMap<>();
        jdbc.sql("SELECT plantilla_id, idioma, nombre, descripcion FROM plantillas_rutina_textos"
                        + " WHERE plantilla_id IN (:ids) AND idioma IN (:lang, :fallback)")
                .param("ids", ids)
                .param("lang", language)
                .param("fallback", FALLBACK)
                .query((rs, n) -> {
                    UUID id = rs.getObject("plantilla_id", UUID.class);
                    boolean preferred = language.equals(rs.getString("idioma"));
                    if (preferred || !texts.containsKey(id)) {
                        texts.put(id, new String[] {rs.getString("nombre"), rs.getString("descripcion")});
                    }
                    return null;
                })
                .list();
        Map<UUID, Map<Integer, List<RoutineTemplate.Item>>> days = new LinkedHashMap<>();
        jdbc.sql("SELECT plantilla_id, dia, ejercicio_id, series, repeticiones, descanso_segundos,"
                        + " segundos_isometricos FROM plantillas_rutina_ejercicios WHERE plantilla_id IN (:ids)"
                        + " ORDER BY plantilla_id, dia, orden")
                .param("ids", ids)
                .query((rs, n) -> {
                    int hold = rs.getInt("segundos_isometricos");
                    Integer holdSeconds = rs.wasNull() ? null : hold;
                    days.computeIfAbsent(rs.getObject("plantilla_id", UUID.class), k -> new TreeMap<>())
                            .computeIfAbsent(rs.getInt("dia"), k -> new ArrayList<>())
                            .add(new RoutineTemplate.Item(rs.getObject("ejercicio_id", UUID.class),
                                    rs.getInt("series"), rs.getInt("repeticiones"), rs.getInt("descanso_segundos"),
                                    holdSeconds));
                    return null;
                })
                .list();
        List<RoutineTemplate> result = new ArrayList<>();
        for (Head h : heads) {
            String[] text = texts.getOrDefault(h.id(), new String[] {h.code(), ""});
            List<RoutineTemplate.Day> templateDays = days.getOrDefault(h.id(), Map.of()).entrySet().stream()
                    .map(e -> new RoutineTemplate.Day(e.getKey(), e.getValue()))
                    .toList();
            result.add(new RoutineTemplate(h.id(), h.code(), text[0], text[1], h.goal(), h.atHome(), h.forExams(),
                    h.minutes(), h.weeks(), templateDays));
        }
        return result;
    }
}
