# Apache2 Configuration for RIT Trading

## Prerequisites

Before deploying, ensure these Apache2 modules are enabled:

```bash
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod rewrite
sudo a2enmod deflate
sudo a2enmod expires
```

## Installation Steps

### 1. Copy Frontend Files

```bash
sudo mkdir -p /var/www/rit-trading
sudo cp -r frontend /var/www/rit-trading/
sudo chown -R www-data:www-data /var/www/rit-trading
```

### 2. Install Apache Configuration

```bash
# Copy the configuration file
sudo cp apache2-config/rit-trading.conf /etc/apache2/sites-available/

# Enable the site
sudo a2ensite rit-trading.conf

# Test configuration
sudo apache2ctl configtest

# Reload Apache
sudo systemctl reload apache2
```

### 3. Update /etc/hosts (for local testing)

```bash
echo "127.0.0.1 rit-trading.local" | sudo tee -a /etc/hosts
```

### 4. Start the Perl Backend

```bash
cd /var/www/rit-trading/backend
perl server.pl &
```

Or use systemd for production (see systemd service below).

## Frontend Configuration

Update the frontend JavaScript files to use relative API URLs:

In `main.js`, `category.js`, and `item.js`, change:
```javascript
const API_URL = 'http://localhost:3000/api';
```

To:
```javascript
const API_URL = '/api';
```

Apache will proxy `/api/*` requests to the Perl backend automatically.

## Production Deployment

### Create Systemd Service for Backend

Create `/etc/systemd/system/rit-trading-backend.service`:

```ini
[Unit]
Description=RIT Trading Perl Backend
After=network.target

[Service]
Type=simple
User=www-data
Group=www-data
WorkingDirectory=/var/www/rit-trading/backend
ExecStart=/usr/bin/perl /var/www/rit-trading/backend/server.pl
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable rit-trading-backend
sudo systemctl start rit-trading-backend
sudo systemctl status rit-trading-backend
```

## Testing

1. Access the site: `http://rit-trading.local`
2. Check Apache logs: `sudo tail -f /var/log/apache2/rit-trading-*.log`
3. Check backend status: `sudo systemctl status rit-trading-backend`

## Troubleshooting

### API requests fail (502 Bad Gateway)
- Ensure Perl backend is running: `sudo systemctl status rit-trading-backend`
- Check backend logs
- Verify backend is listening on port 3000: `netstat -tulpn | grep 3000`

### Frontend not loading
- Check Apache error log: `sudo tail -f /var/log/apache2/rit-trading-error.log`
- Verify file permissions: `ls -la /var/www/rit-trading/frontend`

### CORS errors
- Should not occur with reverse proxy (same origin)
- If needed, verify ProxyPreserveHost is On

## Directory Structure

```
/var/www/rit-trading/
├── frontend/
│   ├── index.html
│   ├── category.html
│   ├── item.html
│   ├── main.js
│   ├── category.js
│   ├── item.js
│   ├── favicon.png
│   └── logo.png
└── backend/
    ├── server.pl
    ├── init-db.pl
    ├── schema-structure.sql
    ├── test-data.sql
    ├── rit-trading.db
    └── ...
```

## Security Considerations

1. **Database location**: Ensure `rit-trading.db` is not in DocumentRoot
2. **File permissions**: Frontend files should be readable by www-data
3. **Backend process**: Run backend as www-data or dedicated user
4. **Firewall**: Only expose port 80/443, block direct access to port 3000
5. **SSL/TLS**: Enable HTTPS in production (see commented section in config)

## Performance Tuning

### Enable Keepalive
In `/etc/apache2/apache2.conf`:
```
KeepAlive On
KeepAliveTimeout 5
MaxKeepAliveRequests 100
```

### Adjust worker processes
For mod_mpm_prefork in `/etc/apache2/mods-available/mpm_prefork.conf`:
```
<IfModule mpm_prefork_module>
    StartServers             5
    MinSpareServers          5
    MaxSpareServers         10
    MaxRequestWorkers      150
    MaxConnectionsPerChild   0
</IfModule>
```
