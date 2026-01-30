#!/usr/bin/with-contenv bashio

# GLM Coding Helper Authentication Script
# Handles GLM backend authentication for Claude Terminal Pro

# Log function with timestamps
log_info() {
    bashio::log.info "$1"
}

log_error() {
    bashio::log.error "$1"
}

log_warning() {
    bashio::log.warning "$1"
}

# Check if chelper is available
check_chelper_installed() {
    if ! command -v chelper &> /dev/null; then
        log_error "GLM coding helper (chelper) not found"
        log_error "Please ensure the Docker image includes @z_ai/coding-helper"
        return 1
    fi
    log_info "GLM coding helper (chelper) found: $(chelper --version 2>/dev/null || echo 'version unknown')"
    return 0
}

# Authenticate with GLM API
authenticate_glm() {
    local api_key="$1"

    if [ -z "$api_key" ]; then
        log_error "GLM API key is required but not provided"
        return 1
    fi

    log_info "Configuring GLM coding helper language..."
    chelper lang set en_US 2>/dev/null || log_warning "Failed to set GLM language (may not be critical)"

    log_info "Authenticating with GLM API..."
    # Use echo to pass the key via stdin to avoid exposing in process list
    if echo "$api_key" | chelper auth glm_coding_plan_global - 2>/dev/null; then
        log_info "GLM authentication successful"
    else
        log_error "GLM authentication failed"
        return 1
    fi

    log_info "Reloading Claude to use GLM backend..."
    if chelper auth reload claude 2>/dev/null; then
        log_info "Claude backend reloaded to use GLM"
    else
        log_warning "Claude reload failed - you may need to restart the terminal"
    fi

    return 0
}

# Main execution
main() {
    local glm_api_key="$1"

    log_info "=== GLM Coding Helper Setup ==="

    # Check if chelper is installed
    if ! check_chelper_installed; then
        exit 1
    fi

    # Check if we have the API key
    if [ -z "$glm_api_key" ]; then
        # Try to get from config if not provided as argument
        glm_api_key=$(bashio::config 'glm_api_key' '')
    fi

    if [ -z "$glm_api_key" ]; then
        log_error "No GLM API key provided"
        exit 1
    fi

    # Perform authentication
    if authenticate_glm "$glm_api_key"; then
        log_info "=== GLM Setup Complete ==="
        log_info "Claude Terminal will now use GLM as the AI backend"
        exit 0
    else
        log_error "=== GLM Setup Failed ==="
        exit 1
    fi
}

# Run main function
main "$@"
