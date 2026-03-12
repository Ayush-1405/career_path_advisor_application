package com.advisor.service;

import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class EmailService {
  private final JavaMailSender mailSender;
  @Value("${spring.mail.username}")
  private String fromAddress;

  public String getFromAddress() {
    return fromAddress;
  }

  public void sendPlainText(String to, String subject, String body) {
    try {
      System.out.println("EmailService: Preparing to send email...");
      System.out.println("EmailService: From: " + fromAddress);
      System.out.println("EmailService: To: " + to);
      
      SimpleMailMessage message = new SimpleMailMessage();
      message.setFrom(fromAddress);
      message.setTo(to);
      message.setSubject(subject);
      message.setText(body);
      
      mailSender.send(message);
      System.out.println("EmailService: Email sent successfully via JavaMailSender.");
    } catch (Exception e) {
      System.err.println("EmailService: Failed to send email via JavaMailSender.");
      e.printStackTrace();
      throw e;
    }
  }

  public void sendHtmlEmail(String to, String subject, String htmlBody) {
    try {
      System.out.println("EmailService: Preparing to send HTML email...");
      System.out.println("EmailService: From: " + fromAddress);
      System.out.println("EmailService: To: " + to);

      MimeMessage message = mailSender.createMimeMessage();
      MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
      
      helper.setFrom(fromAddress);
      helper.setTo(to);
      helper.setSubject(subject);
      helper.setText(htmlBody, true); // true indicates HTML content

      mailSender.send(message);
      System.out.println("EmailService: HTML Email sent successfully via JavaMailSender.");
    } catch (Exception e) {
      System.err.println("EmailService: Failed to send HTML email via JavaMailSender.");
      e.printStackTrace();
      throw new RuntimeException("Failed to send HTML email", e);
    }
  }
}











