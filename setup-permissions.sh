#!/bin/bash
set -euo pipefail

# YouTrack runs as UID:GID 13001:13001
YOUTRACK_UID=13001
YOUTRACK_GID=13001

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== YouTrack Docker - Permission Setup ===${NC}\n"

# Load environment variables from stack.env if it exists
if [ -f "stack.env" ]; then
    echo -e "${YELLOW}Loading configuration from stack.env...${NC}"
    export $(grep -v '^#' stack.env | xargs)
fi

# Default paths - use environment variables or default to named volumes
DATA_PATH="${YOUTRACK_DATA:-}"
CONF_PATH="${YOUTRACK_CONF:-}"
LOGS_PATH="${YOUTRACK_LOGS:-}"
BACKUPS_PATH="${YOUTRACK_BACKUPS:-}"

# Function to check if path is a bind mount (starts with ./ or /)
is_bind_mount() {
    local path="$1"
    [[ "$path" =~ ^(\./|/) ]]
}

# Function to setup directory with proper permissions
setup_directory() {
    local path="$1"
    local name="$2"
    
    if [ -z "$path" ]; then
        echo -e "${YELLOW}✓ $name: Using Docker named volume (no permission setup needed)${NC}"
        return 0
    fi
    
    if ! is_bind_mount "$path"; then
        echo -e "${YELLOW}✓ $name: Using Docker named volume '$path' (no permission setup needed)${NC}"
        return 0
    fi
    
    # Expand relative paths
    if [[ "$path" =~ ^\. ]]; then
        path="$(cd "$(dirname "$path")" && pwd)/$(basename "$path")"
    fi
    
    echo -e "${GREEN}Setting up $name: $path${NC}"
    
    # Create directory if it doesn't exist
    if [ ! -d "$path" ]; then
        echo "  - Creating directory..."
        mkdir -p "$path"
    else
        echo "  - Directory already exists"
    fi
    
    # Set permissions
    echo "  - Setting permissions (750)..."
    chmod 750 "$path"
    
    # Set ownership
    echo "  - Setting ownership ($YOUTRACK_UID:$YOUTRACK_GID)..."
    if command -v chown &> /dev/null; then
        sudo chown -R $YOUTRACK_UID:$YOUTRACK_GID "$path" 2>/dev/null || {
            echo -e "  ${RED}⚠ Warning: Could not set ownership. You may need to run with sudo.${NC}"
            return 1
        }
    else
        echo -e "  ${RED}⚠ Warning: chown command not found${NC}"
        return 1
    fi
    
    echo -e "  ${GREEN}✓ $name configured successfully${NC}\n"
    return 0
}

# Check if running on Linux
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo -e "${YELLOW}Note: This script is optimized for Linux systems.${NC}"
    echo -e "${YELLOW}On macOS/Windows with Docker Desktop, volume permissions are handled differently.${NC}\n"
fi

# Setup each directory
echo -e "${GREEN}Configuring directories...${NC}\n"

failed=0
setup_directory "$DATA_PATH" "Data directory" || ((failed++))
setup_directory "$CONF_PATH" "Config directory" || ((failed++))
setup_directory "$LOGS_PATH" "Logs directory" || ((failed++))
setup_directory "$BACKUPS_PATH" "Backups directory" || ((failed++))

echo -e "\n${GREEN}=== Setup Summary ===${NC}"

if [ $failed -eq 0 ]; then
    echo -e "${GREEN}✓ All directories configured successfully!${NC}\n"
    echo -e "You can now start YouTrack with:"
    echo -e "  ${GREEN}make up${NC} or ${GREEN}docker-compose up -d${NC}\n"
    exit 0
else
    echo -e "${YELLOW}⚠ Some directories could not be fully configured.${NC}"
    echo -e "${YELLOW}If using bind mounts, you may need to run:${NC}"
    echo -e "  ${YELLOW}sudo ./setup-permissions.sh${NC}\n"
    exit 1
fi
