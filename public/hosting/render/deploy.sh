#!/bin/bash

# Deploy to Render
# Works with Node.js, Python, and static sites

set -e

# Load utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../utils/logging.sh"
source "$SCRIPT_DIR/../../utils/validation.sh"

# Configuration
PROJECT_NAME="${PROJECT_NAME:-$(basename $(pwd))}"
SERVICE_TYPE="${SERVICE_TYPE:-web}"
DOMAIN="${DOMAIN:-}"

main() {
    log_step "Starting Render deployment"
    
    # Detect project type
    if [ -f "package.json" ]; then
        PROJECT_TYPE="nodejs"
        if grep -q '"react"' package.json; then
            PROJECT_TYPE="react"
        fi
    elif [ -f "requirements.txt" ] || [ -f "manage.py" ]; then
        PROJECT_TYPE="python"
        if [ -f "manage.py" ]; then
            PROJECT_TYPE="django"
        fi
    else
        PROJECT_TYPE="static"
    fi
    
    log_info "Detected project type: $PROJECT_TYPE"
    
    # Create render.yaml based on project type
    log_step "Creating Render configuration"
    
    case "$PROJECT_TYPE" in
        "nodejs")
            cat > render.yaml << EOF
services:
  - type: web
    name: $PROJECT_NAME
    env: node
    buildCommand: npm install
    startCommand: npm start
    envVars:
      - key: NODE_ENV
        value: production
EOF
            ;;
        "react")
            cat > render.yaml << EOF
services:
  - type: web
    name: $PROJECT_NAME
    env: static
    buildCommand: npm install && npm run build
    staticPublishPath: ./build
    envVars:
      - key: NODE_ENV
        value: production
EOF
            ;;
        "django")
            cat > render.yaml << EOF
services:
  - type: web
    name: $PROJECT_NAME
    env: python
    buildCommand: pip install -r requirements.txt
    startCommand: gunicorn ${PROJECT_NAME}.wsgi:application
    envVars:
      - key: DJANGO_SETTINGS_MODULE
        value: ${PROJECT_NAME}.settings
      - key: SECRET_KEY
        generateValue: true

databases:
  - name: ${PROJECT_NAME}-db
    databaseName: ${PROJECT_NAME//-/_}
    user: ${PROJECT_NAME//-/_}_user
EOF
            ;;
        "python")
            cat > render.yaml << EOF
services:
  - type: web
    name: $PROJECT_NAME
    env: python
    buildCommand: pip install -r requirements.txt
    startCommand: gunicorn app:app
    envVars:
      - key: FLASK_ENV
        value: production
EOF
            ;;
        "static")
            cat > render.yaml << EOF
services:
  - type: web
    name: $PROJECT_NAME
    env: static
    buildCommand: echo "Static site - no build needed"
    staticPublishPath: ./
EOF
            ;;
    esac
    
    # Install Render CLI if needed
    if ! has_command render; then
        log_step "Installing Render CLI"
        if has_command npm; then
            npm install -g @render/cli
        else
            log_error "npm is required to install Render CLI"
            exit 1
        fi
    fi
    
    # Login check
    if ! render auth whoami >/dev/null 2>&1; then
        log_step "Please login to Render"
        render auth login
    fi
    
    # Deploy using blueprint
    log_step "Deploying to Render"
    render blueprint deploy render.yaml
    
    log_success "Deployed to Render!"
    echo
    echo "Project: $PROJECT_NAME"
    echo "Type: $PROJECT_TYPE"
    echo
    echo "Manage at: https://dashboard.render.com"
    echo "View logs: render logs $PROJECT_NAME"
}

main "$@"