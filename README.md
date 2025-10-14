# RIT Trading

A classifieds/trading platform for the RIT community, built with Perl backend and vanilla JavaScript frontend.

## Features

- Browse listings by category (electronics, furniture, cars & trucks, books, free stuff)
- User authentication with secure token-based system
- Post new listings (requires login)
- Simple, lightweight design

## Architecture

### Backend (Perl)
- **Server**: `backend/server.pl` - HTTP daemon serving REST API
- **Database**: SQLite (`backend/rit-trading.db`)
- **Schema**: `backend/schema-structure.sql`

### Frontend (HTML/JS)
- `frontend/index.html` - Main category listing page
- `frontend/login.html` - User login and signup
- `frontend/ad.html` - Create new listings
- `frontend/category.html` - View listings in a category
- `frontend/item.html` - View individual listing details

## Authentication System

### User Roles

The system supports three levels of user privileges:

- **user** (default) - Regular users who can browse and post listings
- **moderator** - Elevated privileges (future: can moderate content, flag listings)
- **admin** - Highest privileges (future: full system administration)

All new signups are assigned the **user** role by default. Roles are stored in the database and returned with authentication responses.

### How It Works

The application uses a **token-based authentication system** to secure user actions:

1. **User Signup** (`POST /api/auth/signup`)
   - User provides: email, password, name
   - Server assigns default role: **user**
   - Server generates a random SHA-256 token
   - Token stored in database `users.auth_token` field
   - Returns: user info (including role) + token

2. **User Login** (`POST /api/auth/login`)
   - User provides: email, password (plaintext for now)
   - Server validates credentials
   - Generates NEW random token on each login
   - Updates database with new token
   - Returns: user info (including role) + token

3. **Token Storage (Frontend)**
   - Token stored in browser `localStorage`
   - Persists across page reloads
   - Cleared on logout

4. **Authenticated Requests**
   - Protected endpoints require `Authorization` header
   - Format: `Authorization: Bearer <token>`
   - Server validates token against database
   - Returns 401 Unauthorized if token invalid/missing

### Protected Endpoints

- ✅ `POST /api/listings/:category` - Create new listing (requires auth)

### Public Endpoints (No Auth Required)

- ✅ `GET /api/categories` - List all categories
- ✅ `GET /api/listings/:category` - View listings in category
- ✅ `GET /api/:category/:id` - View single listing
- ✅ `POST /api/auth/signup` - Create account
- ✅ `POST /api/auth/login` - Login

### Security Notes

⚠️ **Current Implementation (Development Only)**:
- Passwords stored in **plaintext** (not hashed)
- No HTTPS (tokens sent over HTTP)
- No token expiration
- No rate limiting

🔒 **For Production**, implement:
- Password hashing (bcrypt, Argon2)
- HTTPS/TLS encryption
- Token expiration and refresh tokens
- Session management
- Rate limiting
- Input validation and sanitization

## API Endpoints

### Authentication

#### POST /api/auth/signup
Create a new user account.

**Request:**
```json
{
  "email": "user@rit.edu",
  "password": "mypassword",
  "name": "John Doe"
}
```

**Response:**
```json
{
  "success": 1,
  "user": {
    "id": 1,
    "email": "user@rit.edu",
    "name": "John Doe",
    "role": "user"
  },
  "token": "a1b2c3d4e5f6..."
}
```

#### POST /api/auth/login
Login to existing account.

**Request:**
```json
{
  "email": "user@rit.edu",
  "password": "mypassword"
}
```

**Response:**
```json
{
  "success": 1,
  "user": {
    "id": 1,
    "email": "user@rit.edu",
    "name": "John Doe",
    "role": "user"
  },
  "token": "x9y8z7w6v5u4..."
}
```

### Listings

#### GET /api/categories
Get all categories with listing counts.

**Response:**
```json
[
  {
    "id": 1,
    "name": "electronics",
    "table_name": "electronics",
    "description": "Computers, phones, TVs, and other electronics",
    "listing_count": 5
  }
]
```

#### GET /api/listings/:category
Get all listings in a category.

**Response:**
```json
[
  {
    "id": 1,
    "title": "iPhone 12",
    "description": "Gently used",
    "price": 400.00,
    "location": "Campus Center",
    "contact_email": "seller@rit.edu",
    "contact_phone": "555-1234",
    "created_at": "2025-10-14 10:30:00"
  }
]
```

#### POST /api/listings/:category
Create a new listing. **Requires authentication.**

**Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request:**
```json
{
  "title": "MacBook Pro 2020",
  "description": "16GB RAM, 512GB SSD",
  "price": 1200.00,
  "location": "Dorm Building",
  "contact_email": "seller@rit.edu",
  "contact_phone": "555-5678"
}
```

**Response:**
```json
{
  "id": 42
}
```

## Setup

### Prerequisites
- Perl 5.x
- SQLite3
- Perl modules: DBI, DBD::SQLite, HTTP::Daemon, JSON, Digest::SHA

### Install Perl Dependencies
```bash
cd backend
cpanm --installdeps .
```

### Initialize Database
```bash
cd backend
perl init-db.pl
```

### Start Server
```bash
cd backend
perl server.pl
```

Server runs on http://localhost:3000

### Access Frontend
Open `frontend/index.html` in a web browser, or use a local web server:

```bash
cd frontend
python -m http.server 8080
# Open http://localhost:8080
```

## Development

### Database Reset
```bash
cd backend
rm -f rit-trading.db
perl init-db.pl
```

### Database Inspection
```bash
cd backend
sqlite3 rit-trading.db
.schema
SELECT * FROM users;
SELECT * FROM electronics;
```

### User Role Management

To promote a user to moderator or admin:

```bash
cd backend
perl set-user-role.pl user@rit.edu moderator
# or
perl set-user-role.pl admin@rit.edu admin
```

To demote a user back to regular user:

```bash
cd backend
perl set-user-role.pl user@rit.edu user
```

Check all users and their roles:

```bash
cd backend
sqlite3 rit-trading.db "SELECT email, name, user_role FROM users;"
```

## License

For educational purposes at RIT.
