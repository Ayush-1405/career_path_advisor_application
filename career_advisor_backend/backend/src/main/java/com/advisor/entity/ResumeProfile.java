package com.advisor.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.DBRef;
import org.springframework.data.mongodb.core.mapping.Document;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Document(collection = "resume_profile")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ResumeProfile {

    @Id
    private String id;

    @DBRef
    @Indexed(unique = true, sparse = true)
    private User user;

    // File metadata
    private String originalFileName;
    private String storedFileName;
    private String fileType; // pdf / docx
    private Long fileSize;
    private String filePath; // server path
    private String fileUrl;  // public URL if available

    // Extracted + editable fields
    private String name;
    private String email;
    private String phone;
    private List<String> skills = new ArrayList<>();
    private String summary;

    private List<EducationEntry> education = new ArrayList<>();
    private List<ExperienceEntry> experience = new ArrayList<>();
    private List<ProjectEntry> projects = new ArrayList<>();

    private LocalDateTime createdAt = LocalDateTime.now();
    private LocalDateTime updatedAt = LocalDateTime.now();

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EducationEntry {
        private String degree;
        private String institute;
        private String startYear;
        private String endYear;
        private String score;
        private String details;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ExperienceEntry {
        private String title;
        private String company;
        private String startDate;
        private String endDate;
        private String location;
        private List<String> highlights = new ArrayList<>();
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class ProjectEntry {
        private String title;
        private String link;
        private String description;
        private List<String> technologies = new ArrayList<>();
    }
}

