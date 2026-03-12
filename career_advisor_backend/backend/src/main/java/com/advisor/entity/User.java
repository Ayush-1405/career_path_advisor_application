// entity/User.java
package com.advisor.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.index.Indexed;
import lombok.*;
import java.time.LocalDateTime;
import java.util.List;

@Document(collection="users") @Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class User {
  @Id
  private String id;

  private String name;

  @Indexed(unique = true)
  private String email;

  private String password; // will be BCrypt hashed

  private Role role = Role.USER;

  private String phoneNumber;

  private String profilePictureUrl;

  private String bio;

  private String location;

  private String linkedinUrl;

  private String githubUrl;

  private String websiteUrl;

  private Boolean isActive = true;

  private Boolean emailVerified = false;

  private LocalDateTime lastLogin;

  private LocalDateTime createdAt = LocalDateTime.now();

  private LocalDateTime updatedAt = LocalDateTime.now();

  @com.fasterxml.jackson.annotation.JsonIgnore
  private List<String> resumeIds;

  @com.fasterxml.jackson.annotation.JsonIgnore
  private List<String> activityIds;

  @com.fasterxml.jackson.annotation.JsonIgnore
  private List<String> analysisIds;

  public void preUpdate() {
    this.updatedAt = LocalDateTime.now();
  }
}
