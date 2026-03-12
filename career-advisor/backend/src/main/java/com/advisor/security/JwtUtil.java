package com.advisor.security;

//security/JwtUtil.java

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.security.Key;
import java.util.Date;
import java.util.Map;

@Component
public class JwtUtil {
@Value("${jwt.secret}")
private String secret;

@Value("${jwt.expiration-ms}")
private long expirationMs;

private Key key;

@PostConstruct
public void init() {
 this.key = Keys.hmacShaKeyFor(secret.getBytes());
}

public String generateToken(String subject, Map<String,Object> claims) {
 return Jwts.builder()
     .setClaims(claims)
     .setSubject(subject)
     .setIssuedAt(new Date())
     .setExpiration(new Date(System.currentTimeMillis() + expirationMs))
     .signWith(key, SignatureAlgorithm.HS256)
     .compact();
}

public String extractSubject(String token) {
 return Jwts.parserBuilder().setSigningKey(key).build()
     .parseClaimsJws(token).getBody().getSubject();
}

public Claims extractAllClaims(String token) {
 return Jwts.parserBuilder().setSigningKey(key).build()
     .parseClaimsJws(token).getBody();
}

public boolean validate(String token) {
 try {
   Jwts.parserBuilder().setSigningKey(key).build().parseClaimsJws(token);
   return true;
 } catch (JwtException | IllegalArgumentException e) {
   return false;
 }
}
}
