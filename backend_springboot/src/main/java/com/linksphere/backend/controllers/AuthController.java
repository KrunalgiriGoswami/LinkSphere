package com.linksphere.backend.controllers;

import com.linksphere.backend.dto.LoginRequest;
import com.linksphere.backend.dto.RegisterRequest;
import com.linksphere.backend.models.User;
import com.linksphere.backend.services.UserService;
import com.linksphere.backend.util.JwtUtil;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final UserService userService;
    private final JwtUtil jwtUtil;
    private final AuthenticationManager authenticationManager;

    public AuthController(UserService userService, JwtUtil jwtUtil, AuthenticationManager authenticationManager) {
        this.userService = userService;
        this.jwtUtil = jwtUtil;
        this.authenticationManager = authenticationManager;
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest request) {
        userService.registerUser(request);
        return ResponseEntity.ok("User registered successfully");
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request) {
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword()));
        
        User user = userService.findByEmail(request.getEmail());
        String jwt = jwtUtil.generateToken(request.getEmail(), user.getRole());
        
        Map<String, String> response = new HashMap<>();
        response.put("token", jwt);
        response.put("username", user.getUsername());
        
        return ResponseEntity.ok(response);
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<?> forgotPassword(@RequestBody ForgotPasswordRequest request) {
        // Placeholder: Log email and return success
        // In production, generate a reset token and send an email
        System.out.println("Password reset requested for: " + request.getEmail());
        return ResponseEntity.ok("Password reset instructions sent to " + request.getEmail());
    }

    private static class ForgotPasswordRequest {
        private String email;

        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
    }
}