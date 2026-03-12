package com.advisor.entity;

import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.mapping.Document;
import lombok.*;
import java.util.List;

@Document(collection = "system_settings")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor
@Builder
public class SystemSettings {
    @Id
    private String id;

    @Builder.Default
    private String siteName = "Career Advisor";

    @Builder.Default
    private Boolean allowRegistrations = true;

    @Builder.Default
    private Boolean requireEmailVerification = false;

    @Builder.Default
    private Integer resumeMaxSizeMb = 5;

    private List<String> supportedFormats;

    @Builder.Default
    private Boolean aiAssistantEnabled = true;
}
