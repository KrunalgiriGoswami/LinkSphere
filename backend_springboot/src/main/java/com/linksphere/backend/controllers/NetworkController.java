package com.linksphere.backend.controllers;

import com.linksphere.backend.models.Connection;
import com.linksphere.backend.services.NetworkService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/network")
public class NetworkController {
    private final NetworkService networkService;

    public NetworkController(NetworkService networkService) {
        this.networkService = networkService;
    }

    @GetMapping("/connections")
    public ResponseEntity<List<Connection>> getConnections() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String email = auth.getName();
        List<Connection> connections = networkService.getConnections(email);
        return ResponseEntity.ok(connections);
    }

    @GetMapping("/suggestions")
    public ResponseEntity<List<Connection>> getSuggestions() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String email = auth.getName();
        List<Connection> suggestions = networkService.getSuggestions(email);
        return ResponseEntity.ok(suggestions);
    }

    @PostMapping("/connect/{userId}")
    public ResponseEntity<Void> connect(@PathVariable Long userId) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String email = auth.getName();
        networkService.connect(email, userId);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/disconnect/{userId}")
    public ResponseEntity<Void> disconnect(@PathVariable Long userId) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String email = auth.getName();
        networkService.disconnect(email, userId);
        return ResponseEntity.ok().build();
    }
} 