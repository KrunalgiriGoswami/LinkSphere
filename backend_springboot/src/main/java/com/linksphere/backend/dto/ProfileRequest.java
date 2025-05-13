package com.linksphere.backend.dto;

import jakarta.validation.constraints.Size;

public class ProfileRequest {
    @Size(max = 100, message = "Headline must be less than 100 characters")
    private String headline;

    @Size(max = 500, message = "About section must be less than 500 characters")
    private String about;

    @Size(max = 255, message = "Skills must be less than 255 characters")
    private String skills;

    // Getters and Setters
    public String getHeadline() { return headline; }
    public void setHeadline(String headline) { this.headline = headline; }
    public String getAbout() { return about; }
    public void setAbout(String about) { this.about = about; }
    public String getSkills() { return skills; }
    public void setSkills(String skills) { this.skills = skills; }
}