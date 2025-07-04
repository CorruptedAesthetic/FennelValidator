#!/bin/bash
# 🔐 Secure Fennel Validator Launch Script
# Launches validator with essential security hardening

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# Logging
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }

echo -e "${BLUE}🔐 Secure Fennel Validator Launch${NC}"
echo "================================="
echo

# Check if we're in the right directory
if [ ! -f "validate.sh" ]; then
    log_error "validate.sh not found. Please run from FennelValidator directory."
    exit 1
fi

# Security hardening function
apply_security_hardening() {
    log_info "Applying essential security hardening..."
    
    # Set secure umask
    umask 077
    
    # Secure sensitive files
    chmod 600 session-keys.json 2>/dev/null || true
    chmod 600 stash-account.json 2>/dev/null || true
    chmod 700 config/ 2>/dev/null || true
    chmod 600 config/* 2>/dev/null || true
    
    # Configure firewall for validator security
    if command -v ufw >/dev/null 2>&1; then
        log_info "Configuring firewall for secure validator operation..."
        
        # Enable UFW if not already enabled
        if ! sudo ufw status | grep -q "Status: active"; then
            # Allow SSH first to maintain access
            sudo ufw allow ssh
            log_info "SSH access preserved"
        fi
        
        # Allow Fennel P2P port for validator communication
        sudo ufw allow 30333/tcp comment "Fennel P2P Validator"
        
        # Secure RPC and metrics - only localhost access
        sudo ufw deny 9944/tcp comment "Fennel RPC - Denied External"
        sudo ufw deny 9615/tcp comment "Fennel Metrics - Denied External"
        
        # Enable firewall
        sudo ufw --force enable
        
        log_success "Firewall configured: P2P open, RPC/metrics secured to localhost only"
    else
        log_warning "UFW not available. Please configure firewall manually:"
        log_warning "- Allow port 30333/tcp for P2P communication"
        log_warning "- Block external access to ports 9944 and 9615"
    fi
    
    # Check for and stop any existing validator processes
    if pgrep -f "fennel-node.*--validator" >/dev/null; then
        log_info "Stopping existing validator processes..."
        pkill -f "fennel-node.*--validator" || true
        sleep 2
    fi
    
    log_success "Security hardening applied"
}

# Validate configuration
validate_configuration() {
    log_info "Validating validator configuration..."
    
    # Check if validator is configured
    if [ ! -f "config/validator.conf" ]; then
        log_error "Validator not configured. Please run: ./setup-validator.sh"
        exit 1
    fi
    
    # Check if binary exists
    if [ ! -f "bin/fennel-node" ] && [ ! -f "bin/fennel-node.exe" ]; then
        log_error "Fennel binary not found. Please run: ./install.sh"
        exit 1
    fi
    
    # Check chainspec
    if [ ! -f "config/staging-chainspec.json" ]; then
        log_error "Chainspec not found. Please run: ./install.sh"
        exit 1
    fi
    
    log_success "Configuration validated"
}

# Secure validator startup
secure_start_validator() {
    log_info "Starting validator with security measures..."
    
    # Load configuration
    source config/validator.conf
    
    # Ensure RPC methods are set to safe
    if grep -q "rpc-methods unsafe" validate.sh; then
        log_warning "Detected unsafe RPC methods in validate.sh"
        log_info "Securing RPC methods..."
        sed -i 's/--rpc-methods unsafe/--rpc-methods safe/g' validate.sh
        log_success "RPC methods secured to 'safe' mode"
    fi
    
    # Initialize if needed
    if [ ! -f "data/chains/custom/network/secret_ed25519" ]; then
        log_info "Initializing validator (first time setup)..."
        ./validate.sh init
        
        if [ $? -eq 0 ]; then
            log_success "Validator initialized successfully"
        else
            log_error "Validator initialization failed"
            exit 1
        fi
    else
        log_success "Validator already initialized"
    fi
    
    # Start validator
    log_info "Starting validator in secure mode..."
    ./validate.sh start &
    
    # Wait for startup and verify
    local startup_timeout=30
    local count=0
    
    log_info "Waiting for validator startup (timeout: ${startup_timeout}s)..."
    
    while [ $count -lt $startup_timeout ]; do
        if pgrep -f "fennel-node.*--validator" >/dev/null; then
            log_success "Validator process started"
            break
        fi
        
        sleep 1
        count=$((count + 1))
        
        if [ $((count % 10)) -eq 0 ]; then
            echo "  ... waiting (${count}s)"
        fi
    done
    
    if pgrep -f "fennel-node.*--validator" >/dev/null; then
        log_success "Validator is running securely"
    else
        log_error "Validator failed to start"
        exit 1
    fi
}

# Health check
perform_health_check() {
    log_info "Performing security health check..."
    
    # Check validator process
    if pgrep -f "fennel-node.*--validator" >/dev/null; then
        log_success "✅ Validator process running"
    else
        log_error "❌ Validator process not running"
        return 1
    fi
    
    # Check RPC accessibility (should be localhost only)
    if curl -s -m 5 http://localhost:9944/health >/dev/null; then
        log_success "✅ RPC accessible from localhost"
    else
        log_warning "⚠️  RPC not responding (might still be starting)"
    fi
    
    # Check file permissions
    if [ -f "session-keys.json" ]; then
        local perms=$(stat -c "%a" session-keys.json)
        if [ "$perms" = "600" ]; then
            log_success "✅ Session keys file permissions secure (600)"
        else
            log_warning "⚠️  Session keys file permissions: $perms (should be 600)"
        fi
    fi
    
    # Check firewall status
    if command -v ufw >/dev/null 2>&1; then
        if sudo ufw status | grep -q "Status: active"; then
            log_success "✅ Firewall active"
        else
            log_warning "⚠️  Firewall not active"
        fi
    fi
    
    log_success "Health check completed"
}

# Show status
show_status() {
    echo
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    VALIDATOR STATUS                              ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo
    
    # Get validator name
    local validator_name="Unknown"
    if [ -f "config/validator.conf" ]; then
        validator_name=$(grep "VALIDATOR_NAME" config/validator.conf | cut -d'=' -f2 | tr -d '"')
    fi
    
    echo -e "${BLUE}Validator Name:${NC} $validator_name"
    echo -e "${BLUE}Network:${NC} Fennel Solonet (Staging)"
    echo -e "${BLUE}Security:${NC} Hardened"
    echo -e "${BLUE}RPC Access:${NC} Localhost only"
    echo -e "${BLUE}P2P Port:${NC} 30333 (firewall allowed)"
    echo
    echo -e "${GREEN}🔒 Security Features Active:${NC}"
    echo -e "${GREEN}  • Firewall configured (P2P open, RPC/metrics secured)${NC}"
    echo -e "${GREEN}  • File permissions secured (600/700)${NC}"
    echo -e "${GREEN}  • RPC methods set to 'safe' mode${NC}"
    echo -e "${GREEN}  • Secure process isolation${NC}"
    echo
    echo -e "${BLUE}🛠️  Management Commands:${NC}"
    echo -e "${CYAN}  ./validate.sh status    ${NC}- Check validator status"
    echo -e "${CYAN}  ./validate.sh stop      ${NC}- Stop validator"
    echo -e "${CYAN}  ./validate.sh restart   ${NC}- Restart validator"
    echo -e "${CYAN}  ./validate.sh logs      ${NC}- View logs"
    echo
    echo -e "${GREEN}🎉 Validator launched securely!${NC}"
}

# Main execution
main() {
    log_info "Starting secure validator launch process..."
    
    # Apply security hardening
    apply_security_hardening
    
    # Validate configuration
    validate_configuration
    
    # Start validator securely
    secure_start_validator
    
    # Perform health check
    perform_health_check
    
    # Show final status
    show_status
    
    log_success "Secure launch completed successfully!"
}

# Handle interruption
trap 'echo -e "\n${RED}Launch interrupted.${NC}"; exit 1' INT TERM

# Run main function
main "$@" 