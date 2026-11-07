package com.synaptixfit.infrastructure.adapter.output.persistence.adapter.run;

import com.synaptixfit.domain.model.run.KmSplit;
import com.synaptixfit.domain.model.run.RunStep;
import com.synaptixfit.domain.model.run.RunWorkout;
import com.synaptixfit.domain.model.run.TrackPoint;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.json.JsonMapper;

/**
 * Convierte a JSON (columnas {@code jsonb}) la ruta, los tramos por km y los pasos de un entreno de carrera. La ruta
 * va en forma compacta, un array por punto: {@code [lat, lon, altitud|null, precisión, segundos, segmento]}.
 */
final class RunJsonCodec {

    private static final TypeReference<List<List<Number>>> ROUTE = new TypeReference<>() { };
    private static final TypeReference<List<Map<String, Object>>> OBJECTS = new TypeReference<>() { };

    private final JsonMapper json;

    RunJsonCodec(JsonMapper json) {
        this.json = json;
    }

    String route(List<TrackPoint> points) {
        List<List<Object>> rows = new ArrayList<>(points.size());
        for (TrackPoint p : points) {
            List<Object> row = new ArrayList<>(6);
            row.add(p.latitude());
            row.add(p.longitude());
            row.add(p.altitude());
            row.add(p.accuracy());
            row.add(p.offsetSeconds());
            row.add(p.segment());
            rows.add(row);
        }
        return json.writeValueAsString(rows);
    }

    List<TrackPoint> route(String value) {
        List<TrackPoint> points = new ArrayList<>();
        for (List<Number> row : json.readValue(value, ROUTE)) {
            Number altitude = row.get(2);
            points.add(new TrackPoint(row.get(0).doubleValue(), row.get(1).doubleValue(),
                    altitude == null ? null : altitude.doubleValue(), row.get(3).doubleValue(),
                    row.get(4).doubleValue(), row.get(5).intValue()));
        }
        return points;
    }

    String splits(List<KmSplit> splits) {
        List<Map<String, Object>> rows = new ArrayList<>();
        for (KmSplit s : splits) {
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("number", s.number());
            row.put("distanceMeters", s.distanceMeters());
            row.put("seconds", s.seconds());
            rows.add(row);
        }
        return json.writeValueAsString(rows);
    }

    List<KmSplit> splits(String value) {
        return json.readValue(value, OBJECTS).stream()
                .map(r -> new KmSplit(((Number) r.get("number")).intValue(),
                        ((Number) r.get("distanceMeters")).intValue(), ((Number) r.get("seconds")).intValue()))
                .toList();
    }

    String groups(List<RunWorkout.Group> groups) {
        List<Map<String, Object>> rows = new ArrayList<>();
        for (RunWorkout.Group g : groups) {
            List<Map<String, Object>> steps = new ArrayList<>();
            for (RunStep s : g.steps()) {
                Map<String, Object> step = new LinkedHashMap<>();
                step.put("type", s.type().name());
                step.put("measure", s.measure().name());
                step.put("value", s.value());
                steps.add(step);
            }
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("repeat", g.repeat());
            row.put("steps", steps);
            rows.add(row);
        }
        return json.writeValueAsString(rows);
    }

    @SuppressWarnings("unchecked")
    List<RunWorkout.Group> groups(String value) {
        return json.readValue(value, OBJECTS).stream()
                .map(r -> new RunWorkout.Group(((Number) r.get("repeat")).intValue(),
                        ((List<Map<String, Object>>) r.get("steps")).stream()
                                .map(s -> new RunStep(RunStep.Type.valueOf((String) s.get("type")),
                                        RunStep.Measure.valueOf((String) s.get("measure")),
                                        ((Number) s.get("value")).intValue()))
                                .toList()))
                .toList();
    }
}
