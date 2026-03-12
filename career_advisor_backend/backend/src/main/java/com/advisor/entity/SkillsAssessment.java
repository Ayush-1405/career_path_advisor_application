package com.advisor.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.DBRef;
import org.springframework.data.mongodb.core.mapping.Document;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Document(collection = "skills_assessments")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class SkillsAssessment {
    
    @Id
    private String id;
    
    @DBRef
    private User user;
    
    private String assessmentType;
    
    private Integer score;
    
    private Integer maxScore;
    
    private String answers;
    
    private LocalDateTime completedAt;
    
    // Constructor for easy creation
    public SkillsAssessment(User user, String assessmentType, Integer score, Integer maxScore, String answers) {
        this.user = user;
        this.assessmentType = assessmentType;
        this.score = score;
        this.maxScore = maxScore;
        this.answers = answers;
        this.completedAt = LocalDateTime.now();
    }

    public String getUserId() {
        return user != null ? user.getId() : null;
    }
}
