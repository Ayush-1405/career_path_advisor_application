package com.advisor.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.DBRef;
import org.springframework.data.mongodb.core.mapping.Document;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;

import java.time.LocalDateTime;

@Document(collection = "user_activities")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class UserActivity {
    
    @Id
    private String id;
    
    @DBRef
    private User user;
    
    private String activityType;
    
    private String activityData;
    
    @CreatedDate
    private LocalDateTime createdAt;
    
    // Alias method for compatibility
    public LocalDateTime getTimestamp() {
        return createdAt;
    }
    
    // Constructor for easy creation
    public UserActivity(User user, String activityType, String activityData) {
        this.user = user;
        this.activityType = activityType;
        this.activityData = activityData;
    }

    public String getUserId() {
        return user != null ? user.getId() : null;
    }
}
