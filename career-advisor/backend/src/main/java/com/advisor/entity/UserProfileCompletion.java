package com.advisor.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.DBRef;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.index.Indexed;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.LastModifiedDate;

import java.time.LocalDateTime;

@Document(collection = "user_profile_completion")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserProfileCompletion {
    
    @Id
    private String id;
    
    @DBRef
    @Indexed(unique = true, sparse = true)
    private User user;
    
    private Boolean hasResume = false;
    
    private Boolean hasSkillsAssessment = false;
    
    private Boolean hasCareerPreferences = false;
    
    private Boolean hasEducationInfo = false;
    
    private Integer completionPercentage = 0;
    
    @LastModifiedDate
    private LocalDateTime updatedAt;
    
    // Constructor for easy creation
    public UserProfileCompletion(User user) {
        this.user = user;
        this.hasResume = false;
        this.hasSkillsAssessment = false;
        this.hasCareerPreferences = false;
        this.hasEducationInfo = false;
        this.completionPercentage = 0;
    }

    public String getUserId() {
        return user != null ? user.getId() : null;
    }
    
    // Method to calculate completion percentage
    public void calculateCompletionPercentage() {
        int completed = 0;
        int total = 4;
        
        if (hasResume) completed++;
        if (hasSkillsAssessment) completed++;
        if (hasCareerPreferences) completed++;
        if (hasEducationInfo) completed++;
        
        this.completionPercentage = (completed * 100) / total;
    }
}
