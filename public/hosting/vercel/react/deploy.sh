#!/bin/bash

# React Application Deployment Script for Vercel
# Optimized for React applications with build configurations

set -euo pipefail

# Configuration
PROJECT_NAME="${PROJECT_NAME:-$(basename $(pwd))}"
VERCEL_TOKEN="${VERCEL_TOKEN:-}"
DOMAIN="${DOMAIN:-}"
BUILD_COMMAND="${BUILD_COMMAND:-npm run build}"
OUTPUT_DIR="${OUTPUT_DIR:-build}"
NODE_VERSION="${NODE_VERSION:-18}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed. Please install Node.js first."
        exit 1
    fi
    
    # Check if npm is installed
    if ! command -v npm &> /dev/null; then
        log_error "npm is not installed. Please install npm first."
        exit 1
    fi
    
    # Check if package.json exists
    if [ ! -f "package.json" ]; then
        log_error "package.json not found. Please run this script from your React project root."
        exit 1
    fi
    
    # Check if React is in dependencies
    if ! grep -q '"react"' package.json; then
        log_error "React not found in package.json. This script is for React applications."
        exit 1
    fi
    
    # Check Node.js version
    NODE_CURRENT_VERSION=$(node --version | sed 's/v//')
    NODE_MAJOR_VERSION=$(echo "$NODE_CURRENT_VERSION" | cut -d. -f1)
    
    if [ "$NODE_MAJOR_VERSION" -lt 14 ]; then
        log_warn "Node.js version $NODE_CURRENT_VERSION detected. Vercel recommends Node.js 14 or higher."
    fi
    
    log_info "Prerequisites check passed"
}

# Install Vercel CLI
install_vercel_cli() {
    log_step "Installing Vercel CLI..."
    
    if ! command -v vercel &> /dev/null; then
        npm install -g vercel@latest
        log_info "Vercel CLI installed successfully"
    else
        # Update to latest version
        npm update -g vercel
        log_info "Vercel CLI updated to latest version"
    fi
}

# Authenticate with Vercel
authenticate_vercel() {
    log_step "Authenticating with Vercel..."
    
    if [ -n "$VERCEL_TOKEN" ]; then
        echo "$VERCEL_TOKEN" | vercel login --stdin
        log_info "Authenticated using token"
    else
        log_info "Please authenticate with Vercel:"
        vercel login
    fi
}

# Detect React framework and build tool
detect_react_setup() {
    log_step "Detecting React setup..."
    
    # Check for Create React App
    if grep -q '"react-scripts"' package.json; then
        REACT_TYPE="create-react-app"
        BUILD_COMMAND="${BUILD_COMMAND:-npm run build}"
        OUTPUT_DIR="${OUTPUT_DIR:-build}"
        log_info "Detected Create React App"
    # Check for Vite
    elif grep -q '"vite"' package.json; then
        REACT_TYPE="vite"
        BUILD_COMMAND="${BUILD_COMMAND:-npm run build}"
        OUTPUT_DIR="${OUTPUT_DIR:-dist}"
        log_info "Detected Vite React application"
    # Check for Next.js (should use Next.js specific script)
    elif grep -q '"next"' package.json; then
        log_warn "Next.js detected. Consider using the Next.js specific deployment script."
        REACT_TYPE="nextjs"
        BUILD_COMMAND="${BUILD_COMMAND:-npm run build}"
        OUTPUT_DIR="${OUTPUT_DIR:-.next}"
    # Check for custom webpack setup
    elif grep -q '"webpack"' package.json; then
        REACT_TYPE="custom-webpack"
        BUILD_COMMAND="${BUILD_COMMAND:-npm run build}"
        OUTPUT_DIR="${OUTPUT_DIR:-build}"
        log_info "Detected custom webpack setup"
    else
        REACT_TYPE="custom"
        log_info "Custom React setup detected"
    fi
}

# Create optimized vercel.json configuration
create_vercel_config() {
    log_step "Creating Vercel configuration..."
    
    case "$REACT_TYPE" in
        "create-react-app")
            cat > vercel.json << EOF
{
  "version": 2,
  "name": "$PROJECT_NAME",
  "buildCommand": "$BUILD_COMMAND",
  "outputDirectory": "$OUTPUT_DIR",
  "framework": "create-react-app",
  "installCommand": "npm ci",
  "devCommand": "npm start",
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ],
  "headers": [
    {
      "source": "/static/(.*)",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=31536000, immutable"
        }
      ]
    },
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "X-XSS-Protection",
          "value": "1; mode=block"
        }
      ]
    }
  ]
}
EOF
            ;;
        "vite")
            cat > vercel.json << EOF
{
  "version": 2,
  "name": "$PROJECT_NAME",
  "buildCommand": "$BUILD_COMMAND",
  "outputDirectory": "$OUTPUT_DIR",
  "framework": "vite",
  "installCommand": "npm ci",
  "devCommand": "npm run dev",
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ],
  "headers": [
    {
      "source": "/assets/(.*)",
      "headers": [
        {
          "key": "Cache-Control",
          "value": "public, max-age=31536000, immutable"
        }
      ]
    },
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "X-XSS-Protection",
          "value": "1; mode=block"
        }
      ]
    }
  ]
}
EOF
            ;;
        "nextjs")
            cat > vercel.json << EOF
{
  "version": 2,
  "name": "$PROJECT_NAME",
  "framework": "nextjs",
  "buildCommand": "$BUILD_COMMAND",
  "installCommand": "npm ci"
}
EOF
            ;;
        *)
            cat > vercel.json << EOF
{
  "version": 2,
  "name": "$PROJECT_NAME",
  "buildCommand": "$BUILD_COMMAND",
  "outputDirectory": "$OUTPUT_DIR",
  "installCommand": "npm ci",
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ],
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "X-XSS-Protection",
          "value": "1; mode=block"
        }
      ]
    }
  ]
}
EOF
            ;;
    esac
    
    log_info "Vercel configuration created for $REACT_TYPE"
}

# Optimize package.json for deployment
optimize_package_json() {
    log_step "Optimizing package.json for deployment..."
    
    # Create a backup
    cp package.json package.json.backup
    
    # Add engines field if not present
    if ! grep -q '"engines"' package.json; then
        # Add engines field after name
        sed -i '/"name":/a\  "engines": {\n    "node": ">=14.0.0",\n    "npm": ">=6.0.0"\n  },' package.json
        log_info "Added engines field to package.json"
    fi
    
    # Ensure build script exists
    if ! grep -q '"build"' package.json; then
        log_warn "No build script found in package.json. Adding default build script."
        # This is a basic fallback - user should have proper build script
        sed -i '/"scripts":/a\    "build": "react-scripts build",' package.json
    fi
}

# Install dependencies
install_dependencies() {
    log_step "Installing dependencies..."
    
    # Clean install for consistent builds
    if [ -f "package-lock.json" ]; then
        npm ci
    elif [ -f "yarn.lock" ]; then
        if ! command -v yarn &> /dev/null; then
            npm install -g yarn
        fi
        yarn install --frozen-lockfile
    elif [ -f "pnpm-lock.yaml" ]; then
        if ! command -v pnpm &> /dev/null; then
            npm install -g pnpm
        fi
        pnpm install --frozen-lockfile
    else
        npm install
    fi
    
    log_info "Dependencies installed successfully"
}

# Run tests (if available)
run_tests() {
    log_step "Running tests..."
    
    if grep -q '"test"' package.json && [ "${SKIP_TESTS:-false}" != "true" ]; then
        if npm test -- --coverage --watchAll=false --passWithNoTests; then
            log_info "Tests passed successfully"
        else
            log_warn "Tests failed, but continuing with deployment"
        fi
    else
        log_info "No tests found or tests skipped"
    fi
}

# Build project locally (for validation)
build_project() {
    log_step "Building project locally for validation..."
    
    if [ "$REACT_TYPE" = "create-react-app" ]; then
        # Set CI=true to treat warnings as errors in CRA
        CI=true npm run build
    else
        npm run build
    fi
    
    # Verify build output exists
    if [ ! -d "$OUTPUT_DIR" ]; then
        log_error "Build output directory '$OUTPUT_DIR' not found after build"
        exit 1
    fi
    
    # Check if index.html exists in build output
    if [ ! -f "$OUTPUT_DIR/index.html" ]; then
        log_error "index.html not found in build output directory"
        exit 1
    fi
    
    log_info "Local build completed successfully"
}

# Setup environment variables
setup_environment() {
    log_step "Setting up environment variables..."
    
    # Check for .env files
    ENV_FILES=(".env" ".env.local" ".env.production" ".env.production.local")
    
    for env_file in "${ENV_FILES[@]}"; do
        if [ -f "$env_file" ]; then
            log_info "Found $env_file file"
            
            # Read environment variables and add them to Vercel
            while IFS= read -r line; do
                # Skip comments and empty lines
                if [[ $line =~ ^[[:space:]]*# ]] || [[ -z "$line" ]]; then
                    continue
                fi
                
                # Extract variable name and value
                if [[ $line == *"="* ]]; then
                    var_name=$(echo "$line" | cut -d'=' -f1)
                    var_value=$(echo "$line" | cut -d'=' -f2-)
                    
                    # Only add REACT_APP_ variables for security
                    if [[ $var_name == REACT_APP_* ]]; then
                        echo "Adding environment variable: $var_name"
                        echo "$var_value" | vercel env add "$var_name" production --force
                    fi
                fi
            done < "$env_file"
        fi
    done
    
    # Add common production environment variables
    echo "production" | vercel env add NODE_ENV production --force
    echo "true" | vercel env add CI production --force
}

# Deploy to Vercel
deploy_to_vercel() {
    log_step "Deploying to Vercel..."
    
    # Deploy with production flag
    if vercel --prod --yes --confirm; then
        log_info "Deployment successful!"
        
        # Get deployment URL
        DEPLOYMENT_URL=$(vercel ls "$PROJECT_NAME" 2>/dev/null | grep "https://" | head -1 | awk '{print $2}' || echo "")
        if [ -n "$DEPLOYMENT_URL" ]; then
            log_info "Deployment URL: $DEPLOYMENT_URL"
        fi
    else
        log_error "Deployment failed"
        exit 1
    fi
}

# Configure custom domain
configure_domain() {
    if [ -n "$DOMAIN" ]; then
        log_step "Configuring custom domain..."
        
        # Add domain to Vercel
        if vercel domains add "$DOMAIN" --yes; then
            log_info "Domain $DOMAIN added successfully"
            
            # Get the deployment URL to alias
            DEPLOYMENT_URL=$(vercel ls "$PROJECT_NAME" 2>/dev/null | grep "https://" | head -1 | awk '{print $2}' || echo "")
            
            if [ -n "$DEPLOYMENT_URL" ]; then
                # Create alias
                if vercel alias set "$DEPLOYMENT_URL" "$DOMAIN"; then
                    log_info "Domain $DOMAIN linked to deployment"
                else
                    log_warn "Failed to link domain $DOMAIN to deployment"
                fi
            fi
        else
            log_warn "Failed to add domain $DOMAIN. It might already exist or require verification."
        fi
    fi
}

# Performance optimization suggestions
suggest_optimizations() {
    log_step "Analyzing build for optimization suggestions..."
    
    if [ -d "$OUTPUT_DIR" ]; then
        # Check bundle size
        BUILD_SIZE=$(du -sh "$OUTPUT_DIR" | cut -f1)
        log_info "Build size: $BUILD_SIZE"
        
        # Check for large files
        echo "Largest files in build:"
        find "$OUTPUT_DIR" -type f -exec ls -lh {} \; | sort -k5 -hr | head -5 | awk '{print $5 " " $9}'
        
        # Suggestions
        echo
        echo "Optimization Suggestions:"
        echo "========================"
        echo "1. Enable gzip compression (handled by Vercel automatically)"
        echo "2. Consider code splitting for large bundles"
        echo "3. Optimize images using next/image or similar tools"
        echo "4. Use React.lazy() for component lazy loading"
        echo "5. Analyze bundle with 'npm run build -- --analyze' (if supported)"
    fi
}

# Display deployment information
display_info() {
    log_info "React application deployment to Vercel completed successfully!"
    echo
    echo "Project Information:"
    echo "==================="
    echo "Project Name: $PROJECT_NAME"
    echo "React Type: $REACT_TYPE"
    echo "Build Command: $BUILD_COMMAND"
    echo "Output Directory: $OUTPUT_DIR"
    echo "Node.js Version: $(node --version)"
    echo
    if [ -n "$DEPLOYMENT_URL" ]; then
        echo "Deployment URL: $DEPLOYMENT_URL"
    fi
    if [ -n "$DOMAIN" ]; then
        echo "Custom Domain: https://$DOMAIN"
    fi
    echo
    echo "Vercel Commands:"
    echo "==============="
    echo "View deployments: vercel ls"
    echo "View logs: vercel logs"
    echo "Remove deployment: vercel rm $PROJECT_NAME"
    echo "View domains: vercel domains ls"
    echo
    echo "Local Development:"
    echo "=================="
    echo "Start dev server: npm start"
    echo "Build locally: npm run build"
    echo "Test locally: npm test"
    echo
    echo "Configuration Files:"
    echo "==================="
    echo "Vercel config: vercel.json"
    echo "Package backup: package.json.backup"
    echo
    echo "Next Steps:"
    echo "==========="
    echo "1. Test your deployed application"
    echo "2. Set up monitoring and analytics"
    echo "3. Configure CI/CD for automatic deployments"
    echo "4. Optimize performance based on suggestions above"
}

# Cleanup function
cleanup() {
    log_info "Cleaning up temporary files..."
    
    # Restore package.json if backup exists
    if [ -f "package.json.backup" ]; then
        if [ "${RESTORE_PACKAGE_JSON:-true}" = "true" ]; then
            mv package.json.backup package.json
            log_info "Restored original package.json"
        fi
    fi
}

# Main execution
main() {
    log_info "Starting React application deployment to Vercel..."
    
    check_prerequisites
    install_vercel_cli
    authenticate_vercel
    detect_react_setup
    create_vercel_config
    optimize_package_json
    install_dependencies
    run_tests
    build_project
    setup_environment
    deploy_to_vercel
    configure_domain
    suggest_optimizations
    display_info
    cleanup
    
    log_info "Deployment completed successfully!"
}

# Set trap for cleanup
trap cleanup EXIT

# Run main function
main "$@"