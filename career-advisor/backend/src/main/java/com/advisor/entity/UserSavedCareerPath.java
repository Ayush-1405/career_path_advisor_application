package com.advisor.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.DBRef;
import org.springframework.data.mongodb.core.mapping.Document;
import lombok.*;
import java.time.LocalDateTime;

@Document(collection = "user_saved_career_paths")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class UserSavedCareerPath {
  @Id
  private String id;

  @DBRef
  private User user;

  @DBRef
  private CareerPath careerPath;

  private LocalDateTime savedAt;

  public void onCreate() {
    savedAt = LocalDateTime.now();
  }
}
