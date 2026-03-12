package com.advisor.service;

import com.advisor.entity.ResumeProfile;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.*;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
public class ResumeParsingService {

    private static final Pattern EMAIL =
            Pattern.compile("[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", Pattern.CASE_INSENSITIVE);

    // Very tolerant phone pattern (supports +91, spaces, hyphens)
    private static final Pattern PHONE =
            Pattern.compile("(\\+?\\d[\\d\\s().-]{8,}\\d)");

    public ResumeProfile parseToProfile(String extractedText) {
        ResumeProfile profile = new ResumeProfile();
        if (extractedText == null) extractedText = "";

        String text = normalize(extractedText);
        List<String> lines = Arrays.stream(text.split("\\R"))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .toList();

        profile.setEmail(findFirst(EMAIL, text).orElse(null));
        profile.setPhone(findBestPhone(text).orElse(null));
        profile.setName(guessName(lines, profile.getEmail(), profile.getPhone()).orElse(null));

        Map<String, List<String>> sections = splitIntoSections(lines);
        profile.setSkills(parseSkills(sections));
        profile.setEducation(parseEducation(sections));
        profile.setExperience(parseExperience(sections));
        profile.setProjects(parseProjects(sections));
        profile.setSummary(parseSummary(sections));

        return profile;
    }

    private String normalize(String text) {
        return text.replace("\u00A0", " ").replace("\t", " ");
    }

    private Optional<String> findFirst(Pattern p, String text) {
        Matcher m = p.matcher(text);
        return m.find() ? Optional.ofNullable(m.group()) : Optional.empty();
    }

    private Optional<String> findBestPhone(String text) {
        Matcher m = PHONE.matcher(text);
        String best = null;
        while (m.find()) {
            String v = m.group(1);
            String digits = v.replaceAll("\\D", "");
            if (digits.length() < 10 || digits.length() > 15) continue;
            if (best == null || digits.length() > best.replaceAll("\\D", "").length()) {
                best = v.trim();
            }
        }
        return Optional.ofNullable(best);
    }

    private Optional<String> guessName(List<String> lines, String email, String phone) {
        for (String l : lines) {
            // Skip likely headers like "Resume", "Curriculum Vitae"
            String low = l.toLowerCase();
            if (low.contains("resume") || low.contains("curriculum vitae") || low.contains("cv")) continue;
            if (email != null && l.contains(email)) continue;
            if (phone != null && l.contains(phone)) continue;

            // Name is often the first strong line (letters + spaces)
            if (l.length() >= 3 && l.length() <= 50 && l.matches("[A-Za-z][A-Za-z .'-]{1,}")) {
                return Optional.of(l.trim());
            }
        }
        return Optional.empty();
    }

    private Map<String, List<String>> splitIntoSections(List<String> lines) {
        Map<String, List<String>> sections = new LinkedHashMap<>();
        String current = "other";
        sections.put(current, new ArrayList<>());

        for (String line : lines) {
            String key = sectionKey(line);
            if (key != null) {
                current = key;
                sections.putIfAbsent(current, new ArrayList<>());
                continue;
            }
            sections.get(current).add(line);
        }
        return sections;
    }

    private String sectionKey(String line) {
        String t = line.trim().toLowerCase();
        t = t.replaceAll("[^a-z\\s]", "").trim();

        Set<String> skills = Set.of("skills", "technical skills", "technologies", "tools");
        Set<String> edu = Set.of("education", "academics", "academic background", "qualification");
        Set<String> exp = Set.of("experience", "work experience", "employment", "work history", "professional experience");
        Set<String> proj = Set.of("projects", "personal projects", "project", "project work");
        Set<String> sum = Set.of("summary", "objective", "profile", "about");

        if (skills.contains(t)) return "skills";
        if (edu.contains(t)) return "education";
        if (exp.contains(t)) return "experience";
        if (proj.contains(t)) return "projects";
        if (sum.contains(t)) return "summary";
        return null;
    }

    private List<String> parseSkills(Map<String, List<String>> sections) {
        List<String> base = sections.getOrDefault("skills", List.of());
        String joined = String.join(" ", base);
        // Split on commas or bullets
        return Arrays.stream(joined.split("[,•\\u2022|/]+"))
                .map(String::trim)
                .filter(s -> s.length() >= 2)
                .distinct()
                .limit(60)
                .toList();
    }

    private String parseSummary(Map<String, List<String>> sections) {
        List<String> base = sections.getOrDefault("summary", List.of());
        if (base.isEmpty()) return null;
        // Take first 3 lines max
        return String.join(" ", base.subList(0, Math.min(3, base.size()))).trim();
    }

    private List<ResumeProfile.EducationEntry> parseEducation(Map<String, List<String>> sections) {
        List<String> base = sections.getOrDefault("education", List.of());
        if (base.isEmpty()) return List.of();

        List<ResumeProfile.EducationEntry> out = new ArrayList<>();
        // naive: each non-empty line becomes an entry detail
        for (String line : base) {
            if (line.length() < 3) continue;
            ResumeProfile.EducationEntry e = new ResumeProfile.EducationEntry();
            e.setDetails(line);
            out.add(e);
            if (out.size() >= 6) break;
        }
        return out;
    }

    private List<ResumeProfile.ExperienceEntry> parseExperience(Map<String, List<String>> sections) {
        List<String> base = sections.getOrDefault("experience", List.of());
        if (base.isEmpty()) return List.of();

        List<ResumeProfile.ExperienceEntry> out = new ArrayList<>();
        ResumeProfile.ExperienceEntry current = null;

        for (String line : base) {
            // Heuristic: lines that look like titles start a new entry
            boolean looksLikeHeader = line.length() <= 80 && (line.toLowerCase().contains("intern") ||
                    line.toLowerCase().contains("engineer") ||
                    line.toLowerCase().contains("developer") ||
                    line.toLowerCase().contains("analyst") ||
                    line.toLowerCase().contains("manager"));
            if (current == null || looksLikeHeader) {
                current = new ResumeProfile.ExperienceEntry();
                current.setTitle(line);
                current.setHighlights(new ArrayList<>());
                out.add(current);
                if (out.size() >= 6) break;
                continue;
            }
            if (line.startsWith("-") || line.startsWith("•") || line.startsWith("*")) {
                current.getHighlights().add(line.replaceFirst("^[-•*]\\s*", "").trim());
            } else {
                // Append as highlight if not header
                current.getHighlights().add(line.trim());
            }
            if (current.getHighlights().size() > 6) {
                current.setHighlights(current.getHighlights().subList(0, 6));
            }
        }
        return out;
    }

    private List<ResumeProfile.ProjectEntry> parseProjects(Map<String, List<String>> sections) {
        List<String> base = sections.getOrDefault("projects", List.of());
        if (base.isEmpty()) return List.of();

        List<ResumeProfile.ProjectEntry> out = new ArrayList<>();
        ResumeProfile.ProjectEntry current = null;

        for (String line : base) {
            boolean titleLine = line.length() <= 80 && !line.startsWith("-") && !line.startsWith("•");
            if (current == null || titleLine) {
                current = new ResumeProfile.ProjectEntry();
                current.setTitle(line);
                current.setTechnologies(new ArrayList<>());
                out.add(current);
                if (out.size() >= 8) break;
                continue;
            }
            if (current.getDescription() == null) {
                current.setDescription(line);
            } else {
                current.setDescription((current.getDescription() + " " + line).trim());
            }
        }
        return out;
    }
}

