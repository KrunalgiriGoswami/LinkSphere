
# LinkSphere - Professional Networking Platform

<p align="center">
  <img src="frontend_flutter/assets/images/logo.png" alt="LinkSphere Logo" width="200"/>
</p>

<p align="center">
  <b>Connect. Collaborate. Grow.</b>
</p>

## 📱 Overview

LinkSphere is a comprehensive professional networking platform designed to connect professionals, share career updates, and foster meaningful professional relationships. Built with Flutter for the frontend and Spring Boot for the backend.

---

## 🚀 Live Demo

> Coming Soon...

---

## ✨ Features

### 🔐 Authentication & User Management
- Secure registration and login
- JWT-based authentication
- Password encryption with BCrypt
- Profile management

### 👤 Profile Features
- Customizable professional profiles
- Skills showcase
- Professional headline
- About section
- Education and experience details

### 📝 Content Sharing
- Create, edit, and delete posts
- Media attachments support
- Rich text formatting

### 🔄 Interactions
- Like/unlike posts
- Comment on posts
- Save posts for later

### 🏠 Feed Management
- Personalized home feed
- Infinite scroll with pagination
- Pull-to-refresh functionality

### 🔍 Search Capabilities
- Search for users and posts
- Filter search results

## 🛠️ Technology Stack

### Frontend
- **Framework**: Flutter
- **State Management**: Provider
- **HTTP Client**: HTTP package
- **Local Storage**: SharedPreferences
- **UI Components**: Custom widgets with Material Design

### Backend
- **Framework**: Spring Boot
- **Database**: MySQL
- **Authentication**: JWT + Spring Security
- **API**: RESTful architecture

## 🚀 Getting Started

### Prerequisites
- Java JDK 11 or higher
- MySQL 8.0 or higher
- Maven 3.6 or higher
- Git

### Setup Instructions
1. Clone the repository
   ```bash
   git clone https://github.com/KrunalgiriGoswami/backend_springboot.git
   
   cd backend_springboot

 2. Update application.yml:
    ```bash
    spring:
    datasource:
    url: jdbc:mysql://localhost:3306/your_db_name
    username: root
    password: yourpassword

 3. Run the application:
    ```bash
    ./mvnw spring-boot:run

###  📌Ensure MySQL is running and linksphere database is created.

### Prerequisites
- Flutter SDK
- Dart SDK
- Android Studio / VS Code
- Git

### Setup Instructions

1. Clone the repository
   ```bash
   git clone https://github.com/KrunalgiriGoswami/frontend_flutter.git

   cd frontend_flutter

2. Install dependencies:
   ```bash
   flutter pub get

3. Run the app:
   ```bash
   flutter run

###  📌Ensure you’re using Flutter 3.x or higher. Update your API base URL in services/api.dart.

##  👨‍💻 Contributors
- @krunalgiri

##  🙌 Acknowledgements

- Flutter Devs

- Spring Boot Docs

- LinkedIn inspiration

