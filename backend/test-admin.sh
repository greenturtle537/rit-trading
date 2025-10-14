#!/bin/bash

# Test script for admin panel functionality

API_URL="http://localhost:3000/api"

echo "Testing Admin Panel Functionality"
echo "=================================="
echo ""

# Test 1: Login as admin
echo "Test 1: Login as admin user"
echo "----------------------------"
ADMIN_RESPONSE=$(curl -s -X POST "$API_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@rit.edu","password":"admin123"}')

echo "Response: $ADMIN_RESPONSE"

# Extract admin token
ADMIN_TOKEN=$(echo $ADMIN_RESPONSE | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$ADMIN_TOKEN" ]; then
    echo "ERROR: Failed to get admin token"
    echo "Make sure admin user exists. Run: cd backend && perl create-admin.pl"
    exit 1
fi

echo "Admin token: $ADMIN_TOKEN"
echo ""

# Test 2: Access admin endpoint as admin
echo "Test 2: Access admin endpoint with admin credentials"
echo "-----------------------------------------------------"
ADMIN_DATA=$(curl -s -X GET "$API_URL/admin/users" \
  -H "Authorization: Bearer $ADMIN_TOKEN")

echo "Response: $ADMIN_DATA"
echo ""

# Test 3: Create a regular user
echo "Test 3: Create a regular user"
echo "------------------------------"
USER_RESPONSE=$(curl -s -X POST "$API_URL/auth/signup" \
  -H "Content-Type: application/json" \
  -d '{"email":"testuser@rit.edu","password":"test123","name":"Test User"}')

echo "Response: $USER_RESPONSE"

# Extract user token
USER_TOKEN=$(echo $USER_RESPONSE | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
echo "User token: $USER_TOKEN"
echo ""

# Test 4: Try to access admin endpoint as regular user
echo "Test 4: Try to access admin endpoint as regular user (should fail)"
echo "-------------------------------------------------------------------"
FORBIDDEN_RESPONSE=$(curl -s -X GET "$API_URL/admin/users" \
  -H "Authorization: Bearer $USER_TOKEN")

echo "Response: $FORBIDDEN_RESPONSE"
echo ""

# Test 5: Try to access admin endpoint without authentication
echo "Test 5: Try to access admin endpoint without authentication (should fail)"
echo "--------------------------------------------------------------------------"
UNAUTH_RESPONSE=$(curl -s -X GET "$API_URL/admin/users")

echo "Response: $UNAUTH_RESPONSE"
echo ""

echo "=================================="
echo "Testing Complete!"
echo ""
echo "To test the admin panel UI:"
echo "1. Open http://localhost:8080/login.html in your browser"
echo "2. Login with admin@rit.edu / admin123"
echo "3. Click the 'Admin Panel' button on the home page"
