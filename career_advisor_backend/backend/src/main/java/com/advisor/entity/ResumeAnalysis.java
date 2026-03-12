package com.advisor.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.DBRef;
import org.springframework.data.mongodb.core.mapping.Document;
import lombok.*;

@Document(collection = "resume_analysis") @Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class ResumeAnalysis {
  @Id
  private String id;

  @DBRef
  private User user;

  @DBRef
  private Resume resume;

  private Integer overallScore;

  private String strengths; // comma-separated list

  private String improvements; // comma-separated list
  
  private String feedback;
  
  private String analysisData; // Store detailed analysis results
  
  private java.time.LocalDateTime analyzedAt = java.time.LocalDateTime.now();
  
  // Alias method for compatibility
  public String getWeaknesses() {
    return improvements;
  }
}



