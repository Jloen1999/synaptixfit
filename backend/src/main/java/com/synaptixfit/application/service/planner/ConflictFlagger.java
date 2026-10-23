package com.synaptixfit.application.service.planner;

import com.synaptixfit.domain.model.planner.CalendarBlock;
import com.synaptixfit.domain.model.planner.ScheduleConflicts;
import com.synaptixfit.domain.port.output.planner.CalendarBlockRepositoryPort;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Mantiene al día la marca {@code tiene_conflicto} de los bloques afectados por un cambio (los
 * propios y sus vecinos), comparando cada uno con todos los bloques que lo tocan.
 */
final class ConflictFlagger {

    private final CalendarBlockRepositoryPort blocks;

    ConflictFlagger(CalendarBlockRepositoryPort blocks) {
        this.blocks = blocks;
    }

    /**
     * Recalcula y guarda la marca de los bloques {@code affected} (ya guardados) y de los bloques
     * {@code formerNeighbours} (que podían solaparse con la posición anterior).
     */
    void refresh(UUID userId, Collection<CalendarBlock> affected, Collection<CalendarBlock> formerNeighbours) {
        Map<UUID, CalendarBlock> targets = new LinkedHashMap<>();
        formerNeighbours.forEach(b -> targets.put(b.id(), b));
        affected.forEach(b -> targets.put(b.id(), b));
        if (targets.isEmpty()) {
            return;
        }
        Instant from = targets.values().stream().map(CalendarBlock::start).min(Instant::compareTo).orElseThrow();
        Instant to = targets.values().stream().map(CalendarBlock::end).max(Instant::compareTo).orElseThrow();
        Map<UUID, CalendarBlock> window = new LinkedHashMap<>();
        for (CalendarBlock b : blocks.findOverlapping(userId, from, to, null)) {
            window.put(b.id(), b);
        }
        // Las versiones en memoria mandan sobre las leídas (pueden estar pendientes de guardar).
        window.putAll(targets);
        List<CalendarBlock> candidates = new ArrayList<>(window.values());
        List<CalendarBlock> changed = new ArrayList<>();
        for (CalendarBlock target : targets.values()) {
            CalendarBlock current = window.get(target.id());
            if (current == null) {
                continue;
            }
            boolean conflict = !ScheduleConflicts.overlapping(current.range(), candidates, current.id()).isEmpty();
            if (conflict != current.hasConflict()) {
                current.flagConflict(conflict);
                changed.add(current);
            }
        }
        if (!changed.isEmpty()) {
            blocks.saveAll(changed);
        }
    }

    /** Bloques que se solapan con {@code block} (excluido él mismo). */
    List<CalendarBlock> neighboursOf(CalendarBlock block) {
        return ScheduleConflicts.overlapping(block.range(),
                blocks.findOverlapping(block.userId(), block.start(), block.end(), null), block.id());
    }
}
