package com.advisor.repository;

import com.advisor.entity.PasswordResetToken;
import org.springframework.data.mongodb.repository.MongoRepository;
import java.time.Instant;

import java.util.Optional;

public interface PasswordResetTokenRepository extends MongoRepository<PasswordResetToken, String> {
  Optional<PasswordResetToken> findByToken(String token);
  void deleteByUserId(String userId);
  void deleteByExpiresAtBefore(Instant threshold);
}











