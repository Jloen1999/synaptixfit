package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.training;

import com.synaptixfit.domain.model.training.RoutineTemplate;
import com.synaptixfit.domain.model.training.TemplateLevel;
import com.synaptixfit.domain.model.training.TemplatePlace;
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
 * (V1034-V1035), sus días de carrera y el nombre de esos entrenos (V1060-V1061), y desde V1072 si está activa, el
 * rango de repeticiones de cada ejercicio, el nombre de cada sesión y la semana de cada salida a correr (ADR 0054). Los
 * textos se toman en el idioma pedido y, si faltan, en español.
 */
@Component
public class RoutineTemplateJdbcAdapter implements RoutineTemplateRepositoryPort {

    private static final String FALLBACK = "es";

    private final JdbcClient jdbc;

    public RoutineTemplateJdbcAdapter(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    private record Head(UUID id, String code, TrainingGoal goal, TemplatePlace place, TemplateLevel level,
                        boolean forExams, int minutes, int weeks, boolean active) {
    }

    @Override
    public List<RoutineTemplate> findAll(String language) {
        List<Head> heads = jdbc.sql("SELECT id, codigo, objetivo, lugar, nivel, para_examenes, minutos, semanas,"
                        + " activa FROM plantillas_rutina ORDER BY orden, codigo")
                .query((rs, n) -> new Head(rs.getObject("id", UUID.class), rs.getString("codigo"),
                        TrainingGoal.valueOf(rs.getString("objetivo")), TemplatePlace.valueOf(rs.getString("lugar")),
                        TemplateLevel.valueOf(rs.getString("nivel")), rs.getBoolean("para_examenes"),
                        rs.getInt("minutos"), rs.getInt("semanas"), rs.getBoolean("activa")))
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
                        + " segundos_isometricos, rep_min, rep_max, rir_objetivo FROM plantillas_rutina_ejercicios"
                        + " WHERE plantilla_id IN (:ids)"
                        + " ORDER BY plantilla_id, dia, orden")
                .param("ids", ids)
                .query((rs, n) -> {
                    int hold = rs.getInt("segundos_isometricos");
                    Integer holdSeconds = rs.wasNull() ? null : hold;
                    days.computeIfAbsent(rs.getObject("plantilla_id", UUID.class), k -> new TreeMap<>())
                            .computeIfAbsent(rs.getInt("dia"), k -> new ArrayList<>())
                            .add(new RoutineTemplate.Item(rs.getObject("ejercicio_id", UUID.class),
                                    rs.getInt("series"), rs.getInt("repeticiones"), rs.getInt("descanso_segundos"),
                                    holdSeconds, rs.getObject("rep_min", Integer.class),
                                    rs.getObject("rep_max", Integer.class), rs.getObject("rir_objetivo", Integer.class)));
                    return null;
                })
                .list();
        Map<UUID, Map<Integer, String>> dayNames = new LinkedHashMap<>();
        Map<UUID, Map<Integer, Boolean>> dayNamePreferred = new LinkedHashMap<>();
        jdbc.sql("SELECT plantilla_id, dia, idioma, nombre FROM plantillas_rutina_dias_textos"
                        + " WHERE plantilla_id IN (:ids) AND idioma IN (:lang, :fallback)")
                .param("ids", ids)
                .param("lang", language)
                .param("fallback", FALLBACK)
                .query((rs, n) -> {
                    UUID id = rs.getObject("plantilla_id", UUID.class);
                    int day = rs.getInt("dia");
                    boolean preferred = language.equals(rs.getString("idioma"));
                    Map<Integer, Boolean> seen = dayNamePreferred.computeIfAbsent(id, k -> new LinkedHashMap<>());
                    if (preferred || !seen.containsKey(day)) {
                        dayNames.computeIfAbsent(id, k -> new LinkedHashMap<>()).put(day, rs.getString("nombre"));
                        seen.put(day, preferred || seen.getOrDefault(day, false));
                    }
                    return null;
                })
                .list();
        Map<String, String> runNames = new LinkedHashMap<>();
        jdbc.sql("SELECT codigo, idioma, nombre FROM nombres_entreno_carrera WHERE idioma IN (:lang, :fallback)")
                .param("lang", language)
                .param("fallback", FALLBACK)
                .query((rs, n) -> {
                    if (language.equals(rs.getString("idioma")) || !runNames.containsKey(rs.getString("codigo"))) {
                        runNames.put(rs.getString("codigo"), rs.getString("nombre"));
                    }
                    return null;
                })
                .list();
        Map<UUID, List<RoutineTemplate.RunDay>> runs = new LinkedHashMap<>();
        jdbc.sql("SELECT plantilla_id, semana, dia, codigo_entreno FROM plantillas_rutina_carreras"
                        + " WHERE plantilla_id IN (:ids) ORDER BY plantilla_id, semana, dia")
                .param("ids", ids)
                .query((rs, n) -> {
                    String code = rs.getString("codigo_entreno");
                    runs.computeIfAbsent(rs.getObject("plantilla_id", UUID.class), k -> new ArrayList<>())
                            .add(new RoutineTemplate.RunDay(rs.getInt("dia"), code, runNames.get(code),
                                    rs.getInt("semana")));
                    return null;
                })
                .list();
        List<RoutineTemplate> result = new ArrayList<>();
        for (Head h : heads) {
            String[] text = texts.getOrDefault(h.id(), new String[] {h.code(), ""});
            List<RoutineTemplate.Day> templateDays = days.getOrDefault(h.id(), Map.of()).entrySet().stream()
                    .map(e -> new RoutineTemplate.Day(e.getKey(),
                            dayNames.getOrDefault(h.id(), Map.of()).get(e.getKey()), e.getValue()))
                    .toList();
            result.add(new RoutineTemplate(h.id(), h.code(), text[0], text[1], h.goal(), h.place(), h.level(),
                    h.forExams(), h.minutes(), h.weeks(), templateDays, runs.getOrDefault(h.id(), List.of()),
                    h.active()));
        }
        return result;
    }
}
