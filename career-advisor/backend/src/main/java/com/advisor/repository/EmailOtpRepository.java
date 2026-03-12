package com.advisor.repository;

import com.advisor.entity.EmailOtp;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.util.Optional;

public interface EmailOtpRepository extends MongoRepository<EmailOtp, String> {
  Optional<EmailOtp> findFirstByEmailOrderByCreatedAtDesc(String email);
  Optional<EmailOtp> findFirstByEmailAndCodeOrderByCreatedAtDesc(String email, String code);
}
