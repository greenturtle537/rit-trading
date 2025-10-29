#!/bin/bash

# RIT Trading - Live Server Monitor & Database Inspector
# A multipurpose debugging tool for monitoring API requests, errors, and database inspection

set -e

# Configuration
DB_PATH="rit-trading.db"
SERVER_LOG="rit-trading.log"
PORT=3000

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Version
VERSION="1.0.0"

# Helper function to print colored headers
print_header() {
    echo -e "\n${BOLD}${BLUE}================================${NC}"
    echo -e "${BOLD}${CYAN}$1${NC}"
    echo -e "${BOLD}${BLUE}================================${NC}\n"
}

# Helper function to print colored subheaders
print_subheader() {
    echo -e "\n${BOLD}${MAGENTA}>>> $1${NC}\n"
}

# Helper function to print success messages
print_success() {
    echo -e "${GREEN}[OK] $1${NC}"
}

# Helper function to print error messages
print_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Helper function to print warning messages
print_warning() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

# Helper function to print info messages
print_info() {
    echo -e "${CYAN}[INFO] $1${NC}"
}

# Check if database exists
check_database() {
    if [ ! -f "$DB_PATH" ]; then
        print_error "Database not found at $DB_PATH"
        exit 1
    fi
}

# Check if server is running
check_server() {
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        print_success "Server is running on port $PORT"
        return 0
    else
        print_warning "Server does not appear to be running on port $PORT"
        return 1
    fi
}

# Display server status
show_status() {
    print_header "SERVER STATUS"
    
    check_database
    check_server
    
    # Check database size
    if [ -f "$DB_PATH" ]; then
        DB_SIZE=$(du -h "$DB_PATH" | cut -f1)
        print_info "Database size: $DB_SIZE"
    fi
    
    # Count total records
    TOTAL_USERS=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM users;")
    print_info "Total users: $TOTAL_USERS"
    
    # Get category counts
    print_subheader "Category Statistics"
    
    echo -e "${BOLD}Category                       Table                    Listings${NC}"
    echo "------------------------------------------------------------------------"
    
    while IFS='|' read -r name table; do
        COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM $table;" 2>/dev/null || echo "0")
        printf "%-30s %-24s %8d\n" "$name" "$table" "$COUNT"
    done < <(sqlite3 "$DB_PATH" "SELECT name, table_name FROM categories ORDER BY name;")
}

# Monitor live API requests
monitor_live() {
    print_header "LIVE API REQUEST MONITOR"
    print_info "Monitoring API requests on port $PORT (Press Ctrl+C to stop)"
    print_info "Watching for HTTP requests...\n"
    
    # Create named pipe if it doesn't exist
    FIFO="/tmp/rit-trading-monitor-$$"
    mkfifo "$FIFO" 2>/dev/null || true
    
    # Use tcpdump to capture HTTP requests
    if command -v tcpdump >/dev/null 2>&1; then
        sudo tcpdump -i any -l -A -s 0 "tcp port $PORT and (((ip[2:2] - ((ip[0]&0xf)<<2)) - ((tcp[12]&0xf0)>>2)) != 0)" 2>/dev/null | \
        while IFS= read -r line; do
            # Parse HTTP method and path
            if [[ "$line" =~ ^(GET|POST|PUT|DELETE|OPTIONS|PATCH)[[:space:]]([^[:space:]]+) ]]; then
                METHOD="${BASH_REMATCH[1]}"
                PATH="${BASH_REMATCH[2]}"
                TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
                
                case $METHOD in
                    GET)    COLOR=$GREEN ;;
                    POST)   COLOR=$YELLOW ;;
                    PUT)    COLOR=$BLUE ;;
                    DELETE) COLOR=$RED ;;
                    *)      COLOR=$NC ;;
                esac
                
                echo -e "${CYAN}[$TIMESTAMP]${NC} ${COLOR}${METHOD}${NC} ${BOLD}${PATH}${NC}"
            fi
            
            # Parse Authorization headers
            if [[ "$line" =~ Authorization:.*Bearer[[:space:]]([a-zA-Z0-9]+) ]]; then
                TOKEN="${BASH_REMATCH[1]}"
                echo -e "  ${MAGENTA}→ Auth: ${TOKEN:0:16}...${NC}"
            fi
        done
    else
        print_warning "tcpdump not available. Falling back to log monitoring..."
        
        # Fall back to monitoring server output if available
        if [ -f "$SERVER_LOG" ]; then
            tail -f "$SERVER_LOG" | while IFS= read -r line; do
                echo -e "${CYAN}[$(date '+%H:%M:%S')]${NC} $line"
            done
        else
            print_error "Cannot monitor requests. Install tcpdump or configure server logging."
            print_info "To install tcpdump: apt-get install tcpdump"
        fi
    fi
}

# Show all users
show_users() {
    print_header "ALL USERS"
    
    sqlite3 -column -header "$DB_PATH" "
        SELECT 
            id,
            email,
            name,
            user_role AS 'role',
            datetime(created_at, 'localtime') AS 'created'
        FROM users
        ORDER BY created_at DESC;
    "
    
    echo ""
    TOTAL=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM users;")
    print_info "Total users: $TOTAL"
}

# Show user details
show_user_details() {
    local user_id=$1
    
    if [ -z "$user_id" ]; then
        read -p "Enter user ID: " user_id
    fi
    
    print_header "USER DETAILS - ID: $user_id"
    
    # Get user info
    sqlite3 -column -header "$DB_PATH" "
        SELECT 
            id,
            email,
            name,
            user_role,
            datetime(created_at, 'localtime') AS 'created_at'
        FROM users
        WHERE id = $user_id;
    "
    
    # Get user's posts from all categories
    print_subheader "User's Posts"
    
    # Get all category tables
    TABLES=$(sqlite3 "$DB_PATH" "SELECT table_name FROM categories;")
    
    for table in $TABLES; do
        COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM $table WHERE user_id = $user_id;" 2>/dev/null || echo "0")
        
        if [ "$COUNT" -gt 0 ]; then
            echo -e "\n${YELLOW}Category: $table ($COUNT posts)${NC}"
            sqlite3 -column -header "$DB_PATH" "
                SELECT 
                    id,
                    title,
                    price,
                    datetime(created_at, 'localtime') AS 'created'
                FROM $table
                WHERE user_id = $user_id
                ORDER BY created_at DESC;
            " 2>/dev/null
        fi
    done
}

# Show all categories
show_categories() {
    print_header "ALL CATEGORIES"
    
    sqlite3 -column -header "$DB_PATH" "
        SELECT 
            id,
            name,
            table_name,
            description
        FROM categories
        ORDER BY name;
    "
    
    echo ""
    TOTAL=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM categories;")
    print_info "Total categories: $TOTAL"
}

# Show listings from a category
show_listings() {
    local category=$1
    
    if [ -z "$category" ]; then
        echo ""
        sqlite3 -column "$DB_PATH" "SELECT table_name FROM categories ORDER BY name;"
        echo ""
        read -p "Enter category table name: " category
    fi
    
    print_header "LISTINGS IN: $category"
    
    # Check if table exists
    TABLE_EXISTS=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='$category';")
    
    if [ "$TABLE_EXISTS" -eq 0 ]; then
        print_error "Table '$category' does not exist"
        return 1
    fi
    
    sqlite3 -column -header "$DB_PATH" "
        SELECT 
            l.id,
            l.title,
            l.price,
            u.name AS 'seller',
            u.email,
            datetime(l.created_at, 'localtime') AS 'created'
        FROM $category l
        JOIN users u ON l.user_id = u.id
        ORDER BY l.created_at DESC
        LIMIT 50;
    "
    
    echo ""
    TOTAL=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM $category;")
    print_info "Total listings: $TOTAL (showing up to 50)"
}

# Show listing details
show_listing_details() {
    local category=$1
    local listing_id=$2
    
    if [ -z "$category" ]; then
        read -p "Enter category table name: " category
    fi
    
    if [ -z "$listing_id" ]; then
        read -p "Enter listing ID: " listing_id
    fi
    
    print_header "LISTING DETAILS - $category #$listing_id"
    
    sqlite3 -line "$DB_PATH" "
        SELECT 
            l.*,
            u.name AS 'seller_name',
            u.email AS 'seller_email',
            u.user_role AS 'seller_role'
        FROM $category l
        JOIN users u ON l.user_id = u.id
        WHERE l.id = $listing_id;
    "
}

# Show recent activity
show_recent_activity() {
    print_header "RECENT ACTIVITY"
    
    print_subheader "Recently Created Users (Last 10)"
    sqlite3 -column -header "$DB_PATH" "
        SELECT 
            id,
            name,
            email,
            datetime(created_at, 'localtime') AS 'created'
        FROM users
        ORDER BY created_at DESC
        LIMIT 10;
    "
    
    print_subheader "Recently Posted Listings (Last 20)"
    
    # Get all category tables and union their recent posts
    TABLES=$(sqlite3 "$DB_PATH" "SELECT table_name FROM categories;")
    
    # Create a temporary query that unions all tables
    QUERY=""
    for table in $TABLES; do
        if [ -n "$QUERY" ]; then
            QUERY="$QUERY UNION ALL "
        fi
        QUERY="$QUERY SELECT '$table' as category, id, user_id, title, price, created_at FROM $table"
    done
    
    if [ -n "$QUERY" ]; then
        sqlite3 -column -header "$DB_PATH" "
            SELECT 
                category,
                id,
                title,
                price,
                datetime(created_at, 'localtime') AS 'created'
            FROM (
                $QUERY
            )
            ORDER BY created_at DESC
            LIMIT 20;
        " 2>/dev/null || print_warning "Some tables may not exist yet"
    fi
}

# Search functionality
search_listings() {
    local search_term=$1
    
    if [ -z "$search_term" ]; then
        read -p "Enter search term: " search_term
    fi
    
    print_header "SEARCH RESULTS FOR: '$search_term'"
    
    # Get all category tables
    TABLES=$(sqlite3 "$DB_PATH" "SELECT table_name FROM categories;")
    
    for table in $TABLES; do
        COUNT=$(sqlite3 "$DB_PATH" "
            SELECT COUNT(*) FROM $table 
            WHERE title LIKE '%$search_term%' 
               OR description LIKE '%$search_term%';
        " 2>/dev/null || echo "0")
        
        if [ "$COUNT" -gt 0 ]; then
            echo -e "\n${YELLOW}Found in $table: ($COUNT results)${NC}"
            sqlite3 -column -header "$DB_PATH" "
                SELECT 
                    id,
                    title,
                    price,
                    datetime(created_at, 'localtime') AS 'created'
                FROM $table
                WHERE title LIKE '%$search_term%'
                   OR description LIKE '%$search_term%'
                ORDER BY created_at DESC;
            " 2>/dev/null
        fi
    done
}

# Show database statistics
show_stats() {
    print_header "DATABASE STATISTICS"
    
    # Users by role
    print_subheader "Users by Role"
    sqlite3 -column -header "$DB_PATH" "
        SELECT 
            user_role AS 'Role',
            COUNT(*) AS 'Count'
        FROM users
        GROUP BY user_role
        ORDER BY COUNT(*) DESC;
    "
    
    # Listings by category
    print_subheader "Listings by Category"
    TABLES=$(sqlite3 "$DB_PATH" "SELECT name, table_name FROM categories ORDER BY name;")
    
    echo -e "${BOLD}Category\t\t\tCount${NC}"
    echo "----------------------------------------"
    
    while IFS='|' read -r name table; do
        COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM $table;" 2>/dev/null || echo "0")
        printf "%-30s %5d\n" "$name" "$COUNT"
    done < <(sqlite3 "$DB_PATH" "SELECT name, table_name FROM categories ORDER BY name;")
    
    # Activity by date
    print_subheader "User Registrations by Day (Last 7 Days)"
    sqlite3 -column -header "$DB_PATH" "
        SELECT 
            DATE(created_at) AS 'Date',
            COUNT(*) AS 'New Users'
        FROM users
        WHERE created_at >= DATE('now', '-7 days')
        GROUP BY DATE(created_at)
        ORDER BY DATE(created_at) DESC;
    " 2>/dev/null || print_info "No recent registrations"
}

# Execute custom SQL query
execute_query() {
    print_header "CUSTOM SQL QUERY"
    
    echo "Enter SQL query (or 'quit' to cancel):"
    read -e -p "> " query
    
    if [ "$query" = "quit" ] || [ -z "$query" ]; then
        return
    fi
    
    echo ""
    sqlite3 -column -header "$DB_PATH" "$query" 2>&1
    echo ""
}

# Check database schema for issues
check_schema() {
    print_header "DATABASE SCHEMA CHECK"
    
    if [ ! -f "$DB_PATH" ]; then
        print_error "Database not found at $DB_PATH"
        return 1
    fi
    
    print_info "Checking all category tables for required columns..."
    echo ""
    
    # Get all category tables
    TABLES=$(sqlite3 "$DB_PATH" "SELECT table_name FROM categories;" 2>/dev/null)
    
    if [ -z "$TABLES" ]; then
        print_warning "No categories found in database"
        return 1
    fi
    
    REQUIRED_COLS="id user_id title description price location contact_email contact_phone created_at last_edited_at"
    HAS_ISSUES=0
    
    for table in $TABLES; do
        echo -e "${BOLD}Checking table: $table${NC}"
        
        # Get actual column count that matches required columns
        ACTUAL_COLS=$(sqlite3 "$DB_PATH" "PRAGMA table_info($table);" 2>/dev/null | cut -d'|' -f2 | tr '\n' ' ')
        
        if [ -z "$ACTUAL_COLS" ]; then
            echo -e "${RED}  [ERROR] Table does not exist or cannot be read${NC}"
            HAS_ISSUES=1
            continue
        fi
        
        # Check each required column
        MISSING=""
        for col in $REQUIRED_COLS; do
            if ! echo " $ACTUAL_COLS " | grep -q " ${col} "; then
                if [ -z "$MISSING" ]; then
                    MISSING="$col"
                else
                    MISSING="$MISSING, $col"
                fi
            fi
        done
        
        if [ -n "$MISSING" ]; then
            echo -e "${RED}  [ERROR] Missing columns: $MISSING${NC}"
            HAS_ISSUES=1
        else
            echo -e "${GREEN}  [OK] All required columns present${NC}"
        fi
        
        # Show count
        COUNT=$(sqlite3 "$DB_PATH" "SELECT COUNT(*) FROM $table;" 2>/dev/null)
        echo -e "  Records: $COUNT"
        echo ""
    done
    
    if [ $HAS_ISSUES -eq 1 ]; then
        echo -e "${RED}${BOLD}SCHEMA ISSUES FOUND!${NC}"
        echo ""
        print_warning "To fix schema issues, run:"
        echo "  ${BOLD}perl fix-schema.pl${NC}"
        echo ""
        print_info "This will recreate tables with correct schema while preserving data"
        return 1
    else
        echo -e "${GREEN}${BOLD}All tables have correct schema!${NC}"
        return 0
    fi
}

# Show error log (if exists)
show_errors() {
    print_header "SERVER ERROR LOG"
    
    if [ -f "$SERVER_LOG" ]; then
        print_info "Showing last 50 error/warning lines from $SERVER_LOG"
        echo ""
        grep -E "\[ERROR\]|\[WARN\]" "$SERVER_LOG" | tail -50
        
        if [ $? -ne 0 ]; then
            print_warning "No errors or warnings found in log file"
        fi
    else
        print_warning "No log file found at $SERVER_LOG"
        print_info "Log file will be created automatically when server starts"
    fi
}

# Show help/quick reference
show_help() {
    cat << 'EOF'
===============================================================================
                RIT TRADING MONITOR - QUICK REFERENCE                 
===============================================================================

BASIC USAGE
-------------------------------------------------------------------------------
  ./monitor.sh                    Interactive menu
  ./monitor.sh <command> [args]   Run specific command

MONITORING COMMANDS
-------------------------------------------------------------------------------
  status                          Server status & database size
  watch                           Live API request monitoring (requires sudo)
  recent                          Recent users & listings
  errors                          View error logs
  logs                            Watch server logs with highlighting

USER COMMANDS
-------------------------------------------------------------------------------
  users                           List all users
  user <id>                       User details & their posts
  
  Examples:
    ./monitor.sh users
    ./monitor.sh user 5

CATEGORY & LISTING COMMANDS
-------------------------------------------------------------------------------
  categories                      List all categories
  listings <category>             View listings in category
  listing <cat> <id>              Detailed listing view
  
  Examples:
    ./monitor.sh categories
    ./monitor.sh listings electronics
    ./monitor.sh listing electronics 12

SEARCH & STATS
-------------------------------------------------------------------------------
  search <term>                   Search all listings
  stats                           Database statistics
  query                           Custom SQL query (interactive)
  schema                          Check database schema for issues
  
  Examples:
    ./monitor.sh search "laptop"
    ./monitor.sh stats
    ./monitor.sh schema

OTHER COMMANDS
-------------------------------------------------------------------------------
  help                            Show this help message
  version                         Show version information

QUICK DATABASE QUERIES
-------------------------------------------------------------------------------
  # Count users by role
  sqlite3 rit-trading.db "SELECT user_role, COUNT(*) FROM users GROUP BY user_role;"
  
  # Most active users (by post count)
  sqlite3 rit-trading.db "SELECT u.name, COUNT(*) as posts FROM users u JOIN electronics e ON u.id=e.user_id GROUP BY u.id;"
  
  # Recent listings
  sqlite3 rit-trading.db "SELECT * FROM electronics ORDER BY created_at DESC LIMIT 10;"

TROUBLESHOOTING
-------------------------------------------------------------------------------
  Server not running?       perl server.pl
  Permission denied?        chmod +x monitor.sh
  Watch not working?        sudo apt-get install tcpdump
  Database not found?       cd /workspaces/rit-trading/backend

TIPS
-------------------------------------------------------------------------------
  * Run from backend directory: cd backend && ./monitor.sh
  * Live monitoring needs sudo: sudo ./monitor.sh watch
  * Export data: ./monitor.sh users > users.txt
  * Continuous monitoring: watch -n 2 './monitor.sh recent'
  * Pipe to grep: ./monitor.sh errors | grep "authentication"

AVAILABLE CATEGORIES
-------------------------------------------------------------------------------
  electronics              cars_trucks              furniture
  books                    clothing                 free_stuff
  tutoring_services        tech_services            creative_services
  moving_labor             looking_for_items        looking_for_services
  looking_for_housing      job_opportunities

COLOR CODES
-------------------------------------------------------------------------------
  [OK]    Green   - Success, GET requests
  [ERROR] Red     - Errors, DELETE requests
  [WARN]  Yellow  - Warnings, POST requests
  [INFO]  Cyan    - Information, timestamps

For detailed documentation, see MONITOR_README.md

===============================================================================
EOF
}

# Show version
show_version() {
    echo "RIT Trading Monitor v${VERSION}"
    echo "A comprehensive monitoring and debugging tool"
    echo ""
    echo "Components:"
    echo "  - Live API monitoring"
    echo "  - Database inspection"
    echo "  - Log watching"
    echo "  - Statistics & analytics"
}

# Watch server logs with enhanced formatting
watch_logs() {
    print_header "LIVE SERVER LOG VIEWER"
    print_info "Watching server logs (Press Ctrl+C to stop)"
    
    # Function to colorize and format log lines
    format_log_line() {
        local line="$1"
        
        # Check if line already has timestamp (new format)
        if [[ "$line" =~ ^\[([0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2})\] ]]; then
            # Line already has timestamp from server
            
            # Color code based on log level
            if [[ "$line" =~ \[ERROR\] ]]; then
                echo -e "${RED}$line${NC}"
            elif [[ "$line" =~ \[WARN\] ]]; then
                echo -e "${YELLOW}$line${NC}"
            elif [[ "$line" =~ \[INFO\] ]]; then
                echo -e "${GREEN}$line${NC}"
            # Request log format: [timestamp] IP METHOD - /path - status
            elif [[ "$line" =~ POST\ -\ .*/api/auth/login ]]; then
                echo -e "${CYAN}$line${NC}"
            elif [[ "$line" =~ POST\ -\ .*/api/auth/signup ]]; then
                echo -e "${CYAN}$line${NC}"
            elif [[ "$line" =~ POST ]]; then
                echo -e "${YELLOW}$line${NC}"
            elif [[ "$line" =~ DELETE ]]; then
                echo -e "${RED}$line${NC}"
            elif [[ "$line" =~ PUT ]]; then
                echo -e "${BLUE}$line${NC}"
            elif [[ "$line" =~ GET ]]; then
                echo -e "${GREEN}$line${NC}"
            else
                echo -e "$line"
            fi
            return
        fi
        
        # Old format without timestamp - add one
        local timestamp=$(date '+%H:%M:%S')
        
        # API endpoints
        if [[ "$line" =~ POST\ /api/auth/signup ]]; then
            echo -e "${CYAN}[$timestamp]${NC} ${GREEN}New user signup${NC}"
        elif [[ "$line" =~ POST\ /api/auth/login ]]; then
            echo -e "${CYAN}[$timestamp]${NC} ${GREEN}User login${NC}"
        elif [[ "$line" =~ GET\ /api/categories ]]; then
            echo -e "${CYAN}[$timestamp]${NC} ${BLUE}Categories requested${NC}"
        elif [[ "$line" =~ GET\ /api/listings/([a-z_]+) ]]; then
            category="${BASH_REMATCH[1]}"
            echo -e "${CYAN}[$timestamp]${NC} ${BLUE}Listings: ${BOLD}$category${NC}"
        elif [[ "$line" =~ POST\ /api/listings/([a-z_]+) ]]; then
            category="${BASH_REMATCH[1]}"
            echo -e "${CYAN}[$timestamp]${NC} ${YELLOW}New listing in: ${BOLD}$category${NC}"
        elif [[ "$line" =~ PUT\ /api/posts/([a-z_]+)/([0-9]+) ]]; then
            category="${BASH_REMATCH[1]}"
            id="${BASH_REMATCH[2]}"
            echo -e "${CYAN}[$timestamp]${NC} ${BLUE}Update post: ${BOLD}$category #$id${NC}"
        elif [[ "$line" =~ DELETE\ /api/posts/([a-z_]+)/([0-9]+) ]]; then
            category="${BASH_REMATCH[1]}"
            id="${BASH_REMATCH[2]}"
            echo -e "${CYAN}[$timestamp]${NC} ${RED}Delete post: ${BOLD}$category #$id${NC}"
        elif [[ "$line" =~ GET\ /api/admin/users ]]; then
            echo -e "${CYAN}[$timestamp]${NC} ${MAGENTA}Admin: View users${NC}"
        elif [[ "$line" =~ POST\ /api/admin/posts/delete ]]; then
            echo -e "${CYAN}[$timestamp]${NC} ${RED}Admin: Delete post${NC}"
        
        # Errors and warnings
        elif [[ "$line" =~ [Ee]rror|[Ff]ail ]]; then
            echo -e "${CYAN}[$timestamp]${NC} ${RED}[ERROR]${NC} $line"
        elif [[ "$line" =~ [Ww]arning ]]; then
            echo -e "${CYAN}[$timestamp]${NC} ${YELLOW}[WARN]${NC} $line"
        
        # Database operations
        elif [[ "$line" =~ INSERT\ INTO\ ([a-z_]+) ]]; then
            table="${BASH_REMATCH[1]}"
            echo -e "${CYAN}[$timestamp]${NC} ${GREEN}DB Insert: $table${NC}"
        elif [[ "$line" =~ UPDATE\ ([a-z_]+) ]]; then
            table="${BASH_REMATCH[1]}"
            echo -e "${CYAN}[$timestamp]${NC} ${BLUE}DB Update: $table${NC}"
        elif [[ "$line" =~ DELETE\ FROM\ ([a-z_]+) ]]; then
            table="${BASH_REMATCH[1]}"
            echo -e "${CYAN}[$timestamp]${NC} ${RED}DB Delete: $table${NC}"
        
        # Server startup
        elif [[ "$line" =~ "Server running at" ]]; then
            echo -e "${CYAN}[$timestamp]${NC} ${GREEN}${BOLD}Server started!${NC}"
            echo -e "${GREEN}$line${NC}"
        
        # Authentication
        elif [[ "$line" =~ "Authentication required" ]]; then
            echo -e "${CYAN}[$timestamp]${NC} ${YELLOW}Auth required${NC}"
        elif [[ "$line" =~ "Access denied" ]]; then
            echo -e "${CYAN}[$timestamp]${NC} ${RED}Access denied${NC}"
        
        # Generic HTTP methods
        elif [[ "$line" =~ ^(GET|POST|PUT|DELETE|PATCH|OPTIONS) ]]; then
            echo -e "${CYAN}[$timestamp]${NC} $line"
        
        # Default: show as-is
        else
            if [[ -n "$line" ]]; then
                echo -e "${CYAN}[$timestamp]${NC} $line"
            fi
        fi
    }
    
    # Check if log file exists
    if [ -f "$SERVER_LOG" ]; then
        print_success "Found log file at $SERVER_LOG"
        echo ""
        tail -f "$SERVER_LOG" | while IFS= read -r line; do
            format_log_line "$line"
        done
    else
        print_warning "No log file found at $SERVER_LOG"
        echo ""
        print_info "Log file will be created automatically when server starts"
        print_info "Start the server with: perl server.pl"
        echo ""
        print_info "For now, watching database for changes..."
        echo ""
        
        # Fall back to watching database changes
        if [ -f "$DB_PATH" ]; then
            LAST_MODIFIED=$(stat -c %Y "$DB_PATH" 2>/dev/null || stat -f %m "$DB_PATH" 2>/dev/null)
            
            while true; do
                sleep 2
                CURRENT_MODIFIED=$(stat -c %Y "$DB_PATH" 2>/dev/null || stat -f %m "$DB_PATH" 2>/dev/null)
                
                if [ "$CURRENT_MODIFIED" != "$LAST_MODIFIED" ]; then
                    echo -e "${CYAN}[$(date '+%H:%M:%S')]${NC} ${GREEN}Database activity detected${NC}"
                    
                    # Show most recent entry
                    RECENT=$(sqlite3 "$DB_PATH" "
                        SELECT datetime(created_at, 'localtime'), 'electronics', title 
                        FROM electronics 
                        ORDER BY created_at DESC LIMIT 1
                    " 2>/dev/null)
                    
                    if [ -n "$RECENT" ]; then
                        echo -e "  ${BLUE}-> $RECENT${NC}"
                    fi
                    
                    LAST_MODIFIED=$CURRENT_MODIFIED
                fi
            done
        else
            print_error "Database not found"
        fi
    fi
}

# Interactive menu
show_menu() {
    clear
    print_header "RIT TRADING - MONITORING & DEBUG TOOL v${VERSION}"
    
    echo -e "${BOLD}Live Monitoring:${NC}"
    echo "  1) Live API Request Monitor"
    echo "  2) Watch Server Logs"
    echo "  3) Show Server Status"
    echo "  4) Show Recent Activity"
    echo ""
    echo -e "${BOLD}Database Inspection:${NC}"
    echo "  5) Show All Users"
    echo "  6) Show User Details"
    echo "  7) Show All Categories"
    echo "  8) Show Listings by Category"
    echo "  9) Show Listing Details"
    echo " 10) Search Listings"
    echo ""
    echo -e "${BOLD}Statistics & Analysis:${NC}"
    echo " 11) Show Database Statistics"
    echo " 12) Execute Custom SQL Query"
    echo ""
    echo -e "${BOLD}Debugging:${NC}"
    echo " 13) Show Server Error Log"
    echo " 14) Check Database Schema"
    echo ""
    echo -e "${BOLD}Help:${NC}"
    echo " 15) Show Help / Quick Reference"
    echo ""
    echo "  0) Exit"
    echo ""
}

# Main interactive loop
main_menu() {
    while true; do
        show_menu
        read -p "Select option: " choice
        
        case $choice in
            1) monitor_live ;;
            2) watch_logs ;;
            3) show_status; read -p "Press Enter to continue..." ;;
            4) show_recent_activity; read -p "Press Enter to continue..." ;;
            5) show_users; read -p "Press Enter to continue..." ;;
            6) show_user_details; read -p "Press Enter to continue..." ;;
            7) show_categories; read -p "Press Enter to continue..." ;;
            8) show_listings; read -p "Press Enter to continue..." ;;
            9) show_listing_details; read -p "Press Enter to continue..." ;;
            10) search_listings; read -p "Press Enter to continue..." ;;
            11) show_stats; read -p "Press Enter to continue..." ;;
            12) execute_query; read -p "Press Enter to continue..." ;;
            13) show_errors; read -p "Press Enter to continue..." ;;
            14) check_schema; read -p "Press Enter to continue..." ;;
            15) show_help; read -p "Press Enter to continue..." ;;
            0) 
                echo -e "\n${GREEN}Goodbye!${NC}\n"
                exit 0
                ;;
            *)
                print_error "Invalid option. Please try again."
                sleep 2
                ;;
        esac
    done
}

# Parse command line arguments
if [ $# -eq 0 ]; then
    # No arguments - show interactive menu
    main_menu
else
    # Arguments provided - execute specific command
    case "$1" in
        status)
            show_status
            ;;
        monitor|live|watch)
            if [ "$1" = "watch" ]; then
                monitor_live
            else
                monitor_live
            fi
            ;;
        logs)
            watch_logs
            ;;
        users)
            show_users
            ;;
        user)
            show_user_details "$2"
            ;;
        categories)
            show_categories
            ;;
        listings)
            show_listings "$2"
            ;;
        listing)
            show_listing_details "$2" "$3"
            ;;
        recent)
            show_recent_activity
            ;;
        search)
            search_listings "$2"
            ;;
        stats)
            show_stats
            ;;
        query)
            execute_query
            ;;
        errors)
            show_errors
            ;;
        schema)
            check_schema
            ;;
        help|--help|-h)
            show_help
            ;;
        version|--version|-v)
            show_version
            ;;
        *)
            echo "RIT Trading Monitor v${VERSION}"
            echo ""
            echo "Usage: $0 [command] [args]"
            echo ""
            echo "Commands:"
            echo "  status              - Show server status"
            echo "  watch               - Monitor live API requests (requires sudo)"
            echo "  logs                - Watch server logs with highlighting"
            echo "  users               - Show all users"
            echo "  user <id>           - Show user details"
            echo "  categories          - Show all categories"
            echo "  listings <category> - Show listings in category"
            echo "  listing <cat> <id>  - Show listing details"
            echo "  recent              - Show recent activity"
            echo "  search <term>       - Search all listings"
            echo "  stats               - Show database statistics"
            echo "  query               - Execute custom SQL query"
            echo "  errors              - Show error log"
            echo "  schema              - Check database schema for issues"
            echo "  help                - Show detailed help"
            echo ""
            echo "Run without arguments for interactive menu"
            exit 1
            ;;
    esac
fi
