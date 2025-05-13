package com.linksphere.backend.services;

import com.linksphere.backend.dto.RegisterRequest;

import com.linksphere.backend.mapper.UserMapper;
import com.linksphere.backend.models.User;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class UserService {
    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;

    public UserService(UserMapper userMapper, PasswordEncoder passwordEncoder) {
        this.userMapper = userMapper;
        this.passwordEncoder = passwordEncoder;
    }

    public void registerUser(RegisterRequest request) {
        User user = new User();
        user.setEmail(request.getEmail());
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        user.setUsername(request.getUsername());
        user.setRole("USER");
        userMapper.insert(user);
    }

    public User findByEmail(String email) {
        return userMapper.findByEmail(email);
    }
}