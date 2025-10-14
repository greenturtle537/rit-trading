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
INSERT OR IGNORE INTO categories (name, table_name, description) VALUES
    ('electronics', 'electronics', 'Computers, phones, TVs, and other electronics'),
    ('furniture', 'furniture', 'Tables, chairs, couches, beds, and home furniture'),
    ('cars & trucks', 'cars_trucks', 'Automobiles, trucks, and other vehicles'),
    ('books', 'books', 'Books, magazines, and reading materials'),
    ('free stuff', 'free_stuff', 'Items being given away for free');

-- Electronics listings
CREATE TABLE IF NOT EXISTS electronics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2),
    location TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Furniture listings
CREATE TABLE IF NOT EXISTS furniture (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2),
    location TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Cars & Trucks listings
CREATE TABLE IF NOT EXISTS cars_trucks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2),
    location TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Books listings
CREATE TABLE IF NOT EXISTS books (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2),
    location TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Free Stuff listings
CREATE TABLE IF NOT EXISTS free_stuff (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2),
    location TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
