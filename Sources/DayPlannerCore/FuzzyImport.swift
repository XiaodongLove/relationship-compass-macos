import Foundation

/// Local heuristic parser: turns a fuzzy Chinese/English work description into titled drafts with priorities.
public enum FuzzyImport {
    public static func parse(_ text: String) -> [FuzzyDraft] {
        let chunks = splitIntoChunks(text)
        guard !chunks.isEmpty else { return [] }

        return chunks.enumerated().compactMap { index, raw in
            let cleaned = cleanTitle(raw)
            guard !cleaned.isEmpty else { return nil }
            let (title, keywordPriority) = extractPriority(from: cleaned)
            guard !title.isEmpty else { return nil }
            let priority = keywordPriority ?? positionalPriority(index: index, total: chunks.count)
            return FuzzyDraft(title: title, priority: priority)
        }
    }

    private static func splitIntoChunks(_ text: String) -> [String] {
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")

        var parts: [String] = []
        for line in normalized.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            // Prefer explicit list breaks; otherwise keep the line, then soft-split long sentences.
            if looksLikeListItem(trimmed) || trimmed.count < 40 {
                parts.append(stripListMarker(trimmed))
            } else {
                let soft = softSplit(trimmed)
                if soft.count > 1 {
                    parts.append(contentsOf: soft)
                } else {
                    parts.append(trimmed)
                }
            }
        }

        // If the whole input was one prose blob without newlines, soft-split it.
        if parts.count == 1, let only = parts.first, only.count > 48, !looksLikeListItem(only) {
            let soft = softSplit(only)
            if soft.count > 1 { return soft.map { stripListMarker($0) }.filter { !$0.isEmpty } }
        }

        return parts.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private static func looksLikeListItem(_ line: String) -> Bool {
        let patterns = [
            #"^[-*•·]\s+"#,
            #"^\d+[\.\)、]\s*"#,
            #"^[（(]?[一二三四五六七八九十]+[）)、\.]\s*"#,
        ]
        return patterns.contains { line.range(of: $0, options: .regularExpression) != nil }
    }

    private static func stripListMarker(_ line: String) -> String {
        var s = line
        let patterns = [
            #"^[-*•·]\s+"#,
            #"^\d+[\.\)、]\s*"#,
            #"^[（(]?[一二三四五六七八九十]+[）)、\.]\s*"#,
        ]
        for p in patterns {
            if let r = s.range(of: p, options: .regularExpression) {
                s.removeSubrange(r)
            }
        }
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func softSplit(_ line: String) -> [String] {
        let delimiters = ["；", ";", "。", "，然后", "然后", "还要", "另外", "其次", "以及", "、还有"]
        var working = line
        for d in delimiters {
            working = working.replacingOccurrences(of: d, with: "\n")
        }
        // Also split on Chinese enumeration comma when the line is long.
        if working == line, line.contains("、"), line.count > 24 {
            working = line.replacingOccurrences(of: "、", with: "\n")
        }
        return working
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func cleanTitle(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefixes = ["今天", "今日", "我要", "需要", "打算", "准备", "得", "要"]
        for p in prefixes {
            if s.hasPrefix(p) {
                s = String(s.dropFirst(p.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return s
    }

    private static func extractPriority(from text: String) -> (String, Priority?) {
        var title = text
        var priority: Priority?

        let highMarkers = ["紧急", "重要", "优先", "马上", "尽快", "高优", "P0", "p0", "ASAP", "asap"]
        let lowMarkers = ["稍后", "有空", "不急", "低优", "P2", "p2", "闲时"]

        for m in highMarkers {
            if title.localizedCaseInsensitiveContains(m) {
                priority = .high
                title = title.replacingOccurrences(of: m, with: "", options: .caseInsensitive)
            }
        }
        if priority == nil {
            for m in lowMarkers {
                if title.localizedCaseInsensitiveContains(m) {
                    priority = .low
                    title = title.replacingOccurrences(of: m, with: "", options: .caseInsensitive)
                }
            }
        }

        // Strip leftover punctuation from marker removal
        title = title
            .replacingOccurrences(of: #"^[：:\-—,\s]+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"[：:\-—,\s]+$"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return (title, priority)
    }

    private static func positionalPriority(index: Int, total: Int) -> Priority {
        guard total > 1 else { return .medium }
        let third = max(total / 3, 1)
        if index < third { return .high }
        if index >= total - third { return .low }
        return .medium
    }
}
