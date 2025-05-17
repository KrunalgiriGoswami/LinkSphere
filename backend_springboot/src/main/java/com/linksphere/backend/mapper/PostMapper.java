package com.linksphere.backend.mapper;

import com.linksphere.backend.models.Post;
import org.springframework.jdbc.core.RowMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;

public class PostMapper implements RowMapper<Post> {
    private static final Logger logger = LoggerFactory.getLogger(PostMapper.class);

    @Override
    public Post mapRow(ResultSet rs, int rowNum) throws SQLException {
        try {
            Post post = new Post();
            post.setId(rs.getLong("id"));
            post.setUserId(rs.getLong("user_id"));
            post.setUsername(rs.getString("username"));
            
            // Handle optional fields
            try {
                post.setProfilePicture(rs.getString("profile_picture"));
            } catch (SQLException e) {
                logger.warn("profile_picture column not found or null");
                post.setProfilePicture(null);
            }

            post.setDescription(rs.getString("description"));
            
            // Handle media fields
            String mediaUrls = rs.getString("media_urls");
            post.setMediaUrls(mediaUrls != null ? mediaUrls : "");
            
            String mediaTypes = rs.getString("media_types");
            post.setMediaTypes(mediaTypes != null ? mediaTypes : "");
            
            // Handle counts with default values
            post.setLikesCount(rs.getInt("likes_count"));
            post.setCommentsCount(rs.getInt("comments_count"));
            post.setSavesCount(rs.getInt("saves_count"));
            
            // Handle timestamps
            Timestamp createdAt = rs.getTimestamp("created_at");
            if (createdAt != null) {
                post.setCreatedAt(createdAt.toLocalDateTime());
            }
            
            Timestamp updatedAt = rs.getTimestamp("updated_at");
            if (updatedAt != null) {
                post.setUpdatedAt(updatedAt.toLocalDateTime());
            }
            
            return post;
        } catch (SQLException e) {
            logger.error("Error mapping post row: {}", e.getMessage(), e);
            throw e;
        }
    }
}