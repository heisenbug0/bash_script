# Go Deployment Scripts

Comprehensive deployment scripts for Go applications across various platforms, databases, and caching systems.

## 📁 Directory Structure

```
go/
├── standalone/          # Go apps without external dependencies
├── with-postgresql/     # Go + PostgreSQL combinations
├── with-mysql/         # Go + MySQL combinations
├── with-mongodb/       # Go + MongoDB combinations
├── with-redis/         # Go + Redis combinations
├── microservices/      # Go microservices deployments
├── grpc/               # gRPC service deployments
├── api/                # REST API deployments
├── web/                # Web application deployments
└── containers/         # Docker and Kubernetes deployments
```

## 🎯 Deployment Scenarios

### Standalone Applications
Perfect for:
- CLI tools and utilities
- Simple web servers
- API gateways
- Proxy servers
- Development tools

### Database Integrations
- **PostgreSQL**: Production-ready relational database
- **MySQL**: Traditional relational database
- **MongoDB**: Document-based NoSQL database
- **SQLite**: Lightweight embedded database

### Caching Solutions
- **Redis**: In-memory data structure store
- **Memcached**: Distributed memory caching
- **In-memory**: Built-in Go caching

### Service Architectures
- **REST APIs**: HTTP-based services
- **gRPC Services**: High-performance RPC
- **Microservices**: Distributed service architecture
- **Web Applications**: Full-stack Go applications

## 🚀 Quick Start Examples

### Deploy Go API to VPS
```bash
cd api/vps/ubuntu/
export APP_NAME="my-go-api"
export GO_VERSION="1.21"
export DOMAIN="api.example.com"
sudo ./deploy.sh
```

### Deploy Go + PostgreSQL to AWS
```bash
cd with-postgresql/aws-ec2/
export APP_NAME="my-go-app"
export DB_NAME="myapp"
sudo ./deploy.sh
```

### Deploy Go Microservices to Kubernetes
```bash
cd microservices/kubernetes/
export SERVICE_NAME="user-service"
export NAMESPACE="production"
kubectl apply -f manifests/
```

### Deploy gRPC Service to Docker
```bash
cd grpc/docker/
export SERVICE_NAME="my-grpc-service"
export PORT="50051"
docker-compose up -d
```

## 📋 Configuration

### Environment Variables
```bash
# Application Configuration
export APP_NAME="my-go-app"
export GO_VERSION="1.21"
export PORT="8080"
export GIN_MODE="release"

# Database Configuration
export DB_HOST="localhost"
export DB_PORT="5432"
export DB_NAME="myapp"
export DB_USER="appuser"
export DB_PASSWORD="securepassword"
export DB_SSL_MODE="require"

# Redis Configuration (if applicable)
export REDIS_HOST="localhost"
export REDIS_PORT="6379"
export REDIS_PASSWORD=""
export REDIS_DB="0"

# gRPC Configuration
export GRPC_PORT="50051"
export GRPC_REFLECTION="true"

# Security Configuration
export JWT_SECRET="your-jwt-secret"
export API_KEY="your-api-key"
export CORS_ORIGINS="https://example.com"

# Monitoring Configuration
export METRICS_PORT="9090"
export HEALTH_CHECK_PATH="/health"
export LOG_LEVEL="info"
```

## 📝 Application Examples

### Simple HTTP Server
```go
// main.go
package main

import (
    "fmt"
    "log"
    "net/http"
    "os"
)

func main() {
    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Hello, World!")
    })

    http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
        w.WriteHeader(http.StatusOK)
        fmt.Fprintf(w, "OK")
    })

    log.Printf("Server starting on port %s", port)
    log.Fatal(http.ListenAndServe(":"+port, nil))
}
```

### Gin Web Framework
```go
// main.go
package main

import (
    "net/http"
    "os"

    "github.com/gin-gonic/gin"
)

func main() {
    r := gin.Default()

    // Health check endpoint
    r.GET("/health", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{
            "status": "healthy",
        })
    })

    // API routes
    api := r.Group("/api/v1")
    {
        api.GET("/users", getUsers)
        api.POST("/users", createUser)
        api.GET("/users/:id", getUser)
        api.PUT("/users/:id", updateUser)
        api.DELETE("/users/:id", deleteUser)
    }

    port := os.Getenv("PORT")
    if port == "" {
        port = "8080"
    }

    r.Run(":" + port)
}

func getUsers(c *gin.Context) {
    c.JSON(http.StatusOK, gin.H{"users": []string{}})
}

func createUser(c *gin.Context) {
    c.JSON(http.StatusCreated, gin.H{"message": "User created"})
}

func getUser(c *gin.Context) {
    id := c.Param("id")
    c.JSON(http.StatusOK, gin.H{"user": id})
}

func updateUser(c *gin.Context) {
    id := c.Param("id")
    c.JSON(http.StatusOK, gin.H{"message": "User " + id + " updated"})
}

func deleteUser(c *gin.Context) {
    id := c.Param("id")
    c.JSON(http.StatusOK, gin.H{"message": "User " + id + " deleted"})
}
```

### gRPC Service
```go
// server.go
package main

import (
    "context"
    "log"
    "net"
    "os"

    "google.golang.org/grpc"
    "google.golang.org/grpc/reflection"
    pb "your-module/proto"
)

type server struct {
    pb.UnimplementedUserServiceServer
}

func (s *server) GetUser(ctx context.Context, req *pb.GetUserRequest) (*pb.GetUserResponse, error) {
    return &pb.GetUserResponse{
        User: &pb.User{
            Id:    req.Id,
            Name:  "John Doe",
            Email: "john@example.com",
        },
    }, nil
}

func main() {
    port := os.Getenv("GRPC_PORT")
    if port == "" {
        port = "50051"
    }

    lis, err := net.Listen("tcp", ":"+port)
    if err != nil {
        log.Fatalf("Failed to listen: %v", err)
    }

    s := grpc.NewServer()
    pb.RegisterUserServiceServer(s, &server{})

    // Enable reflection for development
    if os.Getenv("GRPC_REFLECTION") == "true" {
        reflection.Register(s)
    }

    log.Printf("gRPC server listening on port %s", port)
    if err := s.Serve(lis); err != nil {
        log.Fatalf("Failed to serve: %v", err)
    }
}
```

### Database Integration (PostgreSQL)
```go
// database.go
package main

import (
    "database/sql"
    "fmt"
    "log"
    "os"

    _ "github.com/lib/pq"
)

type User struct {
    ID    int    `json:"id"`
    Name  string `json:"name"`
    Email string `json:"email"`
}

type Database struct {
    db *sql.DB
}

func NewDatabase() (*Database, error) {
    dbHost := os.Getenv("DB_HOST")
    dbPort := os.Getenv("DB_PORT")
    dbUser := os.Getenv("DB_USER")
    dbPassword := os.Getenv("DB_PASSWORD")
    dbName := os.Getenv("DB_NAME")
    sslMode := os.Getenv("DB_SSL_MODE")

    if sslMode == "" {
        sslMode = "disable"
    }

    connStr := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
        dbHost, dbPort, dbUser, dbPassword, dbName, sslMode)

    db, err := sql.Open("postgres", connStr)
    if err != nil {
        return nil, err
    }

    if err := db.Ping(); err != nil {
        return nil, err
    }

    return &Database{db: db}, nil
}

func (d *Database) CreateUser(user User) (*User, error) {
    query := `INSERT INTO users (name, email) VALUES ($1, $2) RETURNING id`
    err := d.db.QueryRow(query, user.Name, user.Email).Scan(&user.ID)
    if err != nil {
        return nil, err
    }
    return &user, nil
}

func (d *Database) GetUser(id int) (*User, error) {
    user := &User{}
    query := `SELECT id, name, email FROM users WHERE id = $1`
    err := d.db.QueryRow(query, id).Scan(&user.ID, &user.Name, &user.Email)
    if err != nil {
        return nil, err
    }
    return user, nil
}

func (d *Database) GetUsers() ([]User, error) {
    query := `SELECT id, name, email FROM users`
    rows, err := d.db.Query(query)
    if err != nil {
        return nil, err
    }
    defer rows.Close()

    var users []User
    for rows.Next() {
        var user User
        err := rows.Scan(&user.ID, &user.Name, &user.Email)
        if err != nil {
            return nil, err
        }
        users = append(users, user)
    }

    return users, nil
}

func (d *Database) Close() error {
    return d.db.Close()
}
```

## 📝 Build Scripts

### Standard Build Script
```bash
#!/bin/bash
# build.sh

set -e

echo "🚀 Building Go application..."

# Set Go environment
export CGO_ENABLED=0
export GOOS=linux
export GOARCH=amd64

# Get dependencies
echo "📦 Downloading dependencies..."
go mod download
go mod verify

# Run tests
echo "🧪 Running tests..."
go test ./...

# Build binary
echo "🔨 Building binary..."
go build -ldflags="-w -s" -o app .

# Make binary executable
chmod +x app

echo "✅ Build completed successfully!"
```

### Multi-platform Build Script
```bash
#!/bin/bash
# build-multi.sh

set -e

APP_NAME="my-go-app"
VERSION=${VERSION:-"1.0.0"}
BUILD_DIR="build"

echo "🚀 Building $APP_NAME v$VERSION for multiple platforms..."

# Clean build directory
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR

# Build for different platforms
PLATFORMS=(
    "linux/amd64"
    "linux/arm64"
    "darwin/amd64"
    "darwin/arm64"
    "windows/amd64"
)

for platform in "${PLATFORMS[@]}"; do
    IFS='/' read -r GOOS GOARCH <<< "$platform"
    
    echo "Building for $GOOS/$GOARCH..."
    
    output_name="$APP_NAME-$VERSION-$GOOS-$GOARCH"
    if [ "$GOOS" = "windows" ]; then
        output_name="$output_name.exe"
    fi
    
    env GOOS=$GOOS GOARCH=$GOARCH CGO_ENABLED=0 go build \
        -ldflags="-w -s -X main.version=$VERSION" \
        -o "$BUILD_DIR/$output_name" .
done

echo "✅ Multi-platform build completed!"
ls -la $BUILD_DIR/
```

## 📦 Dockerfile Examples

### Simple Go Application
```dockerfile
# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o app .

# Production stage
FROM alpine:latest

# Install ca-certificates for HTTPS requests
RUN apk --no-cache add ca-certificates

WORKDIR /root/

# Copy binary from builder stage
COPY --from=builder /app/app .

# Create non-root user
RUN adduser -D -s /bin/sh appuser
USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

CMD ["./app"]
```

### Go with Database Migrations
```dockerfile
# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache git

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o app .

# Install migrate tool
RUN go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# Production stage
FROM alpine:latest

# Install runtime dependencies
RUN apk --no-cache add ca-certificates postgresql-client

WORKDIR /root/

# Copy binary and migrate tool
COPY --from=builder /app/app .
COPY --from=builder /go/bin/migrate .
COPY --from=builder /app/migrations ./migrations

# Copy startup script
COPY docker-entrypoint.sh .
RUN chmod +x docker-entrypoint.sh

# Create non-root user
RUN adduser -D -s /bin/sh appuser
RUN chown -R appuser:appuser /root
USER appuser

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["./app"]
```

### Docker Entrypoint Script
```bash
#!/bin/sh
# docker-entrypoint.sh

set -e

# Wait for database to be ready
if [ -n "$DATABASE_URL" ]; then
    echo "Waiting for database..."
    until pg_isready -d "$DATABASE_URL"; do
        echo "Database is unavailable - sleeping"
        sleep 1
    done
    echo "Database is up - executing command"
    
    # Run migrations
    echo "Running database migrations..."
    ./migrate -database "$DATABASE_URL" -path ./migrations up
fi

# Execute the main command
exec "$@"
```

## 📝 Features

### Performance
- ✅ Compiled binary deployment
- ✅ Minimal resource usage
- ✅ Fast startup times
- ✅ Efficient memory management
- ✅ Built-in concurrency

### Security
- ✅ Static binary compilation
- ✅ Minimal attack surface
- ✅ Built-in crypto libraries
- ✅ Memory safety
- ✅ Type safety

### Monitoring
- ✅ Built-in metrics with expvar
- ✅ Prometheus metrics integration
- ✅ Structured logging
- ✅ Health check endpoints
- ✅ Distributed tracing

### Development
- ✅ Fast compilation
- ✅ Cross-platform builds
- ✅ Excellent tooling
- ✅ Built-in testing
- ✅ Dependency management

## 🛠️ Prerequisites

### System Requirements
- Go 1.19+ (1.21+ recommended)
- Git for dependency management
- Make (optional, for Makefiles)
- Docker (for containerized deployments)

### Go Dependencies
```go
// go.mod
module my-go-app

go 1.21

require (
    github.com/gin-gonic/gin v1.9.1
    github.com/lib/pq v1.10.9
    github.com/go-redis/redis/v8 v8.11.5
    github.com/golang-migrate/migrate/v4 v4.16.2
    github.com/prometheus/client_golang v1.17.0
    google.golang.org/grpc v1.58.3
    google.golang.org/protobuf v1.31.0
)
```

## 📚 Usage Examples

### Example 1: Simple REST API
```bash
# Deploy Go REST API to Ubuntu VPS
cd api/vps/ubuntu/
export APP_NAME="user-api"
export PORT="8080"
export DOMAIN="api.mysite.com"
sudo ./deploy.sh
```

### Example 2: Microservice with Database
```bash
# Deploy Go microservice with PostgreSQL
cd microservices/with-postgresql/
export SERVICE_NAME="user-service"
export DB_NAME="users"
sudo ./deploy.sh
```

### Example 3: gRPC Service
```bash
# Deploy gRPC service to Kubernetes
cd grpc/kubernetes/
export SERVICE_NAME="user-grpc"
export GRPC_PORT="50051"
kubectl apply -f manifests/
```

## 🔍 Troubleshooting

### Common Issues

**Build Failures**
```bash
# Check Go version
go version

# Verify dependencies
go mod verify
go mod tidy

# Clean module cache
go clean -modcache
```

**Runtime Issues**
```bash
# Check binary
file ./app
ldd ./app  # Check dynamic dependencies

# Test locally
./app &
curl http://localhost:8080/health
```

**Database Connection Issues**
```bash
# Test database connection
psql -h localhost -U appuser -d myapp

# Check environment variables
env | grep DB_
```

### Performance Optimization

**Memory Usage**
```bash
# Profile memory usage
go tool pprof http://localhost:8080/debug/pprof/heap

# Check for memory leaks
go tool pprof http://localhost:8080/debug/pprof/allocs
```

**CPU Performance**
```bash
# Profile CPU usage
go tool pprof http://localhost:8080/debug/pprof/profile

# Check goroutines
go tool pprof http://localhost:8080/debug/pprof/goroutine
```

## 🔗 Related Documentation

- [Database Scripts](../../databases/README.md)
- [Container Scripts](../../containers/README.md)
- [Cloud Services](../../cloud-services/README.md)
- [Monitoring Scripts](../../tools/monitoring/README.md)