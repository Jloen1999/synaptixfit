package com.synaptixfit.domain.model.academic;

import java.util.ArrayList;
import java.util.List;

/**
 * Mapa mental: un tema central y sus ramas. Profundidad máxima 3 niveles bajo el centro y
 * etiquetas de hasta 40 caracteres (las más largas se recortan con «…»).
 */
public record MindMap(String central, List<MindMapNode> branches) {

    public static final int MAX_DEPTH = 3;
    static final int MAX_LABEL = 40;

    public MindMap {
        central = central == null || central.isBlank() ? "Mapa mental" : central.strip();
        branches = branches == null ? List.of() : List.copyOf(prune(branches, 1));
    }

    public boolean isEmpty() {
        return branches.isEmpty();
    }

    private static List<MindMapNode> prune(List<MindMapNode> nodes, int depth) {
        List<MindMapNode> result = new ArrayList<>();
        for (MindMapNode n : nodes) {
            if (n == null || n.title().isBlank()) {
                continue;
            }
            List<MindMapNode> children = depth < MAX_DEPTH ? prune(n.children(), depth + 1) : List.of();
            result.add(new MindMapNode(n.title(), children));
        }
        return result;
    }

    /**
     * Construye el mapa desde el formato que devuelve la IA: una línea por nodo con guion y
     * dos espacios de sangría por nivel. Las líneas que saltan niveles se ignoran.
     */
    public static MindMap fromIndentedMarkdown(String title, String markdown) {
        List<Line> lines = new ArrayList<>();
        for (String raw : (markdown == null ? "" : markdown).split("\n")) {
            String trimmed = raw.stripLeading();
            if (trimmed.isBlank()) {
                continue;
            }
            int level = (raw.length() - trimmed.length()) / 2;
            String label = trimmed.startsWith("- ") || trimmed.startsWith("* ")
                    ? trimmed.substring(2).strip() : trimmed.strip();
            if (!label.isEmpty()) {
                lines.add(new Line(level, label));
            }
        }
        int[] index = {0};
        // El primer nivel (0) es el nodo central del Markdown; sus hijos son las ramas.
        List<MindMapNode> roots = parse(lines, index, 0, 0);
        List<MindMapNode> branches = roots.size() == 1 && !roots.getFirst().children().isEmpty()
                ? roots.getFirst().children() : roots;
        String central = title != null && !title.isBlank() ? title
                : roots.size() == 1 ? roots.getFirst().title() : null;
        return new MindMap(central, branches);
    }

    private static List<MindMapNode> parse(List<Line> lines, int[] index, int level, int depth) {
        List<MindMapNode> nodes = new ArrayList<>();
        while (index[0] < lines.size()) {
            Line line = lines.get(index[0]);
            if (line.level() < level) {
                break;
            }
            if (line.level() > level) {
                index[0]++;
                continue;
            }
            index[0]++;
            List<MindMapNode> children = depth <= MAX_DEPTH ? parse(lines, index, level + 1, depth + 1) : List.of();
            nodes.add(new MindMapNode(line.label(), children));
        }
        return nodes;
    }

    /** Serializa el mapa como apunte Markdown (título, una sección por rama y viñetas anidadas). */
    public String toMarkdown() {
        StringBuilder sb = new StringBuilder("# ").append(central).append("\n\n");
        for (MindMapNode branch : branches) {
            sb.append("## ").append(branch.title()).append('\n');
            appendChildren(sb, branch, "");
            sb.append('\n');
        }
        return sb.toString().strip() + "\n";
    }

    private static void appendChildren(StringBuilder sb, MindMapNode node, String indent) {
        for (MindMapNode child : node.children()) {
            sb.append(indent).append("- ").append(child.title()).append('\n');
            appendChildren(sb, child, indent + "  ");
        }
    }

    private record Line(int level, String label) {
    }
}
