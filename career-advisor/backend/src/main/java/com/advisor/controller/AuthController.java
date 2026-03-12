package com.advisor.controller;

import com.advisor.dto.*;
import com.advisor.entity.*;
import com.advisor.repository.*;
import com.advisor.security.*;
import com.advisor.service.PasswordResetService;
import com.advisor.service.DashboardService;
import com.advisor.service.SystemSettingsService;
import com.advisor.service.EmailVerificationService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.*;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

  private final UserRepository userRepository;
  private final PasswordEncoder passwordEncoder;
  private final AuthenticationManager authenticationManager;
  private final JwtUtil jwtUtil;
  private final PasswordResetService passwordResetService;
  private final DashboardService dashboardService;
  private final SystemSettingsService systemSettingsService;
  private final EmailVerificationService emailVerificationService;

    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest req) {
        System.out.println("Incoming registration: " + req.getEmail());

        if (!systemSettingsService.getSettings().getAllowRegistrations()) {
            return ResponseEntity.badRequest().body("Registrations are currently disabled by administrator.");
        }

        if (userRepository.existsByEmail(req.getEmail())) {
            return ResponseEntity.badRequest().body("Email already registered");
        }

        User u = new User();
        u.setName(req.getName());
        u.setEmail(req.getEmail());
        u.setPassword(passwordEncoder.encode(req.getPassword()));
        u.setRole(Role.USER);
        userRepository.save(u);
        
        try {
            dashboardService.trackUserActivity(u.getId(), "user_registration",
                    "{\"email\":\"" + req.getEmail() + "\",\"name\":\"" + req.getName() + "\"}");
        } catch (Exception e) {
            System.err.println("Registration activity tracking failed: " + e.getMessage());
        }

        return ResponseEntity.ok(Map.of("message", "Registered", "success", true));
    }


    @PostMapping("/login")
  public ResponseEntity<AuthResponse> login(@RequestBody @jakarta.validation.Valid LoginRequest req) {
        try {
            authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(req.getEmail(), req.getPassword())
            );
        } catch (AuthenticationException e) {
            return ResponseEntity.status(401).body(new AuthResponse(null, null, null, null, null, "ERROR", "Invalid credentials"));
        }

        User u = userRepository.findByEmail(req.getEmail()).orElseThrow();
    
        // Trigger OTP for login security
        emailVerificationService.sendOtp(u.getEmail());
        
        AuthResponse resp = new AuthResponse();
        resp.setEmail(u.getEmail());
        resp.setName(u.getName());
        resp.setRole(u.getRole().name());
        resp.setStatus("REQUIRES_OTP");
        resp.setMessage("Verification code sent to your email");
        
        return ResponseEntity.ok(resp);
  }

  @PostMapping("/verify-login")
  public ResponseEntity<AuthResponse> verifyLogin(@RequestParam String email, @RequestParam String code) {
    try {
      boolean ok = emailVerificationService.verifyOtpForLogin(email, code);
      if (!ok) {
        return ResponseEntity.status(401).body(new AuthResponse(null, null, null, null, null, "ERROR", "Invalid or expired code"));
      }

      User u = userRepository.findByEmail(email).orElseThrow();
      u.setLastLogin(java.time.LocalDateTime.now());
      userRepository.save(u);

      String token = jwtUtil.generateToken(
          u.getEmail(),
          Map.of("role", "ROLE_" + u.getRole().name(), "name", u.getName(), "userId", u.getId())
      );

      // Track login activity
      dashboardService.trackUserActivity(u.getId(), "login", 
          "{\"email\":\"" + email + "\",\"timestamp\":\"" + java.time.LocalDateTime.now() + "\"}");

      return ResponseEntity.ok(new AuthResponse(token, u.getRole().name(), u.getEmail(), u.getName(), u.getId(), "SUCCESS", "Logged in successfully"));
    } catch (Exception e) {
      return ResponseEntity.status(500).body(new AuthResponse(null, null, null, null, null, "ERROR", e.getMessage()));
    }
  }

  @PostMapping("/verify/email/send")
  public ResponseEntity<?> sendEmailVerification(@RequestParam String email) {
    try {
      emailVerificationService.sendOtp(email);
      return ResponseEntity.ok("OTP sent");
    } catch (RuntimeException e) {
      return ResponseEntity.badRequest().body(e.getMessage());
    } catch (Exception e) {
      return ResponseEntity.status(500).body("Failed to send OTP: " + e.getMessage());
    }
  }

  @PostMapping("/verify/email/confirm")
  public ResponseEntity<?> confirmEmailVerification(@RequestParam String email, @RequestParam String code) {
    try {
      boolean ok = emailVerificationService.verifyOtp(email, code);
      if (!ok) {
        return ResponseEntity.badRequest().body("Invalid or expired code");
      }

      User u = userRepository.findByEmail(email).orElseThrow();
      String token = jwtUtil.generateToken(
          u.getEmail(),
          Map.of(
              "role", "ROLE_" + u.getRole().name(),
              "name", u.getName(),
              "userId", u.getId().toString()
          )
      );

      // Track activity, but never fail verification if this part throws
      try {
        dashboardService.trackUserActivity(
            u.getId(),
            "email_verified",
            "{\"email\":\"" + email + "\",\"timestamp\":\"" + java.time.LocalDateTime.now() + "\"}"
        );
      } catch (Exception ex) {
        System.err.println("Failed to track email_verified activity for user "
            + u.getId() + ": " + ex.getMessage());
      }

      return ResponseEntity.ok(
          new AuthResponse(token, u.getRole().name(), u.getEmail(), u.getName(), u.getId())
      );
    } catch (Exception e) {
      // Do not expose internal DB errors (like duplicate key) to the client
      System.err.println("Email verification failed for " + email + ": " + e.getMessage());
      return ResponseEntity.status(500).body("Verification failed. Please try again later.");
    }
  }

  @PostMapping("/forgot-password")
  public ResponseEntity<?> forgotPassword(@RequestParam String email, @RequestParam String redirectBaseUrl) {
    try {
      if (!userRepository.existsByEmail(email)) {
        System.out.println("Forgot password requested for non-registered email: " + email);
        return ResponseEntity.badRequest().body("Email not registered");
      }
      passwordResetService.sendResetEmail(email, redirectBaseUrl);
      return ResponseEntity.ok("Reset email sent");
    } catch (Exception e) {
      System.err.println("Forgot password processing failed: " + e.getMessage());
      // Return the specific error message for debugging purposes
      return ResponseEntity.status(500).body("Failed to process forgot password: " + e.getMessage());
    }
  }

  @GetMapping("/reset-password/validate")
  public ResponseEntity<?> validateResetToken(@RequestParam String token, @RequestParam String email) {
    boolean ok = passwordResetService.validateToken(token, email);
    return ok ? ResponseEntity.ok().build() : ResponseEntity.badRequest().body("Invalid token");
  }

  @PostMapping("/reset-password")
  public ResponseEntity<?> resetPassword(@RequestParam String token, @RequestParam String email, @RequestParam String newPassword) {
    boolean ok = passwordResetService.resetPassword(token, email, newPassword);
    return ok ? ResponseEntity.ok().build() : ResponseEntity.badRequest().body("Invalid token or expired");
  }

  @GetMapping("/test-email")
  public ResponseEntity<?> testEmail(@RequestParam String email) {
    try {
      System.out.println("TEST EMAIL: Sending to " + email);
      passwordResetService.sendResetEmail(email, "http://localhost:3000/reset-password");
      return ResponseEntity.ok("Test email sent to " + email + ". Check your inbox and spam folder.");
    } catch (Exception e) {
      e.printStackTrace();
      return ResponseEntity.status(500).body("Failed to send email: " + e.getMessage() + "\nStack trace printed to console.");
    }
  }
}
