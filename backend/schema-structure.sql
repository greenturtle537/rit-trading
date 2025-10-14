-- RIT Trading Database Schema (Structure Only)
-- This file creates tables and categories but does NOT insert test data

-- Users table (plaintext passwords for now)
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    name TEXT NOT NULL,
    auth_token TEXT UNIQUE,
    user_role TEXT DEFAULT 'user' CHECK(user_role IN ('user', 'moderator', 'admin')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Categories table
CREATE TABLE IF NOT EXISTS categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    table_name TEXT NOT NULL UNIQUE,
    description TEXT
);

-- Insert categories (only if they don't exist)
-- Items For Sale
INSERT OR IGNORE INTO categories (name, table_name, description) VALUES
    ('electronics', 'electronics', 'Computers, phones, TVs, and other electronics'),
    ('furniture', 'furniture', 'Tables, chairs, couches, beds, and home furniture'),
    ('cars & trucks', 'cars_trucks', 'Automobiles, trucks, and other vehicles'),
    ('books', 'books', 'Books, magazines, and reading materials'),
    ('clothing', 'clothing', 'Clothes, shoes, and accessories'),
    ('free stuff', 'free_stuff', 'Items being given away for free');

-- Services For Hire
INSERT OR IGNORE INTO categories (name, table_name, description) VALUES
    ('tutoring services', 'tutoring_services', 'Academic tutoring and teaching services'),
    ('tech services', 'tech_services', 'Computer repair, programming, and IT services'),
    ('creative services', 'creative_services', 'Design, photography, video editing services'),
    ('moving & labor', 'moving_labor', 'Moving help, assembly, and manual labor');

-- Looking For
INSERT OR IGNORE INTO categories (name, table_name, description) VALUES
    ('looking for items', 'looking_for_items', 'Wanted to buy or borrow items'),
    ('looking for services', 'looking_for_services', 'Seeking help or services'),
    ('looking for housing', 'looking_for_housing', 'Roommates, sublets, housing wanted'),
    ('job opportunities', 'job_opportunities', 'Looking for work or employment');

-- Electronics listings
CREATE TABLE IF NOT EXISTS electronics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2),
    location TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_edited_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Furniture listings
CREATE TABLE IF NOT EXISTS furniture (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2),
    location TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_edited_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Cars & Trucks listings
CREATE TABLE IF NOT EXISTS cars_trucks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2),
    location TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_edited_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Books listings
CREATE TABLE IF NOT EXISTS books (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2),
    location TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_edited_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Free Stuff listings
CREATE TABLE IF NOT EXISTS free_stuff (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2),
    location TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_edited_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Clothing listings
CREATE TABLE IF NOT EXISTS clothing (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2),
    location TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_edited_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Tutoring Services listings
CREATE TABLE IF NOT EXISTS tutoring_services (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2),
    location TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_edited_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Tech Services listings
CREATE TABLE IF NOT EXISTS tech_services (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2),
    location TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_edited_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Creative Services listings
CREATE TABLE IF NOT EXISTS creative_services (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2),
    location TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_edited_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Moving & Labor listings
CREATE TABLE IF NOT EXISTS moving_labor (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2),
    location TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_edited_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Looking For Items listings
CREATE TABLE IF NOT EXISTS looking_for_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2),
    location TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_edited_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Looking For Services listings
CREATE TABLE IF NOT EXISTS looking_for_services (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2),
    location TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_edited_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Looking For Housing listings
CREATE TABLE IF NOT EXISTS looking_for_housing (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2),
    location TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_edited_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Job Opportunities listings
CREATE TABLE IF NOT EXISTS job_opportunities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2),
    location TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_edited_at DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
