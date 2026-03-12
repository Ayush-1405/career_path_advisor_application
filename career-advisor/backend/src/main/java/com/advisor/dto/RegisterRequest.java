package com.advisor.dto;

//dto/RegisterRequest.java

import jakarta.validation.constraints.*;
import lombok.*;

@Getter @Setter
public class RegisterRequest {
@NotBlank private String name;
@Email @NotBlank private String email;
@Size(min=6) @NotBlank private String password;

}

