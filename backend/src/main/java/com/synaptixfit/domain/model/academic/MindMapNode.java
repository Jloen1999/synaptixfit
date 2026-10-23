package com.synaptixfit.domain.model.academic;

import java.util.List;

/** Nodo de un mapa mental: etiqueta concisa y sus hijos. */
public record MindMapNode(String title, List<MindMapNode> children) {

    public MindMapNode {
        String t = title == null ? "" : title.strip();
        title = t.length() > MindMap.MAX_LABEL ? t.substring(0, MindMap.MAX_LABEL) + "…" : t;
        children = children == null ? List.of() : List.copyOf(children);
    }
}
