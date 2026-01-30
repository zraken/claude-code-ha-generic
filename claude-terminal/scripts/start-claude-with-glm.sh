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
        echo "Initializing GLM backend..." >&2

        # Set language
        chelper lang set en_US 2>&1 | grep -v "^$" || true

        # Authenticate using the stored API key via stdin
        # Use echo with pipe to pass the key
        (echo "$GLM_API_KEY"; sleep 1) | chelper auth glm_coding_plan_global 2>&1 | head -5 || true

        # Reload Claude to use GLM backend
        echo "Reloading Claude with GLM backend..." >&2
        chelper auth reload claude 2>&1 || echo "Note: GLM backend may not be active" >&2

        echo "" >&2
    fi
fi

# Launch Claude with any passed arguments
exec claude "$@"
