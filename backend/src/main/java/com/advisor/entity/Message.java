package com.advisor.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import lombok.*;
import java.time.LocalDateTime;

@Document(collection="messages") 
@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class Message {
    @Id
    private String id;
    
    private String chatRoomId;
    private String senderId;
    private String content;
    
    private boolean isRead = false;
    
    private LocalDateTime timestamp = LocalDateTime.now();
}
