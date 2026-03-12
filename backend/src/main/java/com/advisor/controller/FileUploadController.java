package com.advisor.controller;

import com.advisor.service.SystemSettingsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/uploads")
public class FileUploadController {

    private final Path fileStorageLocation;
    
    @Autowired
    private SystemSettingsService systemSettingsService;

    public FileUploadController() {
        this.fileStorageLocation = Paths.get("uploads").toAbsolutePath().normalize();
        try {
            Files.createDirectories(this.fileStorageLocation);
        } catch (Exception ex) {
            throw new RuntimeException("Could not create the directory where the uploaded files will be stored.", ex);
        }
    }

    @PostMapping("/image")
    public ResponseEntity<Map<String, String>> uploadImage(@RequestParam("file") MultipartFile file) {
        return uploadFile(file, "images");
    }

    @PostMapping("/resume")
    public ResponseEntity<Map<String, String>> uploadResume(@RequestParam("file") MultipartFile file) {
        var settings = systemSettingsService.getSettings();
        
        // Check file size (convert MB to bytes)
        long maxSize = (long) settings.getResumeMaxSizeMb() * 1024 * 1024;
        if (file.getSize() > maxSize) {
            throw new RuntimeException("File size exceeds the maximum limit of " + settings.getResumeMaxSizeMb() + "MB");
        }

        // Check file extension
        String originalFileName = file.getOriginalFilename();
        if (originalFileName != null) {
            String ext = originalFileName.substring(originalFileName.lastIndexOf(".") + 1).toLowerCase();
            boolean isSupported = settings.getSupportedFormats().stream()
                    .anyMatch(format -> format.equalsIgnoreCase(ext));
            if (!isSupported) {
                throw new RuntimeException("File format not supported. Allowed: " + String.join(", ", settings.getSupportedFormats()));
            }
        }

        return uploadFile(file, "resumes");
    }

    private ResponseEntity<Map<String, String>> uploadFile(MultipartFile file, String subDir) {
        // Normalize file name
        String originalFileName = StringUtils.cleanPath(file.getOriginalFilename());
        String fileExtension = "";
        try {
            fileExtension = originalFileName.substring(originalFileName.lastIndexOf("."));
        } catch(Exception e) {
            fileExtension = "";
        }
        
        String fileName = UUID.randomUUID().toString() + fileExtension;

        try {
            // Check if the file's name contains invalid characters
            if(fileName.contains("..")) {
                throw new RuntimeException("Sorry! Filename contains invalid path sequence " + fileName);
            }

            // Create subdirectory if it doesn't exist
            Path targetDir = this.fileStorageLocation.resolve(subDir);
            Files.createDirectories(targetDir);

            // Copy file to the target location (Replacing existing file with the same name)
            Path targetLocation = targetDir.resolve(fileName);
            Files.copy(file.getInputStream(), targetLocation, StandardCopyOption.REPLACE_EXISTING);

            // Build the file download URI
            String fileDownloadUri = ServletUriComponentsBuilder.fromCurrentContextPath()
                    .path("/uploads/")
                    .path(subDir + "/")
                    .path(fileName)
                    .toUriString();

            Map<String, String> response = new HashMap<>();
            response.put("url", fileDownloadUri);
            response.put("fileName", fileName);
            response.put("originalFileName", originalFileName);
            response.put("size", String.valueOf(file.getSize()));
            response.put("path", targetLocation.toString());

            return ResponseEntity.ok(response);
        } catch (IOException ex) {
            throw new RuntimeException("Could not store file " + fileName + ". Please try again!", ex);
        }
    }
}
