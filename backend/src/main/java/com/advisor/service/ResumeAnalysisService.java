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
import java.util.Map;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ResumeAnalysisService {
  private final ResumeRepository resumeRepository;
  private final ResumeAnalysisRepository analysisRepository;
  private final ResumeParsingService resumeParsingService;
  private final OpenRouterService openRouterService;

  public ResumeAnalysis analyzeAndSave(Resume resume, User user) {
    String extractedText = "";
    if (resume.getFilePath() != null) {
      extractedText = extractTextFromFile(resume.getFilePath());
    }

    // Fallback to provided skills if text extraction failed or empty
    if (extractedText.isEmpty() && resume.getSkills() != null) {
      extractedText = resume.getSkills();
    }

    // Perform analysis using AI for accurate feedback and scoring
    Map<String, Object> aiResult = openRouterService.analyzeResume(extractedText);
    
    int score = ((Number) aiResult.getOrDefault("score", 50)).intValue();
    String strengths = (String) aiResult.getOrDefault("strengths", "Generic Profile");
    String improvements = (String) aiResult.getOrDefault("improvements", "Complete details");
    String feedback = (String) aiResult.getOrDefault("feedback", "AI evaluation failed.");
    String careerPath = (String) aiResult.getOrDefault("careerPath", "Review your skills for targeted growth.");

    Resume saved = resumeRepository.save(resume);

    ResumeAnalysis ra = new ResumeAnalysis();
    ra.setUser(user);
    ra.setResume(saved);
    ra.setOverallScore(score);
    ra.setStrengths(strengths);
    ra.setImprovements(improvements);
    ra.setFeedback(feedback);
    ra.setCareerPath(careerPath);
    
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
}
