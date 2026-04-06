package com.advisor.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;

@Document(collection = "notifications")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Notification {
    @Id
    private String id;
    
    // The user who receives the notification
    private String recipientId;
    
    // The user who triggered the notification
    private String senderId;
    private String senderName;
    private String senderAvatarUrl;
    
    // Type of notification: LIKE, COMMENT, FOLLOW_REQUEST, FOLLOW_ACCEPT, SHARE, APPLICATION
    private String type;
    
    // The actual text payload ("John Doe liked your post")
    private String message;
    
    // ID to deep link to (postId, etc)
    private String relatedEntityId;
    
    private boolean isRead = false;
    
    @CreatedDate
    private LocalDateTime createdAt = LocalDateTime.now();
}
