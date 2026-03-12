package com.advisor.service;

import com.advisor.entity.SystemSettings;
import com.advisor.repository.SystemSettingsRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import jakarta.annotation.PostConstruct;
import java.util.List;

@Service
@RequiredArgsConstructor
public class SystemSettingsService {
    private final SystemSettingsRepository settingsRepository;

    @PostConstruct
    public void init() {
        if (settingsRepository.count() == 0) {
            SystemSettings defaultSettings = new SystemSettings();
            defaultSettings.setSiteName("Career Advisor");
            defaultSettings.setAllowRegistrations(true);
            defaultSettings.setRequireEmailVerification(false);
            defaultSettings.setResumeMaxSizeMb(5);
            defaultSettings.setSupportedFormats(List.of("pdf", "doc", "docx"));
            defaultSettings.setAiAssistantEnabled(true);
            settingsRepository.save(defaultSettings);
        }
    }

    public SystemSettings getSettings() {
        return settingsRepository
                .findAll()
                .stream()
                .findFirst()
                .orElseGet(() -> {
                    SystemSettings defaultSettings = new SystemSettings();
                    defaultSettings.setSiteName("Career Advisor");
                    defaultSettings.setAllowRegistrations(true);
                    defaultSettings.setRequireEmailVerification(false);
                    defaultSettings.setResumeMaxSizeMb(5);
                    defaultSettings.setSupportedFormats(List.of("pdf", "doc", "docx"));
                    defaultSettings.setAiAssistantEnabled(true);
                    return settingsRepository.save(defaultSettings);
                });
    }

    public SystemSettings updateSettings(SystemSettings newSettings) {
        SystemSettings current = getSettings();
        current.setSiteName(newSettings.getSiteName());
        current.setAllowRegistrations(newSettings.getAllowRegistrations());
        current.setRequireEmailVerification(newSettings.getRequireEmailVerification());
        current.setResumeMaxSizeMb(newSettings.getResumeMaxSizeMb());
        current.setSupportedFormats(newSettings.getSupportedFormats());
        current.setAiAssistantEnabled(newSettings.getAiAssistantEnabled());
        return settingsRepository.save(current);
    }
}
