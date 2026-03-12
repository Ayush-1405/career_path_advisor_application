package com.advisor.service;

import lombok.Getter;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Map;
import java.util.UUID;

@Service
public class ResumeStorageService {

    @Getter
    private final Path storageRoot;

    public ResumeStorageService() {
        this.storageRoot = Paths.get("uploads").toAbsolutePath().normalize();
        try {
            Files.createDirectories(this.storageRoot.resolve("resumes"));
        } catch (Exception ex) {
            throw new RuntimeException("Could not initialize resume storage", ex);
        }
    }

    public StoredFile storeResume(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new RuntimeException("File is required");
        }

        String original = StringUtils.cleanPath(file.getOriginalFilename() == null ? "resume" : file.getOriginalFilename());
        String ext = "";
        int dot = original.lastIndexOf('.');
        if (dot >= 0) ext = original.substring(dot).toLowerCase();

        String storedName = UUID.randomUUID() + ext;
        Path target = storageRoot.resolve("resumes").resolve(storedName);

        try {
            Files.copy(file.getInputStream(), target, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            throw new RuntimeException("Could not store resume file", e);
        }

        return new StoredFile(
                original,
                storedName,
                ext.startsWith(".") ? ext.substring(1) : ext,
                file.getSize(),
                target.toString(),
                null
        );
    }

    public record StoredFile(
            String originalFileName,
            String storedFileName,
            String fileType,
            long fileSize,
            String filePath,
            String fileUrl
    ) {
        public Map<String, Object> toMap() {
            return Map.of(
                    "originalFileName", originalFileName,
                    "storedFileName", storedFileName,
                    "fileType", fileType,
                    "fileSize", fileSize,
                    "filePath", filePath,
                    "fileUrl", fileUrl
            );
        }
    }
}

