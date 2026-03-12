package com.advisor.dto;

import com.advisor.entity.ResumeProfile;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.ArrayList;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ResumeUpdateRequest {
    private String userId; // optional; if missing, use auth user

    private String name;
    private String email;
    private String phone;
    private String summary;
    private List<String> skills = new ArrayList<>();

    private List<ResumeProfile.EducationEntry> education = new ArrayList<>();
    private List<ResumeProfile.ExperienceEntry> experience = new ArrayList<>();
    private List<ResumeProfile.ProjectEntry> projects = new ArrayList<>();
}

