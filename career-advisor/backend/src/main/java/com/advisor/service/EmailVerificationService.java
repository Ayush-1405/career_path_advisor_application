package com.advisor.service;

import com.advisor.entity.EmailOtp;
import com.advisor.entity.User;
import com.advisor.repository.EmailOtpRepository;
import com.advisor.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.Optional;
import java.util.concurrent.ThreadLocalRandom;

@Service
@RequiredArgsConstructor
public class EmailVerificationService {
  private static final Duration OTP_TTL = Duration.ofMinutes(10);

  private final EmailOtpRepository emailOtpRepository;
  private final UserRepository userRepository;
  private final EmailService emailService;

  public synchronized void sendOtp(String email) {
    Optional<User> userOpt = userRepository.findByEmail(email);
    if (userOpt.isEmpty()) {
      throw new RuntimeException("Email not registered");
    }

    // Rate limiting: Check if an active OTP was sent in the last 60 seconds
    Optional<EmailOtp> existing = emailOtpRepository.findFirstByEmailOrderByCreatedAtDesc(email);
    if (existing.isPresent()) {
      EmailOtp lastOtp = existing.get();
      Instant now = Instant.now();
      if (!lastOtp.isUsed() && lastOtp.getCreatedAt().plus(Duration.ofSeconds(60)).isAfter(now)) {
        long wait = Duration.between(now, lastOtp.getCreatedAt().plus(Duration.ofSeconds(60))).toSeconds();
        throw new RuntimeException("Please wait " + wait + " seconds before requesting a new OTP.");
      }
    }

    User user = userOpt.get();
    String code = String.format("%06d", ThreadLocalRandom.current().nextInt(0, 1_000_000));

    EmailOtp otp = new EmailOtp();
    otp.setEmail(email);
    otp.setCode(code);
    otp.setExpiresAt(Instant.now().plus(OTP_TTL));
    otp.setCreatedAt(Instant.now()); // Explicitly set for accurate rate limiting
    emailOtpRepository.save(otp);

    System.out.println("DEBUG: Generated Email OTP for " + email + ": " + code);

    String htmlBody =
        "<div style='font-family: Arial, sans-serif; padding: 16px;'>"
            + "<h2>Verify your email</h2>"
            + "<p>Hi " + user.getName() + ",</p>"
            + "<p>Your one-time verification code is:</p>"
            + "<div style='font-size: 28px; font-weight: bold; letter-spacing: 4px;'>"
            + code
            + "</div>"
            + "<p>This code expires in 10 minutes.</p>"
            + "<p>If you did not request this, you can ignore this email.</p>"
            + "<hr style='margin-top:16px'/>"
            + "<small>Career Advisor</small>"
            + "</div>";

    try {
      emailService.sendHtmlEmail(email, "Your OTP Code", htmlBody);
    } catch (Exception ex) {
      try {
        emailService.sendPlainText(email, "Your OTP Code", "Your verification code is: " + code);
      } catch (Exception ex2) {
        System.err.println("Failed to send OTP email to " + email + ": " + ex2.getMessage());
      }
    }
  }

  public boolean verifyOtp(String email, String code) {
    boolean ok = checkAndUseOtp(email, code);
    if (ok) {
      User user = userRepository.findByEmail(email).orElseThrow(() -> new RuntimeException("User not found"));
      user.setEmailVerified(true);
      userRepository.save(user);
    }
    return ok;
  }

  public boolean verifyOtpForLogin(String email, String code) {
    return checkAndUseOtp(email, code);
  }

  private boolean checkAndUseOtp(String email, String code) {
    System.out.println("DEBUG: Checking OTP for email: " + email + ", code: " + code);
    Optional<EmailOtp> otpOpt = emailOtpRepository.findFirstByEmailAndCodeOrderByCreatedAtDesc(email, code);
    if (otpOpt.isEmpty()) {
      System.out.println("DEBUG: No OTP found for email: " + email + " and code: " + code);
      return false;
    }
    EmailOtp otp = otpOpt.get();
    if (otp.isUsed()) {
      System.out.println("DEBUG: OTP already used for email: " + email);
      return false;
    }
    if (otp.getExpiresAt().isBefore(Instant.now())) {
      System.out.println("DEBUG: OTP expired for email: " + email + ". Expires at: " + otp.getExpiresAt() + ", Now: " + Instant.now());
      return false;
    }
    otp.setUsed(true);
    emailOtpRepository.save(otp);
    System.out.println("DEBUG: OTP verification successful for email: " + email);
    return true;
  }
}
