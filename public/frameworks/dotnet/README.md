# .NET Deployment Scripts

Comprehensive deployment scripts for .NET applications across various platforms, databases, and caching systems.

## 📁 Directory Structure

```
dotnet/
├── aspnet-core/         # ASP.NET Core applications
├── blazor/             # Blazor applications
├── minimal-api/        # Minimal API applications
├── with-postgresql/    # .NET + PostgreSQL combinations
├── with-sqlserver/     # .NET + SQL Server combinations
├── with-redis/         # .NET + Redis combinations
├── full-stack/         # Complete stacks (DB + Cache + Monitoring)
├── api-only/           # .NET API deployments
├── microservices/      # .NET microservices
└── containers/         # Docker and Kubernetes deployments
```

## 🎯 Deployment Scenarios

### Application Types
- **ASP.NET Core**: Full-stack web applications
- **Blazor**: Interactive web UIs
- **Minimal APIs**: Lightweight APIs
- **Web APIs**: RESTful services
- **gRPC Services**: High-performance RPC

### Database Integrations
- **SQL Server**: Microsoft's relational database
- **PostgreSQL**: Open-source relational database
- **MySQL**: Traditional relational database
- **SQLite**: Lightweight embedded database
- **MongoDB**: Document-based NoSQL

### Caching Solutions
- **Redis**: In-memory data structure store
- **SQL Server Cache**: Distributed SQL Server cache
- **In-Memory**: Built-in memory caching
- **Azure Cache**: Azure Redis Cache

## 🚀 Quick Start Examples

### Deploy ASP.NET Core App to VPS
```bash
cd aspnet-core/vps/ubuntu/
export APP_NAME="my-dotnet-app"
export DOTNET_VERSION="8.0"
export DOMAIN="app.example.com"
sudo ./deploy.sh
```

### Deploy .NET API + PostgreSQL to AWS
```bash
cd with-postgresql/aws-ec2/
export APP_NAME="my-api"
export DB_NAME="myapp"
sudo ./deploy.sh
```

### Deploy Blazor App to Azure
```bash
cd blazor/azure-app-service/
export APP_NAME="my-blazor-app"
export RESOURCE_GROUP="my-rg"
./deploy.sh
```

## 📋 Configuration

### Environment Variables
```bash
# Application Configuration
export APP_NAME="my-dotnet-app"
export DOTNET_VERSION="8.0"
export ASPNETCORE_ENVIRONMENT="Production"
export ASPNETCORE_URLS="http://+:5000"

# Database Configuration
export ConnectionStrings__DefaultConnection="Server=localhost;Database=myapp;User Id=appuser;Password=password;"
export DB_HOST="localhost"
export DB_PORT="5432"
export DB_NAME="myapp"
export DB_USER="appuser"
export DB_PASSWORD="securepassword"

# Redis Configuration (if applicable)
export ConnectionStrings__Redis="localhost:6379"
export REDIS_HOST="localhost"
export REDIS_PORT="6379"
export REDIS_PASSWORD=""

# Security Configuration
export JWT_SECRET="your-jwt-secret"
export JWT_ISSUER="your-app"
export JWT_AUDIENCE="your-app-users"

# Logging Configuration
export Logging__LogLevel__Default="Information"
export Logging__LogLevel__Microsoft="Warning"
```

## 📝 Application Examples

### ASP.NET Core Web API
```csharp
// Program.cs
using Microsoft.EntityFrameworkCore;
using MyApp.Data;
using MyApp.Models;

var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Database
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors("AllowAll");
app.UseAuthorization();
app.MapControllers();

// Health check endpoint
app.MapGet("/health", () => new { Status = "Healthy", Timestamp = DateTime.UtcNow });

app.Run();

// Models/User.cs
namespace MyApp.Models
{
    public class User
    {
        public int Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}

// Data/AppDbContext.cs
using Microsoft.EntityFrameworkCore;
using MyApp.Models;

namespace MyApp.Data
{
    public class AppDbContext : DbContext
    {
        public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

        public DbSet<User> Users { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<User>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Name).IsRequired().HasMaxLength(100);
                entity.Property(e => e.Email).IsRequired().HasMaxLength(255);
                entity.HasIndex(e => e.Email).IsUnique();
            });
        }
    }
}

// Controllers/UsersController.cs
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MyApp.Data;
using MyApp.Models;

namespace MyApp.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class UsersController : ControllerBase
    {
        private readonly AppDbContext _context;

        public UsersController(AppDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<User>>> GetUsers()
        {
            return await _context.Users.OrderByDescending(u => u.CreatedAt).ToListAsync();
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<User>> GetUser(int id)
        {
            var user = await _context.Users.FindAsync(id);
            return user == null ? NotFound() : user;
        }

        [HttpPost]
        public async Task<ActionResult<User>> CreateUser(User user)
        {
            _context.Users.Add(user);
            await _context.SaveChangesAsync();
            return CreatedAtAction(nameof(GetUser), new { id = user.Id }, user);
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateUser(int id, User user)
        {
            if (id != user.Id) return BadRequest();

            _context.Entry(user).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!UserExists(id)) return NotFound();
                throw;
            }

            return NoContent();
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteUser(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null) return NotFound();

            _context.Users.Remove(user);
            await _context.SaveChangesAsync();
            return NoContent();
        }

        private bool UserExists(int id) => _context.Users.Any(e => e.Id == id);
    }
}
```

### Minimal API Example
```csharp
// Program.cs (Minimal API)
using Microsoft.EntityFrameworkCore;
using MyApp.Data;
using MyApp.Models;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

// Health check
app.MapGet("/health", () => new { Status = "Healthy", Timestamp = DateTime.UtcNow });

// Users endpoints
app.MapGet("/api/users", async (AppDbContext db) =>
    await db.Users.OrderByDescending(u => u.CreatedAt).ToListAsync());

app.MapGet("/api/users/{id}", async (int id, AppDbContext db) =>
    await db.Users.FindAsync(id) is User user ? Results.Ok(user) : Results.NotFound());

app.MapPost("/api/users", async (User user, AppDbContext db) =>
{
    db.Users.Add(user);
    await db.SaveChangesAsync();
    return Results.Created($"/api/users/{user.Id}", user);
});

app.MapPut("/api/users/{id}", async (int id, User inputUser, AppDbContext db) =>
{
    var user = await db.Users.FindAsync(id);
    if (user is null) return Results.NotFound();

    user.Name = inputUser.Name;
    user.Email = inputUser.Email;
    await db.SaveChangesAsync();
    return Results.NoContent();
});

app.MapDelete("/api/users/{id}", async (int id, AppDbContext db) =>
{
    var user = await db.Users.FindAsync(id);
    if (user is null) return Results.NotFound();

    db.Users.Remove(user);
    await db.SaveChangesAsync();
    return Results.NoContent();
});

app.Run();
```

## 📝 Build Scripts

### Standard Build Script
```bash
#!/usr/bin/env bash
# build.sh for .NET deployment
set -o errexit

echo "🚀 Starting .NET deployment build..."

# Check .NET version
dotnet --version

# Restore dependencies
echo "📦 Restoring dependencies..."
dotnet restore

# Build application
echo "🔨 Building application..."
dotnet build --configuration Release --no-restore

# Run tests
echo "🧪 Running tests..."
dotnet test --configuration Release --no-build --verbosity normal

# Publish application
echo "📦 Publishing application..."
dotnet publish --configuration Release --no-build --output ./publish

echo "✅ Build completed successfully!"
```

### Docker Build Script
```bash
#!/usr/bin/env bash
# docker-build.sh
set -o errexit

echo "🐳 Building Docker image..."

# Build Docker image
docker build -t $APP_NAME:latest .

# Tag for registry (if specified)
if [ -n "$DOCKER_REGISTRY" ]; then
    docker tag $APP_NAME:latest $DOCKER_REGISTRY/$APP_NAME:latest
    docker push $DOCKER_REGISTRY/$APP_NAME:latest
fi

echo "✅ Docker build completed!"
```

## 📝 Configuration Files

### appsettings.json
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost;Database=myapp;User Id=appuser;Password=password;",
    "Redis": "localhost:6379"
  },
  "JwtSettings": {
    "Secret": "your-secret-key",
    "Issuer": "your-app",
    "Audience": "your-app-users",
    "ExpiryMinutes": 60
  },
  "AllowedHosts": "*",
  "Cors": {
    "AllowedOrigins": ["https://example.com"]
  }
}
```

### appsettings.Production.json
```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Warning",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "ConnectionStrings": {
    "DefaultConnection": "${ConnectionStrings__DefaultConnection}",
    "Redis": "${ConnectionStrings__Redis}"
  },
  "JwtSettings": {
    "Secret": "${JWT_SECRET}",
    "Issuer": "${JWT_ISSUER}",
    "Audience": "${JWT_AUDIENCE}"
  }
}
```

### Project File (.csproj)
```xml
<Project Sdk="Microsoft.NET.Sdk.Web">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.AspNetCore.OpenApi" Version="8.0.0" />
    <PackageReference Include="Microsoft.EntityFrameworkCore.Design" Version="8.0.0">
      <PrivateAssets>all</PrivateAssets>
      <IncludeAssets>runtime; build; native; contentfiles; analyzers; buildtransitive</IncludeAssets>
    </PackageReference>
    <PackageReference Include="Microsoft.EntityFrameworkCore.Tools" Version="8.0.0" />
    <PackageReference Include="Npgsql.EntityFrameworkCore.PostgreSQL" Version="8.0.0" />
    <PackageReference Include="StackExchange.Redis" Version="2.7.0" />
    <PackageReference Include="Swashbuckle.AspNetCore" Version="6.5.0" />
    <PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="8.0.0" />
    <PackageReference Include="System.IdentityModel.Tokens.Jwt" Version="7.0.0" />
  </ItemGroup>

</Project>
```

## 📦 Docker Configuration

### Dockerfile
```dockerfile
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 5000

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src
COPY ["MyApp.csproj", "."]
RUN dotnet restore "./MyApp.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "MyApp.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "MyApp.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Create non-root user
RUN adduser --disabled-password --gecos '' appuser
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

ENTRYPOINT ["dotnet", "MyApp.dll"]
```

### docker-compose.yml
```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "5000:5000"
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - ConnectionStrings__DefaultConnection=Server=db;Database=myapp;User Id=appuser;Password=password;
      - ConnectionStrings__Redis=redis:6379
    depends_on:
      - db
      - redis

  db:
    image: postgres:15
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

## 📝 Features

### Performance
- ✅ AOT compilation support
- ✅ Minimal APIs for lightweight services
- ✅ Async/await patterns
- ✅ Connection pooling
- ✅ Response caching

### Security
- ✅ Built-in authentication & authorization
- ✅ JWT token support
- ✅ HTTPS enforcement
- ✅ CORS configuration
- ✅ Input validation

### Development
- ✅ Hot reload support
- ✅ Swagger/OpenAPI integration
- ✅ Entity Framework migrations
- ✅ Dependency injection
- ✅ Configuration management

### Monitoring
- ✅ Built-in logging
- ✅ Health checks
- ✅ Metrics collection
- ✅ Application Insights integration
- ✅ Structured logging

## 🛠️ Prerequisites

### System Requirements
- .NET 8.0+ SDK
- Database system (PostgreSQL, SQL Server, etc.)
- Redis server (if caching enabled)
- Docker (for containerized deployments)

## 📚 Usage Examples

### Example 1: Enterprise API
```bash
# Deploy ASP.NET Core API to Ubuntu VPS
cd api-only/vps/ubuntu/
export APP_NAME="enterprise-api"
export DOTNET_VERSION="8.0"
export DOMAIN="api.mysite.com"
sudo ./deploy.sh
```

### Example 2: Blazor Application
```bash
# Deploy Blazor app with SQL Server
cd blazor/with-sqlserver/
export APP_NAME="my-blazor-app"
export DB_NAME="blazorapp"
sudo ./deploy.sh
```

### Example 3: Microservice
```bash
# Deploy .NET microservice to Kubernetes
cd microservices/kubernetes/
export SERVICE_NAME="user-service"
export NAMESPACE="production"
kubectl apply -f manifests/
```

## 🔍 Troubleshooting

### Common Issues

**Build Issues**
```bash
# Clean solution
dotnet clean

# Restore packages
dotnet restore

# Check .NET version
dotnet --version
```

**Database Issues**
```bash
# Update database
dotnet ef database update

# Check migrations
dotnet ef migrations list

# Create migration
dotnet ef migrations add InitialCreate
```

**Performance Issues**
```bash
# Profile application
dotnet-trace collect -p $(pgrep dotnet)

# Check memory usage
dotnet-counters monitor -p $(pgrep dotnet)

# Analyze dumps
dotnet-dump analyze dump.dmp
```

## 🔗 Related Documentation

- [Database Scripts](../../databases/README.md)
- [Caching Scripts](../../caching/README.md)
- [Cloud Services](../../cloud-services/README.md)
- [Hosting Platforms](../../hosting/README.md)