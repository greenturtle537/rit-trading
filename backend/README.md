# RIT Trading Backend

Simple SQLite-based backend for the RIT Trading marketplace, written in Perl.

## Quick Start (Recommended)

Use the deployment script for easy setup:

```bash
# Test environment (clears existing database, starts server)
./deploy.sh test

# Production environment (keeps existing data)
./deploy.sh prod
```

## Manual Setup

1. Install Perl dependencies:
```bash
cpanm --installdeps .
```

Or install individually:
```bash
cpanm DBI DBD::SQLite HTTP::Daemon JSON URI
```

2. Initialize the database:

**Production (structure only, no test data):**
```bash
perl init-db.pl prod
```

**Test (structure + test data):**
```bash
perl init-db.pl test
```

3. Start the server:
```bash
perl server.pl
```

The server will run on `http://localhost:3000`

## Deployment Script

The `deploy.sh` script handles complete setup and deployment:

**Test Mode** (`./deploy.sh test`):
- Clears existing database
- Installs dependencies
- Runs `init-db.pl test` (structure + sample data)
- Verifies database structure
- Offers to start the test server
- Loads dummy listings for testing

**Production Mode** (`./deploy.sh prod`):
- Backs up existing database
- Installs dependencies
- Runs `init-db.pl prod` (structure only, preserves existing data)
- Verifies database structure
- Does NOT auto-start server
- Does NOT load test data

The script includes:
- Dependency checking (Perl, sqlite3)
- Automatic Perl module installation
- Database backup before changes
- Colored output for easy reading
- Error handling and validation

## User Management

### Setting User Roles

Use the `set-user-role.pl` script to change a user's role:

```bash
perl set-user-role.pl <email> <role>
```

**Available roles:**
- `user` - Regular user (default for new signups)
- `moderator` - Moderator privileges
- `admin` - Administrator privileges

**Examples:**

Make a user an administrator:
```bash
perl set-user-role.pl admin@rit.edu admin
```

Make a user a moderator:
```bash
perl set-user-role.pl user@rit.edu moderator
```

Change back to regular user:
```bash
perl set-user-role.pl user@rit.edu user
```

The script will:
- Verify the user exists in the database
- Validate the role is valid
- Update the user's role
- Display confirmation with old and new role

## Database Schema

The database is configured via `schema.sql` which includes:

- **categories** - Product categories
- **listings** - Marketplace listings
- **images** - Listing images (optional)

## Database Schema

The database is configured via SQL files:

- **`schema-structure.sql`** - Database structure only (tables and categories)
  - Safe to run in production
  - Uses `CREATE TABLE IF NOT EXISTS` - won't overwrite existing data
  - Defines the categories table and all item tables
  
- **`test-data.sql`** - Sample/dummy data for testing
  - Only for development/testing environments
  - Contains sample listings for each category
  - Uses `INSERT OR IGNORE` - won't duplicate data

### Database Structure:

- **categories** - Master table listing all available categories with their corresponding data table names
- **electronics** - Electronics listings table
- **furniture** - Furniture listings table
- **cars_trucks** - Cars & trucks listings table
- **books** - Books listings table
- **free_stuff** - Free items listings table

Each category in the `categories` table has:
- `id` - Category ID
- `name` - Display name (e.g., "cars & trucks")
- `table_name` - Database table name (e.g., "cars_trucks")
- `description` - Category description

## API Endpoints

- `GET /api/categories` - Get all categories with listing counts
  - Returns: Array of category objects with `id`, `name`, `table_name`, `description`, and `listing_count`
- `GET /api/listings/:category` - Get all listings for a category (use table_name, e.g. /api/listings/electronics)
- `GET /api/:category/:id` - Get a specific listing from a category
- `POST /api/listings/:category` - Create a new listing in a category

## Categories

The following categories are available (from the `categories` table):
- `electronics` → table: `electronics`
- `furniture` → table: `furniture`
- `cars & trucks` → table: `cars_trucks`
- `books` → table: `books`
- `free stuff` → table: `free_stuff`

Each category has its own dedicated table in the database.

## Example Usage

Get all categories:
```bash
curl http://localhost:3000/api/categories
```

Get electronics listings:
```bash
curl http://localhost:3000/api/listings/electronics
```

Get a specific listing:
```bash
curl http://localhost:3000/api/electronics/1
```

Create a listing in the books category:
```bash
curl -X POST http://localhost:3000/api/listings/books \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Python Programming Book",
    "description": "Great condition textbook",
    "price": 35.00,
    "location": "Rochester, NY",
    "contact_email": "test@example.com"
  }'
```
