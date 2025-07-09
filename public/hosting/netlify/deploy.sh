#!/bin/bash

# Deploy to Netlify
# Works with any static site or build process

set -e

# Load utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/logging.sh"
source "$SCRIPT_DIR/../../utils/validation.sh"

# Configuration
SITE_NAME="${SITE_NAME:-$(basename $(pwd))}"
BUILD_COMMAND="${BUILD_COMMAND:-npm run build}"
BUILD_DIR="${BUILD_DIR:-build}"
DOMAIN="${DOMAIN:-}"

main() {
    log_step "Starting Netlify deployment"
    
    # Check if we have a build process
    if [ -f "package.json" ]; then
        if ! has_command node; then
            log_error "Node.js is required but not installed"
            exit 1
        fi
        
        log_step "Installing dependencies"
        npm install
        
        log_step "Building project"
        $BUILD_COMMAND
        
        if [ ! -d "$BUILD_DIR" ]; then
            log_error "Build failed - no $BUILD_DIR directory found"
            exit 1
        fi
    else
        # Assume it's a static site
        BUILD_DIR="."
        log_info "No package.json found, treating as static site"
    fi
    
    # Install Netlify CLI if needed
    if ! has_command netlify; then
        log_step "Installing Netlify CLI"
        npm install -g netlify-cli
    fi
    
    # Login check
    if ! netlify status >/dev/null 2>&1; then
        log_step "Please login to Netlify"
        netlify login
    fi
    
    # Deploy
    log_step "Deploying to Netlify"
    
    if [ -n "$DOMAIN" ]; then
        # Production deployment with custom domain
        netlify deploy --prod --dir="$BUILD_DIR" --site="$SITE_NAME"
        netlify sites:update --name="$SITE_NAME" --domain="$DOMAIN"
    else
        # Production deployment
        netlify deploy --prod --dir="$BUILD_DIR"
    fi
    
    # Get the URL
    SITE_URL=$(netlify status --json | grep -o '"url":"[^"]*"' | cut -d'"' -f4)
    
    log_success "Deployed to Netlify!"
    echo
    echo "Site: $SITE_NAME"
    echo "URL: $SITE_URL"
    if [ -n "$DOMAIN" ]; then
        echo "Custom domain: $DOMAIN"
    fi
    echo
    echo "Manage at: https://app.netlify.com"
}

main "$@"