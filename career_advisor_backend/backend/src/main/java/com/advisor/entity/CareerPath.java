package com.advisor.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import lombok.*;
import java.util.List;
import java.util.Map;

@Document(collection = "career_paths")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class CareerPath {
    @Id
    private String id;

    private String title;
    private String description;
    private String level;
    private String category;
    private String image;
    private String averageSalary;
    private String growth;
    private int popularity;

    private List<String> requiredSkills;
    private List<Map<String, String>> careerProgression;
}
