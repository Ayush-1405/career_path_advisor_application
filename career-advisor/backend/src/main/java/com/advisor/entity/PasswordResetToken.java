package com.advisor.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.index.Indexed;
import lombok.*;

import java.time.Instant;

@Document(collection = "password_reset_tokens")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor
public class PasswordResetToken {
  @Id
  private String id;

  @Indexed(unique = true)
  private String token;

  private String userId;

  private Instant expiresAt;

  private boolean used = false;
}











