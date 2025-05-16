package com.linksphere.backend.mapper;

import com.linksphere.backend.models.Profile;
import org.apache.ibatis.annotations.*;

@Mapper
public interface ProfileMapper {
    @Insert("INSERT INTO profiles (user_id, headline, about, skills, education, experience, location, contact_info) " +
            "VALUES (#{userId}, #{headline}, #{about}, #{skills}, #{education}, #{experience}, #{location}, #{contactInfo})")
    @Options(useGeneratedKeys = true, keyProperty = "id")
    void insert(Profile profile);

    @Update("UPDATE profiles SET headline = #{headline}, about = #{about}, skills = #{skills}, " +
            "education = #{education}, experience = #{experience}, location = #{location}, contact_info = #{contactInfo}, " +
            "updated_at = CURRENT_TIMESTAMP WHERE user_id = #{userId}")
    void update(Profile profile);

    @Select("SELECT * FROM profiles WHERE user_id = #{userId}")
    Profile findByUserId(Long userId);
}