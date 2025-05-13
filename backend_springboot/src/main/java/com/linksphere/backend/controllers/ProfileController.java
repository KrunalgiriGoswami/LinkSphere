package com.linksphere.backend.controllers;

import com.linksphere.backend.dto.ProfileRequest;
import com.linksphere.backend.models.Profile;
import com.linksphere.backend.services.ProfileService;
import com.linksphere.backend.services.UserService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/profile")
public class ProfileController {
    private final ProfileService profileService;
    private final UserService userService;

    public ProfileController(ProfileService profileService, UserService userService) {
        this.profileService = profileService;
        this.userService = userService;
    }

    @PostMapping
    public ResponseEntity<?> createProfile(@Valid @RequestBody ProfileRequest request) {
        Long userId = getCurrentUserId();
        profileService.createProfile(userId, request);
        return ResponseEntity.ok("Profile created successfully");
    }

    @PutMapping
    public ResponseEntity<?> updateProfile(@Valid @RequestBody ProfileRequest request) {
        Long userId = getCurrentUserId();
        profileService.updateProfile(userId, request);
        return ResponseEntity.ok("Profile updated successfully");
    }

    @GetMapping
    public ResponseEntity<Profile> getProfile() {
        Long userId = getCurrentUserId();
        Profile profile = profileService.getProfile(userId);
        return ResponseEntity.ok(profile);
    }

    private Long getCurrentUserId() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        var user = userService.findByEmail(email);
        if (user == null) {
            throw new RuntimeException("User not found for email: " + email);
        }
        return user.getId();
    }
}