package com.advisor.service;

import com.advisor.entity.PasswordResetToken;
import com.advisor.entity.User;
import com.advisor.repository.PasswordResetTokenRepository;
import com.advisor.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class PasswordResetService {
  private static final Duration TOKEN_TTL = Duration.ofMinutes(1);

  private final PasswordResetTokenRepository tokenRepository;
  private final UserRepository userRepository;
  private final PasswordEncoder passwordEncoder;
  private final EmailService emailService;

  public void sendResetEmail(String email, String baseResetUrl) {
    try {
      Optional<User> userOpt = userRepository.findByEmail(email);
      if (userOpt.isEmpty()) {
        throw new RuntimeException("User not found with email: " + email);
      }
      User user = userOpt.get();

      try {
        tokenRepository.deleteByUserId(user.getId());
      } catch (Exception ignored) {}

      String token = UUID.randomUUID().toString().replace("-", "");
      PasswordResetToken prt = new PasswordResetToken();
      prt.setToken(token);
      prt.setUserId(user.getId());
      prt.setExpiresAt(Instant.now().plus(TOKEN_TTL));
      tokenRepository.save(prt);

      String link = baseResetUrl + "?token=" + token + "&email=" + java.net.URLEncoder.encode(user.getEmail(), "UTF-8");
      
      // DEBUG: Log the link so admin can manually share if email fails
      System.out.println("DEBUG: Generated Password Reset Link: " + link);

      String htmlBody = "<div style=\"font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px; background-color: #ffffff;\">" +
          "<h2 style=\"color: #333; text-align: center; margin-bottom: 20px;\">Career Advisor</h2>" +
          "<p style=\"font-size: 16px; color: #555;\">Hi <strong>" + user.getName() + "</strong>,</p>" +
          "<p style=\"font-size: 16px; color: #555;\">We received a request to reset your password. If you made this request, please click the button below to reset your password:</p>" +
          "<div style=\"text-align: center; margin: 30px 0;\">" +
          "  <a href=\"" + link + "\" style=\"background-color: #007bff; color: white; padding: 12px 24px; text-decoration: none; border-radius: 5px; font-size: 16px; font-weight: bold; display: inline-block;\">Reset Password</a>" +
          "</div>" +
          "<p style=\"font-size: 14px; color: #777;\">Or copy and paste this link into your browser:</p>" +
          "<p style=\"font-size: 14px; color: #007bff; word-break: break-all;\"><a href=\"" + link + "\">" + link + "</a></p>" +
          "<hr style=\"border: 0; border-top: 1px solid #eee; margin: 20px 0;\">" +
          "<p style=\"font-size: 12px; color: #999; text-align: center;\">If you didn't request a password reset, you can safely ignore this email.</p>" +
          "</div>";

      System.out.println("Attempting to send password reset email to: " + user.getEmail());
      emailService.sendHtmlEmail(user.getEmail(), "Reset Your Password - Career Advisor", htmlBody);
      
      // Send a copy to the configured mail user to verify delivery path
      try {
        emailService.sendHtmlEmail(emailService.getFromAddress(), "COPY: Reset link sent to " + user.getEmail(), htmlBody);
      } catch (Exception copyErr) {
        System.err.println("Failed to send copy to sender address: " + copyErr.getMessage());
        // Don't fail the main request if copy fails
      }
      
      System.out.println("Password reset email sent successfully to: " + user.getEmail());
    } catch (Exception e) {
      System.err.println("Failed to process password reset request: " + e.getMessage());
      throw new RuntimeException("Failed to send reset email: " + e.getMessage(), e);
    }
  }

  public boolean validateToken(String token, String email) {
    Optional<PasswordResetToken> tokenOpt = tokenRepository.findByToken(token);
    if (tokenOpt.isEmpty()) return false;
    PasswordResetToken prt = tokenOpt.get();
    if (prt.isUsed() || prt.getExpiresAt().isBefore(Instant.now())) {
      return false;
    }
    
    return userRepository.findById(prt.getUserId())
        .map(user -> user.getEmail().equalsIgnoreCase(email))
        .orElse(false);
  }

  public boolean resetPassword(String token, String email, String newPassword) {
    Optional<PasswordResetToken> tokenOpt = tokenRepository.findByToken(token);
    if (tokenOpt.isEmpty()) return false;
    PasswordResetToken prt = tokenOpt.get();
    if (prt.isUsed() || prt.getExpiresAt().isBefore(Instant.now())) {
      return false;
    }

    User user = userRepository.findById(prt.getUserId()).orElse(null);
    if (user == null || !user.getEmail().equalsIgnoreCase(email)) {
      return false;
    }
    
    user.setPassword(passwordEncoder.encode(newPassword));
    userRepository.save(user);

    prt.setUsed(true);
    tokenRepository.save(prt);
    return true;
  }

  @Scheduled(fixedRate = 60_000)
  public void cleanupExpiredTokens() {
    try {
      tokenRepository.deleteByExpiresAtBefore(Instant.now());
    } catch (Exception e) {
      System.err.println("Failed to cleanup expired reset tokens: " + e.getMessage());
    }
  }
}











