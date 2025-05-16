package com.linksphere.backend.dto;

import jakarta.validation.constraints.Size;

public class ProfileRequest {
    @Size(max = 100, message = "Headline must be less than 100 characters")
    private String headline;

    @Size(max = 500, message = "About section must be less than 500 characters")
    private String about;

    @Size(max = 255, message = "Skills must be less than 255 characters")
    private String skills;

    @Size(max = 1000, message = "Education JSON must be less than 1000 characters")
    private String education; // JSON string representing a list

    @Size(max = 1000, message = "Experience JSON must be less than 1000 characters")
    private String experience; // JSON string representing a list

    @Size(max = 1000, message = "Location JSON must be less than 1000 characters")
    private String location; // JSON string representing a map

    @Size(max = 1000, message = "Contact Info JSON must be less than 1000 characters")
    private String contactInfo; // JSON string representing a map

    // Getters and Setters
    public String getHeadline() { return headline; }
    public void setHeadline(String headline) { this.headline = headline; }
    public String getAbout() { return about; }
    public void setAbout(String about) { this.about = about; }
    public String getSkills() { return skills; }
    public void setSkills(String skills) { this.skills = skills; }
    public String getEducation() { return education; }
    public void setEducation(String education) { this.education = education; }
    public String getExperience() { return experience; }
    public void setExperience(String experience) { this.experience = experience; }
    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }
    public String getContactInfo() { return contactInfo; }
    public void setContactInfo(String contactInfo) { this.contactInfo = contactInfo; }
}