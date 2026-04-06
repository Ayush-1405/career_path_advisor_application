package com.advisor.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import lombok.*;
import java.time.LocalDateTime;

@Document(collection="connections") 
@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class Connection {
    @Id
    private String id;
    
    private String followerId;  // User who initiates
    private String followedId;  // User who is being followed
    
    // Status can be "PENDING", "ACCEPTED", "REJECTED"
    // We will use "ACCEPTED" by default for a simple follow architecture
    private String status = "ACCEPTED"; 
    
    private LocalDateTime createdAt = LocalDateTime.now();
}
