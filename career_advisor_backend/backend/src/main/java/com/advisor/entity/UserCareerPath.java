package com.advisor.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.LastModifiedDate;
import org.springframework.data.mongodb.core.mapping.DBRef;
import org.springframework.data.mongodb.core.mapping.Document;
import lombok.*;
import java.time.LocalDateTime;

@Document(collection = "user_career_paths")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor
@Builder
public class UserCareerPath {
    @Id
    private String id;

    @DBRef
    private User user;

    @DBRef
    private CareerPath careerPath;

    @Builder.Default
    private String status = "APPLIED"; // APPLIED, IN_PROGRESS, APPROVED, REJECTED

    @CreatedDate
    private LocalDateTime appliedAt;

    @LastModifiedDate
    private LocalDateTime updatedAt;

    public void prePersist() {
        if (appliedAt == null) appliedAt = LocalDateTime.now();
        if (updatedAt == null) updatedAt = LocalDateTime.now();
        if (status == null) status = "APPLIED";
    }

    public void preUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
