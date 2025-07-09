# Spring Boot Deployment Scripts

Comprehensive deployment scripts for Spring Boot applications across various platforms, databases, and caching systems.

## 📁 Directory Structure

```
spring/
├── standalone/          # Spring Boot apps without external dependencies
├── with-postgresql/     # Spring Boot + PostgreSQL combinations
├── with-mysql/         # Spring Boot + MySQL combinations
├── with-mongodb/       # Spring Boot + MongoDB combinations
├── with-redis/         # Spring Boot + Redis combinations
├── full-stack/         # Complete stacks (DB + Cache + Monitoring)
├── api-only/           # Spring Boot REST API deployments
├── microservices/      # Spring Boot microservices
└── containers/         # Docker and Kubernetes deployments
```

## 🎯 Deployment Scenarios

### Standalone Applications
Perfect for:
- REST APIs
- Web applications
- Microservices
- Batch processing applications
- Enterprise applications

### Database Integrations
- **PostgreSQL**: Production-ready relational database
- **MySQL**: Traditional relational database
- **MongoDB**: Document-based NoSQL database
- **H2**: In-memory database for development

### Caching Solutions
- **Redis**: In-memory data structure store
- **Hazelcast**: In-memory data grid
- **Caffeine**: High-performance caching library
- **EhCache**: Java caching solution

### Enterprise Features
- **Spring Security**: Authentication and authorization
- **Spring Cloud**: Microservices patterns
- **Spring Data**: Data access abstraction
- **Spring Actuator**: Production monitoring

## 🚀 Quick Start Examples

### Deploy Spring Boot App to VPS
```bash
cd standalone/vps/ubuntu/
export APP_NAME="my-spring-app"
export JAVA_VERSION="17"
export DOMAIN="api.example.com"
sudo ./deploy.sh
```

### Deploy Spring Boot + PostgreSQL to AWS
```bash
cd with-postgresql/aws-ec2/
export APP_NAME="my-webapp"
export DB_NAME="myapp"
sudo ./deploy.sh
```

### Deploy Spring Boot to Kubernetes
```bash
cd microservices/kubernetes/
export SERVICE_NAME="user-service"
export NAMESPACE="production"
kubectl apply -f manifests/
```

## 📋 Configuration

### Environment Variables
```bash
# Application Configuration
export APP_NAME="my-spring-app"
export JAVA_VERSION="17"
export SPRING_BOOT_VERSION="3.2"
export SPRING_PROFILES_ACTIVE="production"
export SERVER_PORT="8080"

# Database Configuration
export SPRING_DATASOURCE_URL="jdbc:postgresql://localhost:5432/myapp"
export SPRING_DATASOURCE_USERNAME="appuser"
export SPRING_DATASOURCE_PASSWORD="securepassword"
export SPRING_DATASOURCE_DRIVER_CLASS_NAME="org.postgresql.Driver"

# Redis Configuration (if applicable)
export SPRING_REDIS_HOST="localhost"
export SPRING_REDIS_PORT="6379"
export SPRING_REDIS_PASSWORD=""
export SPRING_REDIS_DATABASE="0"

# Security Configuration
export JWT_SECRET="your-jwt-secret"
export CORS_ALLOWED_ORIGINS="https://example.com"

# Performance Configuration
export SPRING_JPA_HIBERNATE_DDL_AUTO="validate"
export SPRING_JPA_SHOW_SQL="false"
export SPRING_JPA_PROPERTIES_HIBERNATE_FORMAT_SQL="false"

# Logging Configuration
export LOGGING_LEVEL_ROOT="INFO"
export LOGGING_LEVEL_COM_MYCOMPANY="DEBUG"
```

## 📝 Application Examples

### Simple Spring Boot Application
```java
// Application.java
package com.example.myapp;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.Map;

@SpringBootApplication
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}

@RestController
class HealthController {
    
    @GetMapping("/")
    public Map<String, Object> root() {
        return Map.of(
            "message", "Hello, World!",
            "status", "success",
            "timestamp", LocalDateTime.now()
        );
    }
    
    @GetMapping("/health")
    public Map<String, Object> health() {
        return Map.of(
            "status", "healthy",
            "timestamp", LocalDateTime.now()
        );
    }
}
```

### Spring Boot with Database Integration
```java
// User.java
package com.example.myapp.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @NotBlank
    @Column(nullable = false)
    private String name;
    
    @Email
    @NotBlank
    @Column(nullable = false, unique = true)
    private String email;
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
    
    // Constructors, getters, and setters
    public User() {}
    
    public User(String name, String email) {
        this.name = name;
        this.email = email;
    }
    
    // Getters and setters...
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}

// UserRepository.java
package com.example.myapp.repository;

import com.example.myapp.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByEmail(String email);
    
    @Query("SELECT u FROM User u WHERE u.name LIKE %?1%")
    List<User> findByNameContaining(String name);
    
    List<User> findByOrderByCreatedAtDesc();
}

// UserController.java
package com.example.myapp.controller;

import com.example.myapp.entity.User;
import com.example.myapp.repository.UserRepository;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "${cors.allowed.origins:http://localhost:3000}")
public class UserController {
    
    @Autowired
    private UserRepository userRepository;
    
    @GetMapping
    public List<User> getAllUsers() {
        return userRepository.findByOrderByCreatedAtDesc();
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<User> getUserById(@PathVariable Long id) {
        Optional<User> user = userRepository.findById(id);
        return user.map(ResponseEntity::ok)
                  .orElse(ResponseEntity.notFound().build());
    }
    
    @PostMapping
    public ResponseEntity<User> createUser(@Valid @RequestBody User user) {
        try {
            User savedUser = userRepository.save(user);
            return ResponseEntity.status(HttpStatus.CREATED).body(savedUser);
        } catch (Exception e) {
            return ResponseEntity.badRequest().build();
        }
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<User> updateUser(@PathVariable Long id, @Valid @RequestBody User userDetails) {
        Optional<User> optionalUser = userRepository.findById(id);
        
        if (optionalUser.isPresent()) {
            User user = optionalUser.get();
            user.setName(userDetails.getName());
            user.setEmail(userDetails.getEmail());
            return ResponseEntity.ok(userRepository.save(user));
        } else {
            return ResponseEntity.notFound().build();
        }
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        if (userRepository.existsById(id)) {
            userRepository.deleteById(id);
            return ResponseEntity.noContent().build();
        } else {
            return ResponseEntity.notFound().build();
        }
    }
}
```

## 📝 Build Scripts

### Maven Build Script
```bash
#!/usr/bin/env bash
# build.sh for Spring Boot deployment
set -o errexit

echo "🚀 Starting Spring Boot deployment build..."

# Check Java version
java -version

# Clean and compile
echo "🔨 Building application..."
./mvnw clean compile

# Run tests
echo "🧪 Running tests..."
./mvnw test

# Package application
echo "📦 Packaging application..."
./mvnw package -DskipTests

# Verify JAR file
JAR_FILE=$(find target -name "*.jar" -not -name "*-sources.jar" | head -1)
if [ -f "$JAR_FILE" ]; then
    echo "✅ Build completed successfully!"
    echo "📦 JAR file: $JAR_FILE"
else
    echo "❌ Build failed - JAR file not found"
    exit 1
fi
```

### Gradle Build Script
```bash
#!/usr/bin/env bash
# build-gradle.sh for Spring Boot deployment
set -o errexit

echo "🚀 Starting Spring Boot Gradle build..."

# Check Java version
java -version

# Clean and build
echo "🔨 Building application..."
./gradlew clean build

# Verify JAR file
JAR_FILE=$(find build/libs -name "*.jar" | head -1)
if [ -f "$JAR_FILE" ]; then
    echo "✅ Build completed successfully!"
    echo "📦 JAR file: $JAR_FILE"
else
    echo "❌ Build failed - JAR file not found"
    exit 1
fi
```

## 📝 Configuration Files

### application.yml
```yaml
server:
  port: ${SERVER_PORT:8080}

spring:
  profiles:
    active: ${SPRING_PROFILES_ACTIVE:production}
  
  datasource:
    url: ${SPRING_DATASOURCE_URL:jdbc:postgresql://localhost:5432/myapp}
    username: ${SPRING_DATASOURCE_USERNAME:appuser}
    password: ${SPRING_DATASOURCE_PASSWORD:password}
    driver-class-name: ${SPRING_DATASOURCE_DRIVER_CLASS_NAME:org.postgresql.Driver}
    hikari:
      maximum-pool-size: 20
      minimum-idle: 5
      connection-timeout: 30000
      idle-timeout: 600000
      max-lifetime: 1800000
  
  jpa:
    hibernate:
      ddl-auto: ${SPRING_JPA_HIBERNATE_DDL_AUTO:validate}
    show-sql: ${SPRING_JPA_SHOW_SQL:false}
    properties:
      hibernate:
        format_sql: ${SPRING_JPA_PROPERTIES_HIBERNATE_FORMAT_SQL:false}
        dialect: org.hibernate.dialect.PostgreSQLDialect
  
  redis:
    host: ${SPRING_REDIS_HOST:localhost}
    port: ${SPRING_REDIS_PORT:6379}
    password: ${SPRING_REDIS_PASSWORD:}
    database: ${SPRING_REDIS_DATABASE:0}
    timeout: 2000ms
    lettuce:
      pool:
        max-active: 8
        max-idle: 8
        min-idle: 0

management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  endpoint:
    health:
      show-details: always

logging:
  level:
    root: ${LOGGING_LEVEL_ROOT:INFO}
    com.example.myapp: ${LOGGING_LEVEL_COM_MYCOMPANY:INFO}
  pattern:
    console: "%d{yyyy-MM-dd HH:mm:ss} - %msg%n"
    file: "%d{yyyy-MM-dd HH:mm:ss} [%thread] %-5level %logger{36} - %msg%n"

cors:
  allowed:
    origins: ${CORS_ALLOWED_ORIGINS:http://localhost:3000}

jwt:
  secret: ${JWT_SECRET:default-secret-key}
  expiration: 86400000
```

### pom.xml (Maven)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.0</version>
        <relativePath/>
    </parent>
    
    <groupId>com.example</groupId>
    <artifactId>my-spring-app</artifactId>
    <version>1.0.0</version>
    <name>My Spring App</name>
    <description>Spring Boot application</description>
    
    <properties>
        <java.version>17</java.version>
    </properties>
    
    <dependencies>
        <!-- Spring Boot Starters -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-jpa</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-data-redis</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-security</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-actuator</artifactId>
        </dependency>
        
        <!-- Database Drivers -->
        <dependency>
            <groupId>org.postgresql</groupId>
            <artifactId>postgresql</artifactId>
            <scope>runtime</scope>
        </dependency>
        
        <!-- Testing -->
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        
        <dependency>
            <groupId>org.springframework.security</groupId>
            <artifactId>spring-security-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
        </plugins>
    </build>
</project>
```

## 📦 Docker Configuration

### Dockerfile
```dockerfile
FROM openjdk:17-jdk-slim

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd --create-home --shell /bin/bash app

WORKDIR /app

# Copy JAR file
COPY target/*.jar app.jar

# Change ownership
RUN chown app:app app.jar

USER app

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
```

### Multi-stage Dockerfile
```dockerfile
# Build stage
FROM openjdk:17-jdk-slim as builder

WORKDIR /app

# Copy Maven wrapper and pom.xml
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# Download dependencies
RUN ./mvnw dependency:go-offline

# Copy source code and build
COPY src src
RUN ./mvnw clean package -DskipTests

# Runtime stage
FROM openjdk:17-jre-slim

# Install curl for health checks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd --create-home --shell /bin/bash app

WORKDIR /app

# Copy JAR from builder stage
COPY --from=builder /app/target/*.jar app.jar

# Change ownership
RUN chown app:app app.jar

USER app

EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
```

## 📝 Features

### Enterprise Features
- ✅ Spring Security integration
- ✅ Spring Data JPA
- ✅ Spring Boot Actuator
- ✅ Spring Cloud support
- ✅ Microservices patterns

### Performance
- ✅ Connection pooling
- ✅ Caching support
- ✅ JVM optimization
- ✅ Async processing
- ✅ Database optimization

### Monitoring
- ✅ Actuator endpoints
- ✅ Metrics collection
- ✅ Health checks
- ✅ Distributed tracing
- ✅ Log aggregation

### Security
- ✅ Authentication & authorization
- ✅ JWT token support
- ✅ CORS configuration
- ✅ Input validation
- ✅ Security headers

## 🛠️ Prerequisites

### System Requirements
- Java 17+ (21+ recommended)
- Maven 3.6+ or Gradle 7+
- Database system (PostgreSQL, MySQL, etc.)
- Redis server (if caching enabled)

## 📚 Usage Examples

### Example 1: Enterprise API
```bash
# Deploy Spring Boot API to Ubuntu VPS
cd api-only/vps/ubuntu/
export APP_NAME="enterprise-api"
export JAVA_VERSION="17"
export DOMAIN="api.mysite.com"
sudo ./deploy.sh
```

### Example 2: Microservice with Database
```bash
# Deploy Spring Boot microservice with PostgreSQL
cd microservices/with-postgresql/
export SERVICE_NAME="user-service"
export DB_NAME="users"
sudo ./deploy.sh
```

### Example 3: Full-Stack Application
```bash
# Deploy Spring Boot app to Kubernetes
cd full-stack/kubernetes/
export APP_NAME="my-app"
export NAMESPACE="production"
kubectl apply -f manifests/
```

## 🔍 Troubleshooting

### Common Issues

**Build Issues**
```bash
# Clean Maven cache
./mvnw clean

# Update dependencies
./mvnw dependency:resolve

# Check Java version
java -version
```

**Database Connection Issues**
```bash
# Test database connection
java -jar app.jar --spring.datasource.url=jdbc:postgresql://localhost:5432/test

# Check environment variables
env | grep SPRING_
```

**Performance Issues**
```bash
# Monitor JVM
jstat -gc -t $(pgrep java) 5s

# Check memory usage
jmap -histo $(pgrep java)

# Profile application
java -XX:+FlightRecorder -XX:StartFlightRecording=duration=60s,filename=profile.jfr -jar app.jar
```

## 🔗 Related Documentation

- [Database Scripts](../../../databases/README.md)
- [Caching Scripts](../../../caching/README.md)
- [Cloud Services](../../../cloud-services/README.md)
- [Hosting Platforms](../../../hosting/README.md)