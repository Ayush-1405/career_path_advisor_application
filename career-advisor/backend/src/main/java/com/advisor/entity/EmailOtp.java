package com.advisor.entity;


import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.index.Indexed;
import lombok.Getter;
import lombok.Setter;

import java.time.Instant;

@Document(collection = "email_otp")
@Getter
@Setter
public class EmailOtp {
  @Id
  private String id;

  @Indexed
  private String email;

  private String code;

  private Instant expiresAt;

  private boolean used = false;

  private Instant createdAt;
}
