package com.linksphere.backend.services;

import com.linksphere.backend.dto.ProfileRequest;
import com.linksphere.backend.mapper.ProfileMapper;
import com.linksphere.backend.models.Profile;
import org.springframework.stereotype.Service;

@Service
public class ProfileService {
    private final ProfileMapper profileMapper;

    public ProfileService(ProfileMapper profileMapper) {
        this.profileMapper = profileMapper;
    }

    public void createProfile(Long userId, ProfileRequest request) {
        Profile profile = new Profile();
        profile.setUserId(userId);
        profile.setHeadline(request.getHeadline());
        profile.setAbout(request.getAbout());
        profile.setSkills(request.getSkills());
        profile.setEducation(request.getEducation());
        profile.setExperience(request.getExperience());
        profile.setLocation(request.getLocation());
        profile.setContactInfo(request.getContactInfo());
        profileMapper.insert(profile);
    }

    public void updateProfile(Long userId, ProfileRequest request) {
        Profile profile = new Profile();
        profile.setUserId(userId);
        profile.setHeadline(request.getHeadline());
        profile.setAbout(request.getAbout());
        profile.setSkills(request.getSkills());
        profile.setEducation(request.getEducation());
        profile.setExperience(request.getExperience());
        profile.setLocation(request.getLocation());
        profile.setContactInfo(request.getContactInfo());
        profileMapper.update(profile);
    }

    public Profile getProfile(Long userId) {
        return profileMapper.findByUserId(userId);
    }
}