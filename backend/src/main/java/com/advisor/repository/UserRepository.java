package com.advisor.repository;

//repository/UserRepository.java


import com.advisor.entity.*;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface UserRepository extends MongoRepository<User, String> {
Optional<User> findByEmail(String email);
boolean existsByEmail(String email);
long countByRole(Role role);
List<User> findByRole(Role role);
long countByIsActiveTrue();
long countByCreatedAtAfter(LocalDateTime date);
long countByLastLoginAfter(LocalDateTime date);
    long countByEmailVerifiedTrue();

    @org.springframework.data.mongodb.repository.Query(value = "{}", fields = "{ 'role' : 1, 'createdAt' : 1 }")
    List<User> findAllProjectedBy();
}
