package com.linksphere.backend.services;

import com.linksphere.backend.mapper.ConnectionMapper;
import com.linksphere.backend.models.Connection;
import com.linksphere.backend.models.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class NetworkService {
    private static final Logger logger = LoggerFactory.getLogger(NetworkService.class);
    private final JdbcTemplate jdbcTemplate;
    private final UserService userService;

    public NetworkService(JdbcTemplate jdbcTemplate, UserService userService) {
        this.jdbcTemplate = jdbcTemplate;
        this.userService = userService;
    }

    public List<Connection> getConnections(String email) {
        logger.info("Fetching connections for user with email: {}", email);
        User user = userService.findByEmail(email);
        if (user == null) {
            throw new RuntimeException("User not found");
        }

        try {
            String sql = """
                SELECT c.*, u.username, p.profile_picture, p.headline
                FROM connections c
                JOIN users u ON c.connected_user_id = u.id
                LEFT JOIN profiles p ON c.connected_user_id = p.user_id
                WHERE c.user_id = ?
                ORDER BY c.created_at DESC
                """;
            List<Connection> connections = jdbcTemplate.query(sql, new ConnectionMapper(), user.getId());
            logger.info("Successfully fetched {} connections for user: {}", connections.size(), user.getId());
            return connections;
        } catch (Exception e) {
            logger.error("Error fetching connections: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to fetch connections: " + e.getMessage());
        }
    }

    public List<Connection> getSuggestions(String email) {
        logger.info("Fetching connection suggestions for user with email: {}", email);
        User user = userService.findByEmail(email);
        if (user == null) {
            throw new RuntimeException("User not found");
        }

        try {
            // Get all users except the current user
            String sql = """
                SELECT 
                    u.id, 
                    u.id as user_id, 
                    u.id as connected_user_id, 
                    u.username, 
                    p.profile_picture, 
                    COALESCE(p.headline, 'LinkSphere User') as headline,
                    NOW() as created_at, 
                    NOW() as updated_at
                FROM users u
                LEFT JOIN profiles p ON u.id = p.user_id
                WHERE u.id != ?
                AND u.id NOT IN (
                    SELECT connected_user_id
                    FROM connections
                    WHERE user_id = ?
                )
                ORDER BY u.username ASC
                """;
            List<Connection> suggestions = jdbcTemplate.query(sql, new ConnectionMapper(), user.getId(), user.getId());
            logger.info("Successfully fetched {} suggestions for user: {}", suggestions.size(), user.getId());
            return suggestions;
        } catch (Exception e) {
            logger.error("Error fetching suggestions: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to fetch suggestions: " + e.getMessage());
        }
    }

    public void connect(String email, Long connectedUserId) {
        logger.info("Connecting user with email: {} to user: {}", email, connectedUserId);
        User user = userService.findByEmail(email);
        if (user == null) {
            throw new RuntimeException("User not found");
        }

        // Check if already connected
        String checkSql = "SELECT COUNT(*) FROM connections WHERE user_id = ? AND connected_user_id = ?";
        int count = jdbcTemplate.queryForObject(checkSql, Integer.class, user.getId(), connectedUserId);
        if (count > 0) {
            return; // Already connected
        }

        try {
            // Create bidirectional connection
            String sql = "INSERT INTO connections (user_id, connected_user_id, created_at, updated_at) VALUES (?, ?, NOW(), NOW())";
            jdbcTemplate.update(sql, user.getId(), connectedUserId);
            jdbcTemplate.update(sql, connectedUserId, user.getId());
            logger.info("Successfully created connection between users: {} and {}", user.getId(), connectedUserId);
        } catch (Exception e) {
            logger.error("Error creating connection: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to create connection: " + e.getMessage());
        }
    }

    public void disconnect(String email, Long connectedUserId) {
        logger.info("Disconnecting user with email: {} from user: {}", email, connectedUserId);
        User user = userService.findByEmail(email);
        if (user == null) {
            throw new RuntimeException("User not found");
        }

        try {
            // Remove bidirectional connection
            String sql = "DELETE FROM connections WHERE (user_id = ? AND connected_user_id = ?) OR (user_id = ? AND connected_user_id = ?)";
            int rowsAffected = jdbcTemplate.update(sql, user.getId(), connectedUserId, connectedUserId, user.getId());
            logger.info("Successfully removed {} connection records between users: {} and {}", rowsAffected, user.getId(), connectedUserId);
        } catch (Exception e) {
            logger.error("Error removing connection: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to remove connection: " + e.getMessage());
        }
    }
} 