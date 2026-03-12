package com.advisor.dto;

import lombok.*;

@Getter @Setter @AllArgsConstructor @NoArgsConstructor
public class AuthResponse {
  private String token;
  private String role;
  private String email;
  private String name;
  private String userId;
  private String status; // SUCCESS, REQUIRES_OTP
  private String message;

  public AuthResponse(String token, String role, String email, String name) {
    this.token = token;
    this.role = role;
    this.email = email;
    this.name = name;
    this.status = "SUCCESS";
  }

  public AuthResponse(String token, String role, String email, String name, String userId) {
    this.token = token;
    this.role = role;
    this.email = email;
    this.name = name;
    this.userId = userId;
    this.status = "SUCCESS";
  }
}