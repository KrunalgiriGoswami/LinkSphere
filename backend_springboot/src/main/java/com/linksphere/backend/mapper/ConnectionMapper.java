package com.linksphere.backend.mapper;

import com.linksphere.backend.models.Connection;
import org.springframework.jdbc.core.RowMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;

public class ConnectionMapper implements RowMapper<Connection> {
    private static final Logger logger = LoggerFactory.getLogger(ConnectionMapper.class);

    @Override
    public Connection mapRow(ResultSet rs, int rowNum) throws SQLException {
        try {
            Connection connection = new Connection();
            connection.setId(rs.getLong("id"));
            connection.setUserId(rs.getLong("user_id"));
            connection.setConnectedUserId(rs.getLong("connected_user_id"));
            connection.setUsername(rs.getString("username"));
            
            // Handle optional fields
            try {
                connection.setProfilePicture(rs.getString("profile_picture"));
            } catch (SQLException e) {
                logger.warn("profile_picture column not found or null");
                connection.setProfilePicture(null);
            }

            try {
                connection.setHeadline(rs.getString("headline"));
            } catch (SQLException e) {
                logger.warn("headline column not found or null");
                connection.setHeadline(null);
            }
            
            // Handle timestamps
            Timestamp createdAt = rs.getTimestamp("created_at");
            if (createdAt != null) {
                connection.setCreatedAt(createdAt.toLocalDateTime());
            }
            
            Timestamp updatedAt = rs.getTimestamp("updated_at");
            if (updatedAt != null) {
                connection.setUpdatedAt(updatedAt.toLocalDateTime());
            }
            
            return connection;
        } catch (SQLException e) {
            logger.error("Error mapping connection row: {}", e.getMessage());
            throw e;
        }
    }
} 