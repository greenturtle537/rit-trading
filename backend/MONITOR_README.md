# RIT Trading Monitor & Debug Tool

A comprehensive bash-based monitoring and debugging tool for the RIT Trading backend server. All functionality is consolidated into a single `monitor.sh` script.

## Features

### Live Monitoring
- **Real-time API Request Monitoring** - Watch HTTP requests as they come in
- **Server Log Watching** - Enhanced log viewer with syntax highlighting
- **Server Status** - Check if the server is running and view database statistics
- **Recent Activity** - See recently registered users and posted listings

### Database Inspection
- **User Management** - View all users, individual user details, and their posts
- **Category Browsing** - List all categories and their statistics
- **Listing Browser** - View listings by category with full details
- **Search** - Search across all categories for specific listings

### Statistics & Analysis
- **Database Statistics** - Users by role, listings by category, activity trends
- **Custom SQL Queries** - Execute custom queries for advanced debugging

### Debugging
- **Error Logs** - View server error logs and warnings

## Usage

### Interactive Menu Mode

Run the script without arguments to enter interactive mode:

```bash
./monitor.sh
```

This will present a menu with all available options.

### Command Line Mode

Run specific commands directly:

```bash
# Show server status
./monitor.sh status

# Monitor live API requests (requires tcpdump or sudo)
./monitor.sh watch

# Watch server logs with highlighting
./monitor.sh logs

# Show all users
./monitor.sh users

# Show details for a specific user
./monitor.sh user 1

# Show all categories
./monitor.sh categories

# Show listings in a category
./monitor.sh listings electronics

# Show specific listing details
./monitor.sh listing electronics 5

# Show recent activity
./monitor.sh recent

# Search for listings
./monitor.sh search "laptop"

# Show database statistics
./monitor.sh stats

# Execute custom SQL query (interactive)
./monitor.sh query

# Show error logs
./monitor.sh errors

# Show help and quick reference
./monitor.sh help

# Show version information
./monitor.sh version
```

## Requirements

- **SQLite3** - For database queries (usually pre-installed)
- **tcpdump** (optional) - For live API request monitoring
  - Without tcpdump, monitoring will fall back to log file watching
  - Install with: `sudo apt-get install tcpdump`
  - Requires sudo privileges for packet capture

## Examples

### Example 1: Check Server Health

```bash
./monitor.sh status
```

Output:
```
================================
SERVER STATUS
================================

✓ Server is running on port 3000
ℹ Database size: 100K
ℹ Total users: 42

>>> Category Statistics

Category                       Table                    Listings
------------------------------------------------------------------------
electronics                    electronics                     12
furniture                      furniture                        8
cars & trucks                  cars_trucks                      5
```

### Example 2: View User Activity

```bash
./monitor.sh user 5
```

Shows complete user profile including:
- User details (email, name, role, creation date)
- All posts by the user across all categories

### Example 3: Search for Items

```bash
./monitor.sh search "laptop"
```

Searches all categories for listings containing "laptop" in title or description.

### Example 4: Monitor Live Requests

```bash
sudo ./monitor.sh watch
```

Watch API requests in real-time:
```
[2025-10-29 14:32:15] GET /api/categories
[2025-10-29 14:32:18] POST /api/auth/login
  -> Auth: 8f3a2b1c4d5e6f7a...
[2025-10-29 14:32:22] GET /api/listings/electronics
```

### Example 5: Watch Server Logs

```bash
./monitor.sh logs
```

Enhanced log viewer with color coding and highlighting for different event types.

### Example 5: Watch Server Logs

```bash
./monitor.sh logs
```

Enhanced log viewer with color coding and highlighting for different event types.

### Example 6: Database Statistics

```bash
./monitor.sh stats
```

Shows:
- User distribution by role (admin, moderator, user)
- Listing counts by category
- Recent registration trends

### Example 7: Custom SQL Query

```bash
./monitor.sh query
```

Then enter any SQL query:
```sql
SELECT u.name, COUNT(e.id) as electronics_count 
FROM users u 
LEFT JOIN electronics e ON u.id = e.user_id 
GROUP BY u.id 
ORDER BY electronics_count DESC;
```

## Configuration

Edit the script to change default settings:

```bash
# Configuration section at top of monitor.sh
DB_PATH="rit-trading.db"           # Database file location
SERVER_LOG="/tmp/rit-trading-server.log"  # Server log file
PORT=3000                          # Server port to monitor
```

## Tips & Tricks

### Continuous Monitoring

To continuously watch recent activity:

```bash
watch -n 2 './monitor.sh recent'
```

### Watch Live Logs

```bash
./monitor.sh logs
```

### Export User List

```bash
./monitor.sh users > users_list.txt
```

### Check for Specific Error Patterns

```bash
./monitor.sh errors | grep -i "authentication"
```

### Find Active Users

```bash
sqlite3 rit-trading.db "
  SELECT u.email, COUNT(*) as post_count 
  FROM users u 
  JOIN electronics e ON u.id = e.user_id 
  GROUP BY u.id 
  HAVING post_count > 0;
"
```

## Keyboard Shortcuts in Interactive Mode

- **Ctrl+C** - Return to menu (when in live monitor)
- **0** - Exit the program
- **Enter** - Continue after viewing results

## Troubleshooting

### "Database not found" Error

Make sure you're running the script from the backend directory:
```bash
cd /workspaces/rit-trading/backend
./monitor.sh
```

### "Server does not appear to be running"

Start the server first:
```bash
perl server.pl
```

Or if running as a service:
```bash
sudo systemctl start rit-trading
```

### Live Monitor Not Working

1. Install tcpdump: `sudo apt-get install tcpdump`
2. Run with sudo: `sudo ./monitor.sh monitor`
3. Alternatively, configure server logging to a file

### Permission Denied

Make the script executable:
```bash
chmod +x monitor.sh
```

## Advanced Usage

### Combining with Other Tools

```bash
# Monitor requests and save to file
sudo ./monitor.sh monitor | tee api_requests.log

# Get JSON output for specific queries
sqlite3 -json rit-trading.db "SELECT * FROM users;" | jq '.'

# Monitor database size changes
watch -n 5 'du -h rit-trading.db'
```

### Automating Checks

Create a cron job to log statistics daily:

```bash
# Add to crontab
0 0 * * * /path/to/monitor.sh stats >> /var/log/rit-trading-stats.log
```

## Color Output

The script uses ANSI color codes for better readability:

- Green [OK] - Success messages and GET requests
- Red [ERROR] - Errors and DELETE requests  
- Yellow [WARN] - Warnings and POST requests
- Blue - Headers and PUT requests
- Magenta - Subheaders
- Cyan [INFO] - Info messages and timestamps

## Security Notes

- The script requires read access to the database file
- Live monitoring with tcpdump requires sudo/root privileges
- Be careful when executing custom SQL queries - use SELECT statements for safety
- Avoid exposing authentication tokens from logs

## Contributing

To add new features to the monitor:

1. Add a new function following the naming pattern `show_*` or `get_*`
2. Add menu entry in `show_menu()`
3. Add case in `main_menu()` and command-line argument parser
4. Update this README with the new feature

## License

Part of the RIT Trading project.
