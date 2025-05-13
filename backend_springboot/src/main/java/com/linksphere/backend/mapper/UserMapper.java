package com.linksphere.backend.mapper;

import com.linksphere.backend.models.User;
import org.apache.ibatis.annotations.*;

@Mapper
public interface UserMapper {
    @Insert("INSERT INTO users (email, password, username, role) VALUES (#{email}, #{password}, #{username}, #{role})")
    @Options(useGeneratedKeys = true, keyProperty = "id")
    void insert(User user);

    @Select("SELECT * FROM users WHERE email = #{email}")
    User findByEmail(String email);
}