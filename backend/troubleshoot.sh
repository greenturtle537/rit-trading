#!/bin/bash

# RIT Trading Production Troubleshooting Script
# Use this to diagnose common production issues

echo "RIT Trading Production Troubleshooting"
echo "======================================="
echo ""

# Check if backend service is running
echo "1. Checking backend service status..."
if systemctl is-active --quiet rit-trading 2>/dev/null; then
    echo "   ✓ Backend service is running"
else
    echo "   ✗ Backend service is NOT running"
    echo "   Fix: sudo systemctl start rit-trading"
fi
echo ""

# Check if backend is listening on port 3000
echo "2. Checking if backend is listening on port 3000..."
if netstat -tuln 2>/dev/null | grep -q ":3000 "; then
    echo "   ✓ Backend is listening on port 3000"
else
    echo "   ✗ Backend is NOT listening on port 3000"
    echo "   Fix: Check service logs with: journalctl -u rit-trading -n 50"
fi
echo ""

# Check database file permissions
echo "3. Checking database file permissions..."
if [ -f "/var/www/trading/backend/rit-trading.db" ]; then
    DB_OWNER=$(stat -c '%U' /var/www/trading/backend/rit-trading.db)
    echo "   Database file exists (owner: $DB_OWNER)"
    if [ "$DB_OWNER" = "www-data" ]; then
        echo "   ✓ Database has correct ownership"
    else
        echo "   ✗ Database has wrong ownership"
        echo "   Fix: sudo chown www-data:www-data /var/www/trading/backend/rit-trading.db"
    fi
else
    echo "   ✗ Database file not found"
    echo "   Fix: cd /var/www/trading/backend && sudo -u www-data perl init-db.pl prod"
fi
echo ""

# Test API endpoint
echo "4. Testing API endpoint..."
if command -v curl &> /dev/null; then
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/categories 2>/dev/null)
    if [ "$RESPONSE" = "200" ]; then
        echo "   ✓ API is responding correctly (HTTP $RESPONSE)"
    else
        echo "   ✗ API returned HTTP $RESPONSE"
        echo "   Fix: Check service logs with: journalctl -u rit-trading -n 50"
    fi
else
    echo "   ⚠ curl not installed, skipping API test"
fi
echo ""

# Check Apache configuration
echo "5. Checking Apache configuration..."
if [ -f "/etc/apache2/sites-available/trading.conf" ] || [ -f "/etc/apache2/sites-available/000-default.conf" ]; then
    echo "   Apache config file exists"
    
    if grep -r "ProxyPass.*trading" /etc/apache2/sites-available/ 2>/dev/null | grep -q "http://localhost:3000"; then
        echo "   ✓ Apache proxy configuration found"
    else
        echo "   ⚠ Apache proxy configuration not found or incorrect"
        echo "   Add to your Apache config:"
        echo ""
        echo "   ProxyPass /trading/api http://localhost:3000/api"
        echo "   ProxyPassReverse /trading/api http://localhost:3000/api"
    fi
else
    echo "   ⚠ Apache configuration files not found"
fi
echo ""

# Check Apache modules
echo "6. Checking Apache modules..."
if command -v apache2ctl &> /dev/null; then
    if apache2ctl -M 2>/dev/null | grep -q "proxy_module"; then
        echo "   ✓ proxy_module is enabled"
    else
        echo "   ✗ proxy_module is NOT enabled"
        echo "   Fix: sudo a2enmod proxy proxy_http"
    fi
else
    echo "   ⚠ Apache not installed or not accessible"
fi
echo ""

# Show recent service logs
echo "7. Recent service logs (last 10 lines)..."
if command -v journalctl &> /dev/null; then
    journalctl -u rit-trading -n 10 --no-pager 2>/dev/null || echo "   ⚠ Cannot access service logs"
else
    echo "   ⚠ journalctl not available"
fi
echo ""

# Test signup endpoint specifically
echo "8. Testing signup endpoint..."
if command -v curl &> /dev/null; then
    SIGNUP_TEST=$(curl -s -X POST http://localhost:3000/api/auth/signup \
        -H "Content-Type: application/json" \
        -d '{"email":"test@example.com","password":"test123","name":"Test User"}' 2>/dev/null)
    
    if echo "$SIGNUP_TEST" | grep -q "error"; then
        ERROR_MSG=$(echo "$SIGNUP_TEST" | grep -o '"error":"[^"]*"' | cut -d'"' -f4)
        if [ "$ERROR_MSG" = "Email already registered" ]; then
            echo "   ✓ Signup endpoint is working (test email already exists)"
        else
            echo "   ⚠ Signup returned error: $ERROR_MSG"
        fi
    elif echo "$SIGNUP_TEST" | grep -q "success"; then
        echo "   ✓ Signup endpoint is working"
    else
        echo "   ✗ Unexpected response from signup endpoint"
        echo "   Response: $SIGNUP_TEST"
    fi
else
    echo "   ⚠ curl not installed, skipping test"
fi
echo ""

echo "======================================="
echo "Troubleshooting complete!"
echo ""
echo "Common fixes:"
echo "  - Start service: sudo systemctl start rit-trading"
echo "  - View logs: sudo journalctl -u rit-trading -f"
echo "  - Restart service: sudo systemctl restart rit-trading"
echo "  - Check Apache: sudo systemctl status apache2"
echo "  - Enable Apache proxy: sudo a2enmod proxy proxy_http && sudo systemctl restart apache2"
