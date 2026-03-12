package com.advisor.entity;

//entity/Resume.java

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.DBRef;
import org.springframework.data.mongodb.core.mapping.Document;
import lombok.*;
import java.util.List;

@Document(collection = "resume") @Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class Resume {
    @Id
    private String id;

    @DBRef
    private User user;

    private String education;
    
    private String skills;
    
    private String experience;
    
    private String fileName;
    
    private String filePath;
    
    private Long fileSize;
    
    private String fileType;
    
    private java.time.LocalDateTime uploadedAt = java.time.LocalDateTime.now();

    @com.fasterxml.jackson.annotation.JsonIgnore
    private List<String> analysisIds;
}
