package com.advisor.service;

import com.advisor.entity.ResumeProfile;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.util.List;

@Service
public class ResumePdfService {

    public byte[] generatePdf(ResumeProfile profile) {
        if (profile == null) {
            throw new RuntimeException("Resume data not found");
        }

        try (PDDocument doc = new PDDocument()) {
            PDPage page = new PDPage(PDRectangle.A4);
            doc.addPage(page);

            try (PDPageContentStream cs = new PDPageContentStream(doc, page)) {
                float margin = 48;
                float y = page.getMediaBox().getHeight() - margin;

                y = writeHeader(cs, profile, margin, y);
                y -= 12;

                y = writeSection(cs, "Summary", List.of(nullToEmpty(profile.getSummary())), margin, y);
                y = writeSection(cs, "Skills", profile.getSkills(), margin, y);

                y = writeEducation(cs, profile, margin, y);
                y = writeExperience(cs, profile, margin, y);
                y = writeProjects(cs, profile, margin, y);
            }

            ByteArrayOutputStream out = new ByteArrayOutputStream();
            doc.save(out);
            return out.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("Failed to generate PDF: " + e.getMessage(), e);
        }
    }

    private float writeHeader(PDPageContentStream cs, ResumeProfile p, float x, float y) throws Exception {
        cs.beginText();
        cs.setFont(PDType1Font.HELVETICA_BOLD, 18);
        cs.newLineAtOffset(x, y);
        cs.showText(nullToEmpty(p.getName()));
        cs.endText();

        y -= 22;
        String contact = String.join(" • ",
                List.of(nullToEmpty(p.getEmail()), nullToEmpty(p.getPhone())).stream()
                        .filter(s -> !s.isBlank()).toList()
        );
        if (!contact.isBlank()) {
            cs.beginText();
            cs.setFont(PDType1Font.HELVETICA, 10);
            cs.newLineAtOffset(x, y);
            cs.showText(contact);
            cs.endText();
            y -= 16;
        }
        return y;
    }

    private float writeSection(PDPageContentStream cs, String title, List<String> lines, float x, float y) throws Exception {
        lines = (lines == null) ? List.of() : lines.stream().filter(s -> s != null && !s.isBlank()).toList();
        if (lines.isEmpty()) return y;

        y -= 8;
        cs.beginText();
        cs.setFont(PDType1Font.HELVETICA_BOLD, 12);
        cs.newLineAtOffset(x, y);
        cs.showText(title);
        cs.endText();

        y -= 14;
        cs.setFont(PDType1Font.HELVETICA, 10);

        for (String line : lines) {
            for (String wrapped : wrap(line, 95)) {
                cs.beginText();
                cs.newLineAtOffset(x, y);
                cs.showText(wrapped);
                cs.endText();
                y -= 12;
            }
        }
        return y;
    }

    private float writeEducation(PDPageContentStream cs, ResumeProfile p, float x, float y) throws Exception {
        if (p.getEducation() == null || p.getEducation().isEmpty()) return y;
        y -= 4;
        cs.beginText();
        cs.setFont(PDType1Font.HELVETICA_BOLD, 12);
        cs.newLineAtOffset(x, y);
        cs.showText("Education");
        cs.endText();
        y -= 14;

        cs.setFont(PDType1Font.HELVETICA, 10);
        for (var e : p.getEducation()) {
            String line = firstNonBlank(
                    joinNonBlank(" - ", e.getDegree(), e.getInstitute()),
                    e.getDetails()
            );
            if (line.isBlank()) continue;
            for (String wrapped : wrap(line, 95)) {
                cs.beginText();
                cs.newLineAtOffset(x, y);
                cs.showText(wrapped);
                cs.endText();
                y -= 12;
            }
        }
        return y;
    }

    private float writeExperience(PDPageContentStream cs, ResumeProfile p, float x, float y) throws Exception {
        if (p.getExperience() == null || p.getExperience().isEmpty()) return y;
        y -= 4;
        cs.beginText();
        cs.setFont(PDType1Font.HELVETICA_BOLD, 12);
        cs.newLineAtOffset(x, y);
        cs.showText("Work Experience");
        cs.endText();
        y -= 14;

        cs.setFont(PDType1Font.HELVETICA_BOLD, 10);
        for (var e : p.getExperience()) {
            String header = joinNonBlank(" - ", e.getTitle(), e.getCompany());
            if (!header.isBlank()) {
                cs.beginText();
                cs.newLineAtOffset(x, y);
                cs.showText(header);
                cs.endText();
                y -= 12;
            }
            cs.setFont(PDType1Font.HELVETICA, 10);
            if (e.getHighlights() != null) {
                for (String h : e.getHighlights()) {
                    if (h == null || h.isBlank()) continue;
                    for (String wrapped : wrap("• " + h.trim(), 92)) {
                        cs.beginText();
                        cs.newLineAtOffset(x + 10, y);
                        cs.showText(wrapped);
                        cs.endText();
                        y -= 12;
                    }
                }
            }
            cs.setFont(PDType1Font.HELVETICA_BOLD, 10);
            y -= 4;
        }
        return y;
    }

    private float writeProjects(PDPageContentStream cs, ResumeProfile p, float x, float y) throws Exception {
        if (p.getProjects() == null || p.getProjects().isEmpty()) return y;
        y -= 4;
        cs.beginText();
        cs.setFont(PDType1Font.HELVETICA_BOLD, 12);
        cs.newLineAtOffset(x, y);
        cs.showText("Projects");
        cs.endText();
        y -= 14;

        for (var pr : p.getProjects()) {
            String title = nullToEmpty(pr.getTitle());
            if (!title.isBlank()) {
                cs.beginText();
                cs.setFont(PDType1Font.HELVETICA_BOLD, 10);
                cs.newLineAtOffset(x, y);
                cs.showText(title);
                cs.endText();
                y -= 12;
            }
            cs.setFont(PDType1Font.HELVETICA, 10);
            if (pr.getDescription() != null && !pr.getDescription().isBlank()) {
                for (String wrapped : wrap(pr.getDescription(), 95)) {
                    cs.beginText();
                    cs.newLineAtOffset(x, y);
                    cs.showText(wrapped);
                    cs.endText();
                    y -= 12;
                }
            }
            y -= 4;
        }
        return y;
    }

    private String nullToEmpty(String s) {
        return s == null ? "" : s.trim();
    }

    private String joinNonBlank(String sep, String a, String b) {
        String aa = nullToEmpty(a);
        String bb = nullToEmpty(b);
        if (aa.isBlank()) return bb;
        if (bb.isBlank()) return aa;
        return aa + sep + bb;
    }

    private String firstNonBlank(String a, String b) {
        if (a != null && !a.isBlank()) return a;
        return b == null ? "" : b;
    }

    private List<String> wrap(String text, int maxChars) {
        if (text == null) return List.of();
        String t = text.trim();
        if (t.length() <= maxChars) return List.of(t);

        List<String> out = new java.util.ArrayList<>();
        int idx = 0;
        while (idx < t.length()) {
            int end = Math.min(idx + maxChars, t.length());
            int space = t.lastIndexOf(' ', end);
            if (space <= idx) space = end;
            out.add(t.substring(idx, space).trim());
            idx = space + 1;
        }
        return out;
    }
}

