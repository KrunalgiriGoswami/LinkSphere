package com.linksphere.backend.services;

import com.linksphere.backend.dto.PostRequest;
import com.linksphere.backend.mapper.PostMapper;
import com.linksphere.backend.models.Comment;
import com.linksphere.backend.models.Post;
import com.linksphere.backend.models.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class PostService {
    private static final Logger logger = LoggerFactory.getLogger(PostService.class);
    private final JdbcTemplate jdbcTemplate;
    private final UserService userService;

    @Value("${app.upload.dir:uploads}")
    private String uploadDir;

    public PostService(JdbcTemplate jdbcTemplate, UserService userService) {
        this.jdbcTemplate = jdbcTemplate;
        this.userService = userService;
    }

    public String uploadMedia(MultipartFile file) {
        try {
            logger.info("Starting media upload for file: {}", file.getOriginalFilename());
            // Create uploads directory if it doesn't exist
            Path uploadPath = Paths.get(uploadDir);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
                logger.info("Created upload directory: {}", uploadPath);
            }

            // Generate unique filename
            String filename = UUID.randomUUID().toString() + "_" + file.getOriginalFilename();
            Path filePath = uploadPath.resolve(filename);

            // Save file
            Files.copy(file.getInputStream(), filePath);
            logger.info("Successfully uploaded file to: {}", filePath);

            // Return relative path
            return "/uploads/" + filename;
        } catch (IOException e) {
            logger.error("Failed to upload media file", e);
            throw new RuntimeException("Failed to store file", e);
        }
    }

    public Post createPost(String email, PostRequest request) {
        logger.info("Creating post for user with email: {}", email);
        try {
            User user = userService.findByEmail(email);
            if (user == null) {
                logger.error("User not found for email: {}", email);
                throw new RuntimeException("User not found");
            }

            logger.info("Request details - Description: {}, MediaUrls: {}, MediaTypes: {}",
                    request.getDescription(), request.getMediaUrls(), request.getMediaTypes());

            // Get user's profile picture
            String profilePicture = null;
            try {
                String profileSql = "SELECT profile_picture FROM profiles WHERE user_id = ?";
                profilePicture = jdbcTemplate.queryForObject(profileSql, String.class, user.getId());
                logger.info("Retrieved profile picture for user: {}", user.getId());
            } catch (Exception e) {
                logger.warn("Could not retrieve profile picture for user: {}", user.getId());
            }

            // Insert post with profile picture
            String sql = "INSERT INTO posts (user_id, username, profile_picture, description, media_urls, media_types, created_at, updated_at) " +
                    "VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW())";
            jdbcTemplate.update(sql,
                    user.getId(),
                    user.getUsername(),
                    profilePicture,
                    request.getDescription(),
                    request.getMediaUrls(),
                    request.getMediaTypes());
            logger.info("Successfully inserted post for user: {}", user.getId());

            // Retrieve created post
            String selectSql = "SELECT * FROM posts WHERE user_id = ? ORDER BY created_at DESC LIMIT 1";
            Post createdPost = jdbcTemplate.queryForObject(selectSql, new PostMapper(), user.getId());
            if (createdPost != null) {
                logger.info("Successfully retrieved created post with ID: {}", createdPost.getId());
                return createdPost;
            } else {
                logger.error("Failed to retrieve created post for user: {}", user.getId());
                throw new RuntimeException("Failed to retrieve created post");
            }
        } catch (Exception e) {
            logger.error("Error in createPost: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to create post: " + e.getMessage());
        }
    }

    public Post updatePost(Long postId, String email, PostRequest request) {
        User user = userService.findByEmail(email);
        if (user == null) {
            throw new RuntimeException("User not found");
        }

        // Verify post ownership
        String ownershipSql = "SELECT COUNT(*) FROM posts WHERE id = ? AND user_id = ?";
        int count = jdbcTemplate.queryForObject(ownershipSql, Integer.class, postId, user.getId());
        if (count == 0) {
            throw new RuntimeException("Post not found or user not authorized");
        }

        // Update post
        String sql = "UPDATE posts SET description = ?, media_urls = ?, media_types = ?, updated_at = ? WHERE id = ?";
        jdbcTemplate.update(sql,
                request.getDescription(),
                request.getMediaUrls(),
                request.getMediaTypes(),
                LocalDateTime.now(),
                postId);

        // Return updated post
        String selectSql = "SELECT * FROM posts WHERE id = ?";
        return jdbcTemplate.queryForObject(selectSql, new PostMapper(), postId);
    }

    public void deletePost(Long postId, String email) {
        User user = userService.findByEmail(email);
        if (user == null) {
            throw new RuntimeException("User not found");
        }

        String sql = "DELETE FROM posts WHERE id = ? AND user_id = ?";
        int rowsAffected = jdbcTemplate.update(sql, postId, user.getId());
        if (rowsAffected == 0) {
            throw new RuntimeException("Post not found or user not authorized");
        }
    }

    public List<Post> getAllPosts() {
        logger.info("Fetching all posts");
        try {
            String sql = "SELECT * FROM posts ORDER BY created_at DESC";
            List<Post> posts = jdbcTemplate.query(sql, new PostMapper());
            logger.info("Successfully fetched {} posts", posts.size());
            return posts;
        } catch (Exception e) {
            logger.error("Error fetching posts: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to fetch posts: " + e.getMessage());
        }
    }

    public void likePost(Long postId, String email) {
        User user = userService.findByEmail(email);
        if (user == null) {
            throw new RuntimeException("User not found");
        }

        // Check if already liked
        String checkSql = "SELECT COUNT(*) FROM post_likes WHERE post_id = ? AND user_id = ?";
        int count = jdbcTemplate.queryForObject(checkSql, Integer.class, postId, user.getId());
        if (count > 0) {
            return; // Already liked
        }

        // Add like
        String sql = "INSERT INTO post_likes (post_id, user_id) VALUES (?, ?)";
        jdbcTemplate.update(sql, postId, user.getId());

        // Update likes count
        String updateSql = "UPDATE posts SET likes_count = likes_count + 1 WHERE id = ?";
        jdbcTemplate.update(updateSql, postId);
    }

    public void unlikePost(Long postId, String email) {
        User user = userService.findByEmail(email);
        if (user == null) {
            throw new RuntimeException("User not found");
        }

        // Remove like
        String sql = "DELETE FROM post_likes WHERE post_id = ? AND user_id = ?";
        int rowsAffected = jdbcTemplate.update(sql, postId, user.getId());

        if (rowsAffected > 0) {
            // Update likes count
            String updateSql = "UPDATE posts SET likes_count = likes_count - 1 WHERE id = ?";
            jdbcTemplate.update(updateSql, postId);
        }
    }

    public void savePost(Long postId, String email) {
        User user = userService.findByEmail(email);
        if (user == null) {
            throw new RuntimeException("User not found");
        }

        // Check if already saved
        String checkSql = "SELECT COUNT(*) FROM post_saves WHERE post_id = ? AND user_id = ?";
        int count = jdbcTemplate.queryForObject(checkSql, Integer.class, postId, user.getId());
        if (count > 0) {
            return; // Already saved
        }

        // Add save
        String sql = "INSERT INTO post_saves (post_id, user_id) VALUES (?, ?)";
        jdbcTemplate.update(sql, postId, user.getId());

        // Update saves count
        String updateSql = "UPDATE posts SET saves_count = saves_count + 1 WHERE id = ?";
        jdbcTemplate.update(updateSql, postId);
    }

    public void unsavePost(Long postId, String email) {
        User user = userService.findByEmail(email);
        if (user == null) {
            throw new RuntimeException("User not found");
        }

        // Remove save
        String sql = "DELETE FROM post_saves WHERE post_id = ? AND user_id = ?";
        int rowsAffected = jdbcTemplate.update(sql, postId, user.getId());

        if (rowsAffected > 0) {
            // Update saves count
            String updateSql = "UPDATE posts SET saves_count = saves_count - 1 WHERE id = ?";
            jdbcTemplate.update(updateSql, postId);
        }
    }

    public List<Comment> getComments(Long postId) {
        String sql = "SELECT * FROM comments WHERE post_id = ? ORDER BY created_at DESC";
        return jdbcTemplate.query(sql, (rs, rowNum) -> {
            Comment comment = new Comment();
            comment.setId(rs.getLong("id"));
            comment.setPostId(rs.getLong("post_id"));
            comment.setUserId(rs.getLong("user_id"));
            comment.setUsername(rs.getString("username"));
            comment.setContent(rs.getString("content"));
            comment.setCreatedAt(rs.getTimestamp("created_at").toLocalDateTime());
            return comment;
        }, postId);
    }

    public Comment addComment(Long postId, String email, String content) {
        User user = userService.findByEmail(email);
        if (user == null) {
            throw new RuntimeException("User not found");
        }

        // Add comment
        String sql = "INSERT INTO comments (post_id, user_id, username, content) VALUES (?, ?, ?, ?)";
        jdbcTemplate.update(sql, postId, user.getId(), user.getUsername(), content);

        // Update comments count
        String updateSql = "UPDATE posts SET comments_count = comments_count + 1 WHERE id = ?";
        jdbcTemplate.update(updateSql, postId);

        // Retrieve created comment
        String selectSql = "SELECT * FROM comments WHERE post_id = ? AND user_id = ? ORDER BY created_at DESC LIMIT 1";
        return jdbcTemplate.queryForObject(selectSql, (rs, rowNum) -> {
            Comment comment = new Comment();
            comment.setId(rs.getLong("id"));
            comment.setPostId(rs.getLong("post_id"));
            comment.setUserId(rs.getLong("user_id"));
            comment.setUsername(rs.getString("username"));
            comment.setContent(rs.getString("content"));
            comment.setCreatedAt(rs.getTimestamp("created_at").toLocalDateTime());
            return comment;
        }, postId, user.getId());
    }

    public void deleteComment(Long postId, Long commentId, String email) {
        User user = userService.findByEmail(email);
        if (user == null) {
            throw new RuntimeException("User not found");
        }

        // Verify comment ownership or post ownership
        String ownershipSql = "SELECT COUNT(*) FROM comments c " +
                "LEFT JOIN posts p ON c.post_id = p.id " +
                "WHERE c.id = ? AND (c.user_id = ? OR p.user_id = ?)";
        int count = jdbcTemplate.queryForObject(ownershipSql, Integer.class, commentId, user.getId(), user.getId());
        if (count == 0) {
            throw new RuntimeException("Comment not found or user not authorized");
        }

        String sql = "DELETE FROM comments WHERE id = ?";
        jdbcTemplate.update(sql, commentId);
    }

    public List<Post> searchPosts(String query) {
        logger.info("Searching posts with query: {}", query);
        try {
            String searchQuery = "%" + query.toLowerCase() + "%";
            String sql = "SELECT * FROM posts WHERE LOWER(description) LIKE ? OR LOWER(username) LIKE ? ORDER BY created_at DESC";
            List<Post> posts = jdbcTemplate.query(sql, new PostMapper(), searchQuery, searchQuery);
            logger.info("Found {} posts matching the search query", posts.size());
            return posts;
        } catch (Exception e) {
            logger.error("Error searching posts: {}", e.getMessage(), e);
            throw new RuntimeException("Failed to search posts: " + e.getMessage());
        }
    }
}