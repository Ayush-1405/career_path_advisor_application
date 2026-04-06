package com.advisor.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import lombok.*;
import java.time.LocalDateTime;
import java.util.List;

@Document(collection="chat_rooms") 
@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class ChatRoom {
    @Id
    private String id;
    
    private List<String> participantIds; // Should typically contain 2 user IDs
    
    private String lastMessage;
    private LocalDateTime lastUpdate = LocalDateTime.now();
}
