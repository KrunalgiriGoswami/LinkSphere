package com.linksphere.backend.models;

import java.time.LocalDateTime;

public class Post {
    private Long id;
    private Long userId;
    private String username;
    private String profilePicture;
    private String description;
    private String mediaUrls; // Comma-separated URLs or paths
    private String mediaTypes; // Comma-separated types (e.g., "image,video,pdf")
    private int likesCount;
    private int commentsCount;
    private int savesCount;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    // Default constructor
    public Post() {
    }

    // Parameterized constructor
    public Post(Long id, Long userId, String username, String profilePicture, String description,
                String mediaUrls, String mediaTypes, int likesCount, int commentsCount, int savesCount,
                LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id;
        this.userId = userId;
        this.username = username;
        this.profilePicture = profilePicture;
        this.description = description;
        this.mediaUrls = mediaUrls;
        this.mediaTypes = mediaTypes;
        this.likesCount = likesCount;
        this.commentsCount = commentsCount;
        this.savesCount = savesCount;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getProfilePicture() {
        return profilePicture;
    }

    public void setProfilePicture(String profilePicture) {
        this.profilePicture = profilePicture;
    }

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

    public int getLikesCount() {
        return likesCount;
    }

    public void setLikesCount(int likesCount) {
        this.likesCount = likesCount;
    }

    public int getCommentsCount() {
        return commentsCount;
    }

    public void setCommentsCount(int commentsCount) {
        this.commentsCount = commentsCount;
    }

    public int getSavesCount() {
        return savesCount;
    }

    public void setSavesCount(int savesCount) {
        this.savesCount = savesCount;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    @Override
    public String toString() {
        return "Post{" +
                "id=" + id +
                ", userId=" + userId +
                ", username='" + username + '\'' +
                ", profilePicture='" + profilePicture + '\'' +
                ", description='" + description + '\'' +
                ", mediaUrls='" + mediaUrls + '\'' +
                ", mediaTypes='" + mediaTypes + '\'' +
                ", likesCount=" + likesCount +
                ", commentsCount=" + commentsCount +
                ", savesCount=" + savesCount +
                ", createdAt=" + createdAt +
                ", updatedAt=" + updatedAt +
                '}';
    }
}