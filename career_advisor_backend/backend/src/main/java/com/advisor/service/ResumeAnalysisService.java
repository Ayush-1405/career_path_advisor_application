package com.advisor.service;

import com.advisor.entity.*;
import com.advisor.repository.*;
import lombok.RequiredArgsConstructor;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;
import org.apache.poi.xwpf.extractor.XWPFWordExtractor;
import org.apache.poi.xwpf.usermodel.XWPFDocument;
import org.springframework.stereotype.Service;

import java.io.File;
import java.io.FileInputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ResumeAnalysisService {
  private final ResumeRepository resumeRepository;
  private final ResumeAnalysisRepository analysisRepository;

  public ResumeAnalysis analyzeAndSave(Resume resume, User user) {
    String extractedText = "";
    if (resume.getFilePath() != null) {
      extractedText = extractTextFromFile(resume.getFilePath());
    }

    // Fallback to provided skills if text extraction failed or empty
    if (extractedText.isEmpty() && resume.getSkills() != null) {
      extractedText = resume.getSkills();
    }

    // Perform analysis on the text
    int score = calculateScore(extractedText);
    String strengths = identifyStrengths(extractedText);
    String improvements = identifyImprovements(extractedText);
    String feedback = generateFeedback(score);

    Resume saved = resumeRepository.save(resume);

    ResumeAnalysis ra = new ResumeAnalysis();
    ra.setUser(user);
    ra.setResume(saved);
    ra.setOverallScore(score);
    ra.setStrengths(strengths);
    ra.setImprovements(improvements);
    ra.setFeedback(feedback);
    
    // Store extracted text summary or details if needed in analysisData
    // For now, we keep it simple
    
    return analysisRepository.save(ra);
  }

  public ResumeAnalysis getAnalysisByResumeId(String resumeId) {
    List<ResumeAnalysis> analyses = analysisRepository.findByResume_Id(resumeId);
    return analyses.isEmpty() ? null : analyses.get(0);
  }

  private String extractTextFromFile(String filePath) {
    try {
      File file = new File(filePath);
      if (!file.exists()) return "";

      String lowerPath = filePath.toLowerCase();
      if (lowerPath.endsWith(".pdf")) {
        try (PDDocument document = PDDocument.load(file)) {
          PDFTextStripper stripper = new PDFTextStripper();
          return stripper.getText(document);
        }
      } else if (lowerPath.endsWith(".docx")) {
        try (FileInputStream fis = new FileInputStream(file);
             XWPFDocument document = new XWPFDocument(fis);
             XWPFWordExtractor extractor = new XWPFWordExtractor(document)) {
          return extractor.getText();
        }
      }
    } catch (Exception e) {
      System.err.println("Error extracting text: " + e.getMessage());
    }
    return "";
  }

  /**
   * Extract resume text for structured parsing.
   * This is intentionally separate from scoring so other services can reuse it.
   */
  public String extractTextForParsing(String filePath, String fileType) {
    if (filePath == null || filePath.isBlank()) return "";
    return extractTextFromFile(filePath);
  }

  private int calculateScore(String text) {
    if (text == null || text.isEmpty()) return 50; // Base score
    
    int score = 60; // Start with a decent baseline
    String lowerText = text.toLowerCase();

    // Key sections check
    if (lowerText.contains("education")) score += 5;
    if (lowerText.contains("experience") || lowerText.contains("work history")) score += 10;
    if (lowerText.contains("skills") || lowerText.contains("technologies")) score += 5;
    if (lowerText.contains("projects")) score += 5;
    if (lowerText.contains("summary") || lowerText.contains("objective") || lowerText.contains("profile")) score += 5;

    // Tech keywords check (Expand this list)
    List<String> keywords = Arrays.asList(
        "java", "python", "javascript", "react", "angular", "vue", "node", "spring", 
        "sql", "nosql", "aws", "azure", "docker", "kubernetes", "git", "ci/cd",
        "flutter", "mobile", "android", "ios", "machine learning", "ai", "data science"
    );

    long keywordCount = keywords.stream().filter(lowerText::contains).count();
    score += Math.min(keywordCount * 2, 20); // Cap keyword bonus at 20

    return Math.min(score, 100);
  }

  private String identifyStrengths(String text) {
    if (text == null || text.isEmpty()) return "Basic profile";
    
    List<String> strengths = new ArrayList<>();
    String lowerText = text.toLowerCase();

    if (lowerText.contains("experience") || lowerText.contains("years")) strengths.add("Industry Experience");
    if (lowerText.contains("lead") || lowerText.contains("manager") || lowerText.contains("managed")) strengths.add("Leadership Potential");
    if (lowerText.contains("bachelor") || lowerText.contains("master") || lowerText.contains("phd")) strengths.add("Formal Education");
    if (lowerText.contains("award") || lowerText.contains("certified") || lowerText.contains("certification")) strengths.add("Achievements/Certifications");
    
    // Tech strengths
    if (lowerText.contains("java") || lowerText.contains("python") || lowerText.contains("javascript")) strengths.add("Programming Skills");
    if (lowerText.contains("aws") || lowerText.contains("cloud")) strengths.add("Cloud Computing");

    if (strengths.isEmpty()) strengths.add("Emerging Talent");
    
    return String.join(", ", strengths);
  }

  private String identifyImprovements(String text) {
    if (text == null || text.isEmpty()) return "Complete profile details";
    
    List<String> improvements = new ArrayList<>();
    String lowerText = text.toLowerCase();

    if (!lowerText.contains("linkedin")) improvements.add("Add LinkedIn Profile");
    if (!lowerText.contains("github") && !lowerText.contains("portfolio")) improvements.add("Add Portfolio/GitHub");
    if (!lowerText.contains("certificat")) improvements.add("Get Relevant Certifications");
    if (!lowerText.contains("metric") && !lowerText.contains("%") && !lowerText.contains("$")) improvements.add("Quantify Achievements (use metrics)");
    
    if (improvements.isEmpty()) improvements.add("Keep skills updated");
    
    return String.join(", ", improvements);
  }

  private String generateFeedback(int score) {
    if (score >= 90) return "Excellent resume! You have a strong profile with all key sections and relevant keywords.";
    if (score >= 80) return "Great job! Your resume is very good, just a few minor improvements could make it perfect.";
    if (score >= 70) return "Good start. Focus on adding more specific technical skills and quantifying your achievements.";
    if (score >= 60) return "Average profile. You need to elaborate more on your projects and experience.";
    return "Needs improvement. Please ensure you have included Education, Experience, Skills, and Projects sections.";
  }
}
