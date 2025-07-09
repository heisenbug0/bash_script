#!/bin/bash

# Deploy to Vercel
# Works with Next.js, React, Vue, and static sites

set -e

# Load utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/logging.sh"
source "$SCRIPT_DIR/../../utils/validation.sh"

# Configuration
PROJECT_NAME="${PROJECT_NAME:-$(basename $(pwd))}"
DOMAIN="${DOMAIN:-}"

main() {
    log_step "Starting Vercel deployment"
    
    # Check for Node.js project
    if [ ! -f "package.json" ]; then
        log_error "No package.json found - Vercel requires a Node.js project"
        exit 1
    fi
    
    if ! has_command node; then
        log_error "Node.js is required but not installed"
        exit 1
    fi
    
    # Install Vercel CLI if needed
    if ! has_command vercel; then
        log_step "Installing Vercel CLI"
        npm install -g vercel
    fi
    
    # Login check
    if ! vercel whoami >/dev/null 2>&1; then
        log_step "Please login to Vercel"
        vercel login
    fi
    
    # Install dependencies
    log_step "Installing dependencies"
    npm install
    
    # Deploy
    log_step "Deploying to Vercel"
    
    if [ -n "$DOMAIN" ]; then
        # Deploy with custom domain
        vercel --prod --yes
        vercel alias set "$PROJECT_NAME" "$DOMAIN"
    else
        # Standard deployment
        vercel --prod --yes
    fi
    
    # Get deployment info
    DEPLOYMENT_URL=$(vercel ls "$PROJECT_NAME" 2>/dev/null | grep https | head -1 | awk '{print $2}')
    
    log_success "Deployed to Vercel!"
    echo
    echo "Project: $PROJECT_NAME"
    echo "URL: $DEPLOYMENT_URL"
    if [ -n "$DOMAIN" ]; then
        echo "Custom domain: https://$DOMAIN"
    fi
    echo
    echo "Manage at: https://vercel.com/dashboard"
}

main "$@"