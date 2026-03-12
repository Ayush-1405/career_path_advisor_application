package com.advisor.service;

import com.advisor.security.JwtUtil;

//security/JwtFilter.java

import com.advisor.service.*;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Component
@RequiredArgsConstructor
public class JwtFilter extends OncePerRequestFilter {

private final JwtUtil jwtUtil;
private final CustomUserDetailsService userDetailsService;

@Override
protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
   throws ServletException, IOException {

 String auth = request.getHeader("Authorization");
 if (auth != null && auth.startsWith("Bearer ")) {
   String token = auth.substring(7);
   if (jwtUtil.validate(token)) {
     String email = jwtUtil.extractSubject(token);

     if (email != null && SecurityContextHolder.getContext().getAuthentication() == null) {
       UserDetails ud = userDetailsService.loadUserByUsername(email);
       UsernamePasswordAuthenticationToken authToken =
           new UsernamePasswordAuthenticationToken(ud, null, ud.getAuthorities());
       authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
       SecurityContextHolder.getContext().setAuthentication(authToken);
     }
   }
 }

 chain.doFilter(request, response);
}
}
