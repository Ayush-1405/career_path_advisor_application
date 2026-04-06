package com.advisor.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import lombok.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Document(collection="posts") 
@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class Post {
    @Id
    private String id;
    
    private String userId; // The creator of the post
    private String content; // Text content
    
    private boolean isAchievement = false;
    
    // Media attachments: list of URLs for images, or a single video URL
    private List<String> mediaUrls = new ArrayList<>();
    // "IMAGE", "VIDEO", or null for text-only
    private String mediaType;
    
    private List<String> likes = new ArrayList<>(); // User IDs who liked
    private List<Comment> comments = new ArrayList<>(); // Embedded comments
    
    private LocalDateTime createdAt = LocalDateTime.now();

    @Getter @Setter @NoArgsConstructor @AllArgsConstructor
    public static class Comment {
        private String userId;
        private String text;
        private LocalDateTime createdAt = LocalDateTime.now();
    }
}
