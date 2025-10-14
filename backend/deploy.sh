#!/bin/bash

# RIT Trading - Database Initialization and Deployment Script
# Usage: ./deploy.sh [test|prod]

set -e  # Exit on error

# Default to test environment
ENVIRONMENT="${1:-test}"

# Configuration
BACKEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DB_FILE="$BACKEND_DIR/rit-trading.db"
SCHEMA_FILE="$BACKEND_DIR/schema.sql"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print colored messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v perl &> /dev/null; then
        log_error "Perl is not installed. Please install Perl first."
        exit 1
    fi
    
    if ! command -v sqlite3 &> /dev/null; then
        log_warn "sqlite3 CLI not found. Will skip verification step."
    fi
    
    log_info "Dependencies check complete."
}

# Install Perl dependencies
install_perl_deps() {
    log_info "Installing Perl dependencies..."
    
    if command -v cpanm &> /dev/null; then
        cpanm --quiet --installdeps "$BACKEND_DIR"
    else
        log_warn "cpanm not found. Attempting to install with cpan..."
        cpan DBI DBD::SQLite HTTP::Daemon JSON URI
    fi
    
    log_info "Perl dependencies installed."
}

# Initialize database
init_database() {
    log_info "Initializing database for $ENVIRONMENT environment..."
    
    # Backup existing database if it exists
    if [ -f "$DB_FILE" ]; then
        BACKUP_FILE="$DB_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        log_warn "Existing database found. Creating backup: $BACKUP_FILE"
        cp "$DB_FILE" "$BACKUP_FILE"
    fi
    
    # Remove old database if in test mode
    if [ "$ENVIRONMENT" = "test" ]; then
        log_info "Test environment: Removing existing database..."
        rm -f "$DB_FILE"
    fi
    
    # Run the initialization script with appropriate mode
    log_info "Running database initialization script..."
    cd "$BACKEND_DIR"
    
    if [ "$ENVIRONMENT" = "test" ]; then
        perl init-db.pl test
    else
        perl init-db.pl prod
    fi
    
    if [ $? -eq 0 ]; then
        log_info "Database initialized successfully!"
    else
        log_error "Database initialization failed!"
        exit 1
    fi
}

# Verify database
verify_database() {
    if ! command -v sqlite3 &> /dev/null; then
        log_warn "Skipping database verification (sqlite3 not found)"
        return
    fi
    
    log_info "Verifying database structure..."
    
    # Check tables exist
    TABLES=$(sqlite3 "$DB_FILE" "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;")
    
    echo "$TABLES" | while read -r table; do
        if [ -n "$table" ]; then
            COUNT=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM $table;")
            log_info "  Table '$table': $COUNT rows"
        fi
    done
    
    log_info "Database verification complete."
}

# Start server (test mode only)
start_server() {
    if [ "$ENVIRONMENT" = "test" ]; then
        log_info "Starting test server..."
        log_info "Press Ctrl+C to stop the server"
        echo ""
        cd "$BACKEND_DIR"
        perl server.pl
    else
        log_info "Production mode: Server not started automatically."
        log_info "To start the server, run: cd $BACKEND_DIR && perl server.pl"
    fi
}

# Main script
main() {
    echo "================================================"
    echo "  RIT Trading - Database Deployment Script"
    echo "  Environment: $ENVIRONMENT"
    echo "================================================"
    echo ""
    
    case "$ENVIRONMENT" in
        test)
            log_info "Running in TEST mode"
            check_dependencies
            install_perl_deps
            init_database
            verify_database
            echo ""
            log_info "Database setup complete!"
            echo ""
            read -p "Start the test server now? (y/n) " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                start_server
            else
                log_info "To start the server later, run: cd $BACKEND_DIR && perl server.pl"
            fi
            ;;
        prod)
            log_info "Running in PRODUCTION mode"
            check_dependencies
            install_perl_deps
            init_database
            verify_database
            log_info "Production database setup complete!"
            log_info "Remember to configure your production web server."
            ;;
        *)
            log_error "Invalid environment: $ENVIRONMENT"
            echo "Usage: $0 [test|prod]"
            exit 1
            ;;
    esac
}

# Run main script
main
