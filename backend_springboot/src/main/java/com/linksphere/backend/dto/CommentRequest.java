package com.linksphere.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class CommentRequest {
    @NotBlank(message = "Comment content cannot be empty")
    @Size(max = 500, message = "Comment must be less than 500 characters")
    private String content;

    // Default constructor
    public CommentRequest() {
    }

    // Getters and Setters
    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    @Override
    public String toString() {
        return "CommentRequest{" +
                "content='" + content + '\'' +
                '}';
    }
} 