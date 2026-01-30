#!/bin/bash

# Start Claude with GLM backend if configured
# This script runs in the terminal session environment

# Source the profile to ensure all environment variables are set
if [ -f /etc/profile.d/persistent-packages.sh ]; then
    source /etc/profile.d/persistent-packages.sh
fi

# Check if GLM is enabled via config
GLM_ENABLED_CONFIG="/data/.config/glm-enabled"
GLM_API_KEY_FILE="/data/.config/glm-api-key"

if [ -f "$GLM_ENABLED_CONFIG" ] && [ -f "$GLM_API_KEY_FILE" ]; then
    GLM_API_KEY=$(cat "$GLM_API_KEY_FILE")

    if [ -n "$GLM_API_KEY" ] && command -v chelper >/dev/null 2>&1; then
        echo "Initializing GLM backend..."

        # Set language (may prompt, use default)
        chelper lang set en_US >/dev/null 2>&1 || true

        # Authenticate using the stored API key
        # Use a here-document to avoid exposing the key in ps
        chelper auth glm_coding_plan_global >/dev/null 2>&1 <<< "$GLM_API_KEY" || true

        # Reload Claude to use GLM backend
        chelper auth reload claude >/dev/null 2>&1 || echo "Note: GLM backend may not be active"

        echo ""
    fi
fi

# Launch Claude with any passed arguments
exec claude "$@"
