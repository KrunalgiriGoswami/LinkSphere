package com.linksphere.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class PostRequest {
    @NotBlank(message = "Description cannot be empty")
    @Size(max = 1000, message = "Description must be less than 1000 characters")
    private String description;
    private String mediaUrls; // Comma-separated URLs or paths
    private String mediaTypes; // Comma-separated types (e.g., "image,video,pdf")

    // Default constructor
    public PostRequest() {
    }

    // Parameterized constructor
    public PostRequest(String description, String mediaUrls, String mediaTypes) {
        this.description = description;
        this.mediaUrls = mediaUrls;
        this.mediaTypes = mediaTypes;
    }

    // Getters and Setters
    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getMediaUrls() {
        return mediaUrls;
    }

    public void setMediaUrls(String mediaUrls) {
        this.mediaUrls = mediaUrls;
    }

    public String getMediaTypes() {
        return mediaTypes;
    }

    public void setMediaTypes(String mediaTypes) {
        this.mediaTypes = mediaTypes;
    }

    @Override
    public String toString() {
        return "PostRequest{" +
                "description='" + description + '\'' +
                ", mediaUrls='" + mediaUrls + '\'' +
                ", mediaTypes='" + mediaTypes + '\'' +
                '}';
    }
}