#!/bin/bash
# This script has been moved to handle safe RPC mode properly

echo "Session key generation script has been updated!"
echo "Redirecting to the correct script..."
echo

# Call the correct script that handles safe RPC mode
exec "$(dirname "$0")/../tools/internal/generate-keys-with-restart.sh" "$@" 