package com.advisor.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.DBRef;
import org.springframework.data.mongodb.core.mapping.Document;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Document(collection = "career_suggestions")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CareerSuggestion {
    
    @Id
    private String id;
    
    @DBRef
    private User user;
    
    private String suggestionTitle;
    
    private String suggestionDescription;
    
    private Integer matchPercentage;
    
    private String salaryRange;
    
    private String growthPotential;
    
    private String requiredSkills;
    
    private LocalDateTime suggestedAt;
    
    private Boolean isViewed = false;
    
    // Constructor for easy creation
    public CareerSuggestion(User user, String suggestionTitle, String suggestionDescription, 
                           Integer matchPercentage, String salaryRange, String growthPotential) {
        this.user = user;
        this.suggestionTitle = suggestionTitle;
        this.suggestionDescription = suggestionDescription;
        this.matchPercentage = matchPercentage;
        this.salaryRange = salaryRange;
        this.growthPotential = growthPotential;
        this.suggestedAt = LocalDateTime.now();
        this.isViewed = false;
    }

    public String getUserId() {
        return user != null ? user.getId() : null;
    }
}
