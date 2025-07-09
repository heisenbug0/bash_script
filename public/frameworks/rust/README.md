# Rust Deployment Scripts

Comprehensive deployment scripts for Rust applications across various platforms, databases, and caching systems.

## 📁 Directory Structure

```
rust/
├── standalone/          # Rust apps without external dependencies
├── with-postgresql/     # Rust + PostgreSQL combinations
├── with-mysql/         # Rust + MySQL combinations
├── with-mongodb/       # Rust + MongoDB combinations
├── with-redis/         # Rust + Redis combinations
├── web/                # Web application deployments (Actix, Warp, Rocket)
├── api/                # REST API deployments
├── microservices/      # Rust microservices deployments
├── cli/                # Command-line tool deployments
└── containers/         # Docker and Kubernetes deployments
```

## 🎯 Deployment Scenarios

### Standalone Applications
Perfect for:
- CLI tools and utilities
- System services
- High-performance servers
- Network services
- Data processing tools

### Web Frameworks
- **Actix Web**: High-performance web framework
- **Warp**: Lightweight web framework
- **Rocket**: Type-safe web framework
- **Axum**: Ergonomic web framework

### Database Integrations
- **PostgreSQL**: Production-ready relational database
- **MySQL**: Traditional relational database
- **MongoDB**: Document-based NoSQL database
- **SQLite**: Lightweight embedded database

### Caching Solutions
- **Redis**: In-memory data structure store
- **Memcached**: Distributed memory caching
- **In-memory**: Built-in Rust caching

## 🚀 Quick Start Examples

### Deploy Actix Web API to VPS
```bash
cd web/actix/vps/ubuntu/
export APP_NAME="my-rust-api"
export RUST_VERSION="1.75"
export DOMAIN="api.example.com"
sudo ./deploy.sh
```

### Deploy Rust + PostgreSQL to AWS
```bash
cd with-postgresql/aws-ec2/
export APP_NAME="my-rust-app"
export DB_NAME="myapp"
sudo ./deploy.sh
```

### Deploy Rust Microservices to Kubernetes
```bash
cd microservices/kubernetes/
export SERVICE_NAME="user-service"
export NAMESPACE="production"
kubectl apply -f manifests/
```

### Deploy CLI Tool
```bash
cd cli/
export TOOL_NAME="my-cli-tool"
export INSTALL_PATH="/usr/local/bin"
sudo ./install.sh
```

## 📋 Configuration

### Environment Variables
```bash
# Application Configuration
export APP_NAME="my-rust-app"
export RUST_VERSION="1.75"
export PORT="8080"
export RUST_ENV="production"

# Database Configuration
export DATABASE_URL="postgresql://user:pass@localhost/db"
export DB_HOST="localhost"
export DB_PORT="5432"
export DB_NAME="myapp"
export DB_USER="appuser"
export DB_PASSWORD="securepassword"

# Redis Configuration (if applicable)
export REDIS_URL="redis://localhost:6379"
export REDIS_HOST="localhost"
export REDIS_PORT="6379"
export REDIS_PASSWORD=""

# Security Configuration
export JWT_SECRET="your-jwt-secret"
export API_KEY="your-api-key"
export CORS_ORIGINS="https://example.com"

# Performance Configuration
export WORKER_THREADS="4"
export MAX_CONNECTIONS="1000"
export KEEP_ALIVE="75"

# Logging Configuration
export RUST_LOG="info"
export LOG_LEVEL="info"
export LOG_FORMAT="json"
```

## 📝 Application Examples

### Actix Web Server
```rust
// main.rs
use actix_web::{web, App, HttpResponse, HttpServer, Result, middleware::Logger};
use serde::{Deserialize, Serialize};
use std::env;

#[derive(Serialize, Deserialize)]
struct User {
    id: u32,
    name: String,
    email: String,
}

async fn health() -> Result<HttpResponse> {
    Ok(HttpResponse::Ok().json(serde_json::json!({
        "status": "healthy",
        "timestamp": chrono::Utc::now().to_rfc3339()
    })))
}

async fn get_users() -> Result<HttpResponse> {
    let users = vec![
        User {
            id: 1,
            name: "John Doe".to_string(),
            email: "john@example.com".to_string(),
        },
    ];
    Ok(HttpResponse::Ok().json(users))
}

async fn create_user(user: web::Json<User>) -> Result<HttpResponse> {
    println!("Creating user: {:?}", user);
    Ok(HttpResponse::Created().json(&*user))
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init();
    
    let port = env::var("PORT").unwrap_or_else(|_| "8080".to_string());
    let bind_address = format!("0.0.0.0:{}", port);
    
    println!("Starting server on {}", bind_address);
    
    HttpServer::new(|| {
        App::new()
            .wrap(Logger::default())
            .route("/health", web::get().to(health))
            .service(
                web::scope("/api/v1")
                    .route("/users", web::get().to(get_users))
                    .route("/users", web::post().to(create_user))
            )
    })
    .bind(&bind_address)?
    .run()
    .await
}
```

### Warp Web Server
```rust
// main.rs
use warp::Filter;
use serde::{Deserialize, Serialize};
use std::env;

#[derive(Serialize, Deserialize, Clone)]
struct User {
    id: u32,
    name: String,
    email: String,
}

#[tokio::main]
async fn main() {
    env_logger::init();
    
    let health = warp::path("health")
        .and(warp::get())
        .map(|| {
            warp::reply::json(&serde_json::json!({
                "status": "healthy",
                "timestamp": chrono::Utc::now().to_rfc3339()
            }))
        });
    
    let users = warp::path("api")
        .and(warp::path("v1"))
        .and(warp::path("users"))
        .and(warp::get())
        .map(|| {
            let users = vec![
                User {
                    id: 1,
                    name: "John Doe".to_string(),
                    email: "john@example.com".to_string(),
                },
            ];
            warp::reply::json(&users)
        });
    
    let create_user = warp::path("api")
        .and(warp::path("v1"))
        .and(warp::path("users"))
        .and(warp::post())
        .and(warp::body::json())
        .map(|user: User| {
            println!("Creating user: {:?}", user);
            warp::reply::json(&user)
        });
    
    let routes = health
        .or(users)
        .or(create_user)
        .with(warp::cors().allow_any_origin());
    
    let port: u16 = env::var("PORT")
        .unwrap_or_else(|_| "8080".to_string())
        .parse()
        .expect("PORT must be a number");
    
    println!("Starting server on port {}", port);
    
    warp::serve(routes)
        .run(([0, 0, 0, 0], port))
        .await;
}
```

### Database Integration (PostgreSQL with SQLx)
```rust
// database.rs
use sqlx::{PgPool, Row};
use serde::{Deserialize, Serialize};
use std::env;

#[derive(Serialize, Deserialize, sqlx::FromRow)]
pub struct User {
    pub id: i32,
    pub name: String,
    pub email: String,
    pub created_at: chrono::DateTime<chrono::Utc>,
}

#[derive(Deserialize)]
pub struct CreateUser {
    pub name: String,
    pub email: String,
}

pub struct Database {
    pool: PgPool,
}

impl Database {
    pub async fn new() -> Result<Self, sqlx::Error> {
        let database_url = env::var("DATABASE_URL")
            .expect("DATABASE_URL must be set");
        
        let pool = PgPool::connect(&database_url).await?;
        
        // Run migrations
        sqlx::migrate!("./migrations").run(&pool).await?;
        
        Ok(Database { pool })
    }
    
    pub async fn create_user(&self, user: CreateUser) -> Result<User, sqlx::Error> {
        let user = sqlx::query_as!(
            User,
            r#"
            INSERT INTO users (name, email)
            VALUES ($1, $2)
            RETURNING id, name, email, created_at
            "#,
            user.name,
            user.email
        )
        .fetch_one(&self.pool)
        .await?;
        
        Ok(user)
    }
    
    pub async fn get_user(&self, id: i32) -> Result<Option<User>, sqlx::Error> {
        let user = sqlx::query_as!(
            User,
            "SELECT id, name, email, created_at FROM users WHERE id = $1",
            id
        )
        .fetch_optional(&self.pool)
        .await?;
        
        Ok(user)
    }
    
    pub async fn get_users(&self) -> Result<Vec<User>, sqlx::Error> {
        let users = sqlx::query_as!(
            User,
            "SELECT id, name, email, created_at FROM users ORDER BY created_at DESC"
        )
        .fetch_all(&self.pool)
        .await?;
        
        Ok(users)
    }
    
    pub async fn update_user(&self, id: i32, user: CreateUser) -> Result<Option<User>, sqlx::Error> {
        let user = sqlx::query_as!(
            User,
            r#"
            UPDATE users 
            SET name = $2, email = $3, updated_at = NOW()
            WHERE id = $1
            RETURNING id, name, email, created_at
            "#,
            id,
            user.name,
            user.email
        )
        .fetch_optional(&self.pool)
        .await?;
        
        Ok(user)
    }
    
    pub async fn delete_user(&self, id: i32) -> Result<bool, sqlx::Error> {
        let result = sqlx::query!("DELETE FROM users WHERE id = $1", id)
            .execute(&self.pool)
            .await?;
        
        Ok(result.rows_affected() > 0)
    }
}
```

### Redis Integration
```rust
// redis.rs
use redis::{Client, Connection, RedisResult};
use serde::{Deserialize, Serialize};
use std::env;

pub struct RedisClient {
    client: Client,
}

impl RedisClient {
    pub fn new() -> RedisResult<Self> {
        let redis_url = env::var("REDIS_URL")
            .unwrap_or_else(|_| "redis://localhost:6379".to_string());
        
        let client = Client::open(redis_url)?;
        
        Ok(RedisClient { client })
    }
    
    pub fn get_connection(&self) -> RedisResult<Connection> {
        self.client.get_connection()
    }
    
    pub fn set<T: Serialize>(&self, key: &str, value: &T, ttl: Option<usize>) -> RedisResult<()> {
        let mut conn = self.get_connection()?;
        let serialized = serde_json::to_string(value)
            .map_err(|e| redis::RedisError::from((redis::ErrorKind::TypeError, "Serialization error", e.to_string())))?;
        
        if let Some(ttl) = ttl {
            redis::cmd("SETEX")
                .arg(key)
                .arg(ttl)
                .arg(serialized)
                .execute(&mut conn)
        } else {
            redis::cmd("SET")
                .arg(key)
                .arg(serialized)
                .execute(&mut conn)
        }
    }
    
    pub fn get<T: for<'de> Deserialize<'de>>(&self, key: &str) -> RedisResult<Option<T>> {
        let mut conn = self.get_connection()?;
        let value: Option<String> = redis::cmd("GET")
            .arg(key)
            .query(&mut conn)?;
        
        match value {
            Some(v) => {
                let deserialized = serde_json::from_str(&v)
                    .map_err(|e| redis::RedisError::from((redis::ErrorKind::TypeError, "Deserialization error", e.to_string())))?;
                Ok(Some(deserialized))
            }
            None => Ok(None),
        }
    }
    
    pub fn delete(&self, key: &str) -> RedisResult<bool> {
        let mut conn = self.get_connection()?;
        let result: i32 = redis::cmd("DEL")
            .arg(key)
            .query(&mut conn)?;
        Ok(result > 0)
    }
}
```

## 📝 Build Scripts

### Standard Build Script
```bash
#!/bin/bash
# build.sh

set -e

echo "🚀 Building Rust application..."

# Check Rust installation
if ! command -v rustc &> /dev/null; then
    echo "❌ Rust is not installed"
    exit 1
fi

# Update Rust if needed
echo "🔄 Updating Rust..."
rustup update

# Set release profile
export CARGO_PROFILE_RELEASE_LTO=true
export CARGO_PROFILE_RELEASE_CODEGEN_UNITS=1
export CARGO_PROFILE_RELEASE_PANIC=abort

# Clean previous builds
echo "🧹 Cleaning previous builds..."
cargo clean

# Run tests
echo "🧪 Running tests..."
cargo test --release

# Build optimized binary
echo "🔨 Building optimized binary..."
cargo build --release

# Strip binary to reduce size
if command -v strip &> /dev/null; then
    echo "✂️ Stripping binary..."
    strip target/release/$(cargo metadata --no-deps --format-version 1 | jq -r '.packages[0].name')
fi

echo "✅ Build completed successfully!"
echo "📦 Binary location: target/release/$(cargo metadata --no-deps --format-version 1 | jq -r '.packages[0].name')"
```

### Cross-compilation Build Script
```bash
#!/bin/bash
# build-cross.sh

set -e

APP_NAME=$(cargo metadata --no-deps --format-version 1 | jq -r '.packages[0].name')
VERSION=$(cargo metadata --no-deps --format-version 1 | jq -r '.packages[0].version')
BUILD_DIR="target/release"

echo "🚀 Cross-compiling $APP_NAME v$VERSION..."

# Install cross if not available
if ! command -v cross &> /dev/null; then
    echo "📦 Installing cross..."
    cargo install cross
fi

# Target platforms
TARGETS=(
    "x86_64-unknown-linux-gnu"
    "x86_64-unknown-linux-musl"
    "aarch64-unknown-linux-gnu"
    "x86_64-apple-darwin"
    "aarch64-apple-darwin"
    "x86_64-pc-windows-gnu"
)

# Create release directory
mkdir -p releases

for target in "${TARGETS[@]}"; do
    echo "🔨 Building for $target..."
    
    cross build --release --target $target
    
    # Copy binary to releases directory
    if [[ $target == *"windows"* ]]; then
        cp "target/$target/release/${APP_NAME}.exe" "releases/${APP_NAME}-${VERSION}-${target}.exe"
    else
        cp "target/$target/release/$APP_NAME" "releases/${APP_NAME}-${VERSION}-${target}"
    fi
done

echo "✅ Cross-compilation completed!"
ls -la releases/
```

## 📦 Dockerfile Examples

### Multi-stage Rust Dockerfile
```dockerfile
# Build stage
FROM rust:1.75-slim as builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy manifests
COPY Cargo.toml Cargo.lock ./

# Create dummy main.rs to build dependencies
RUN mkdir src && echo "fn main() {}" > src/main.rs

# Build dependencies (this will be cached)
RUN cargo build --release && rm -rf src

# Copy source code
COPY src ./src

# Build application
RUN touch src/main.rs && cargo build --release

# Runtime stage
FROM debian:bookworm-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd -m -u 1001 appuser

WORKDIR /app

# Copy binary from builder stage
COPY --from=builder /app/target/release/my-rust-app ./app

# Change ownership
RUN chown appuser:appuser ./app

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

CMD ["./app"]
```

### Alpine-based Dockerfile
```dockerfile
# Build stage
FROM rust:1.75-alpine as builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache \
    musl-dev \
    openssl-dev \
    openssl-libs-static \
    pkgconfig

# Set environment for static linking
ENV RUSTFLAGS="-C target-feature=+crt-static"

# Copy manifests
COPY Cargo.toml Cargo.lock ./

# Create dummy main.rs to build dependencies
RUN mkdir src && echo "fn main() {}" > src/main.rs

# Build dependencies
RUN cargo build --release && rm -rf src

# Copy source code
COPY src ./src

# Build application
RUN touch src/main.rs && cargo build --release

# Runtime stage
FROM alpine:latest

# Install runtime dependencies
RUN apk --no-cache add ca-certificates

# Create non-root user
RUN adduser -D -s /bin/sh appuser

WORKDIR /app

# Copy binary from builder stage
COPY --from=builder /app/target/release/my-rust-app ./app

# Change ownership
RUN chown appuser:appuser ./app

USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

CMD ["./app"]
```

## 📝 Cargo.toml Configuration

### Web Application Dependencies
```toml
[package]
name = "my-rust-app"
version = "0.1.0"
edition = "2021"

[dependencies]
# Web framework
actix-web = "4.4"
# Or use warp
# warp = "0.3"
# Or use rocket
# rocket = { version = "0.5", features = ["json"] }

# Async runtime
tokio = { version = "1.0", features = ["full"] }

# Serialization
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"

# Database
sqlx = { version = "0.7", features = ["runtime-tokio-rustls", "postgres", "chrono", "uuid", "migrate"] }

# Redis
redis = { version = "0.24", features = ["tokio-comp"] }

# HTTP client
reqwest = { version = "0.11", features = ["json"] }

# Logging
log = "0.4"
env_logger = "0.10"

# Date/time
chrono = { version = "0.4", features = ["serde"] }

# UUID
uuid = { version = "1.0", features = ["v4", "serde"] }

# Configuration
config = "0.13"

# JWT
jsonwebtoken = "9.0"

# Password hashing
bcrypt = "0.15"

# Environment variables
dotenv = "0.15"

[profile.release]
lto = true
codegen-units = 1
panic = "abort"
strip = true
```

### CLI Application Dependencies
```toml
[package]
name = "my-cli-tool"
version = "0.1.0"
edition = "2021"

[dependencies]
# CLI framework
clap = { version = "4.0", features = ["derive"] }

# Terminal UI
crossterm = "0.27"
ratatui = "0.24"

# Progress bars
indicatif = "0.17"

# Colors
colored = "2.0"

# File operations
walkdir = "2.0"
glob = "0.3"

# Serialization
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
toml = "0.8"
serde_yaml = "0.9"

# HTTP client
reqwest = { version = "0.11", features = ["json", "blocking"] }

# Async runtime (if needed)
tokio = { version = "1.0", features = ["full"] }

# Error handling
anyhow = "1.0"
thiserror = "1.0"

# Logging
log = "0.4"
env_logger = "0.10"

[profile.release]
lto = true
codegen-units = 1
panic = "abort"
strip = true
```

## 📝 Features

### Performance
- ✅ Zero-cost abstractions
- ✅ Memory safety without garbage collection
- ✅ Fearless concurrency
- ✅ Minimal runtime overhead
- ✅ Excellent optimization

### Security
- ✅ Memory safety
- ✅ Thread safety
- ✅ Type safety
- ✅ No null pointer dereferences
- ✅ No buffer overflows

### Development
- ✅ Excellent tooling (Cargo)
- ✅ Package management
- ✅ Built-in testing
- ✅ Documentation generation
- ✅ Cross-compilation

### Ecosystem
- ✅ Rich crate ecosystem
- ✅ Active community
- ✅ Excellent documentation
- ✅ WebAssembly support
- ✅ Embedded systems support

## 🛠️ Prerequisites

### System Requirements
- Rust 1.70+ (1.75+ recommended)
- Cargo package manager
- Git for dependency management
- C compiler (for some dependencies)
- OpenSSL development libraries

### Installation
```bash
# Install Rust via rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Add to PATH
source ~/.cargo/env

# Update Rust
rustup update

# Install additional components
rustup component add clippy rustfmt

# Install useful tools
cargo install cargo-watch cargo-edit cargo-audit
```

## 📚 Usage Examples

### Example 1: High-Performance API
```bash
# Deploy Actix Web API to VPS
cd web/actix/vps/ubuntu/
export APP_NAME="high-perf-api"
export PORT="8080"
export DOMAIN="api.mysite.com"
sudo ./deploy.sh
```

### Example 2: Microservice with Database
```bash
# Deploy Rust microservice with PostgreSQL
cd microservices/with-postgresql/
export SERVICE_NAME="user-service"
export DB_NAME="users"
sudo ./deploy.sh
```

### Example 3: CLI Tool Distribution
```bash
# Build and distribute CLI tool
cd cli/
export TOOL_NAME="my-tool"
export VERSION="1.0.0"
./build-cross.sh
./package.sh
```

## 🔍 Troubleshooting

### Common Issues

**Compilation Errors**
```bash
# Check Rust version
rustc --version

# Update Rust
rustup update

# Clean and rebuild
cargo clean
cargo build
```

**Dependency Issues**
```bash
# Update dependencies
cargo update

# Check for security vulnerabilities
cargo audit

# Fix formatting
cargo fmt

# Run linter
cargo clippy
```

**Runtime Issues**
```bash
# Enable debug logging
export RUST_LOG=debug

# Check for memory leaks (with valgrind)
valgrind --tool=memcheck ./target/release/my-app

# Profile performance
cargo install flamegraph
cargo flamegraph --bin my-app
```

### Performance Optimization

**Build Optimization**
```bash
# Profile-guided optimization
export RUSTFLAGS="-C profile-generate=/tmp/pgo-data"
cargo build --release
# Run application with representative workload
export RUSTFLAGS="-C profile-use=/tmp/pgo-data"
cargo build --release
```

**Runtime Optimization**
```bash
# Check binary size
ls -la target/release/my-app

# Analyze dependencies
cargo bloat --release

# Optimize for size
export RUSTFLAGS="-C opt-level=z"
cargo build --release
```

## 🔗 Related Documentation

- [Database Scripts](../../databases/README.md)
- [Container Scripts](../../containers/README.md)
- [Cloud Services](../../cloud-services/README.md)
- [Monitoring Scripts](../../tools/monitoring/README.md)