-- RIT Trading Test Data
-- This file contains sample/dummy data for testing purposes only
-- DO NOT run this in production

-- Insert sample electronics data
INSERT OR IGNORE INTO electronics (title, description, price, location, contact_email) VALUES
    ('iPhone 12 Pro - Excellent Condition', 'Barely used iPhone 12 Pro, 256GB, includes charger and case', 599.99, 'Rochester, NY', 'seller1@example.com'),
    ('Gaming Laptop - RTX 3070', 'High-performance gaming laptop, perfect for students', 1200.00, 'Rochester, NY', 'seller2@example.com'),
    ('Sony Headphones WH-1000XM4', 'Noise cancelling, like new condition', 249.99, 'Rochester, NY', 'seller3@example.com');

-- Insert sample furniture data
INSERT OR IGNORE INTO furniture (title, description, price, location, contact_email) VALUES
    ('Comfortable Couch - Must Go!', 'Moving sale, great condition L-shaped couch', 150.00, 'Rochester, NY', 'seller4@example.com'),
    ('Oak Dining Table', 'Solid oak table, seats 6, excellent condition', 300.00, 'Rochester, NY', 'seller5@example.com');

-- Insert sample cars & trucks data
INSERT OR IGNORE INTO cars_trucks (title, description, price, location, contact_email) VALUES
    ('Honda Civic 2018', 'Well maintained, low mileage, one owner', 14500.00, 'Rochester, NY', 'seller6@example.com'),
    ('Ford F-150 2015', 'Reliable work truck, new tires', 18000.00, 'Rochester, NY', 'seller7@example.com');

-- Insert sample books data
INSERT OR IGNORE INTO books (title, description, price, location, contact_email) VALUES
    ('Calculus Textbook', 'Like new, latest edition', 45.00, 'RIT Campus', 'student@rit.edu'),
    ('Computer Science Textbooks', 'Bundle of 5 CS textbooks from various courses', 120.00, 'RIT Campus', 'student2@rit.edu');

-- Insert sample free stuff data
INSERT OR IGNORE INTO free_stuff (title, description, price, location, contact_email) VALUES
    ('Free Moving Boxes', 'About 20 sturdy moving boxes, free to pick up', 0.00, 'Rochester, NY', 'seller8@example.com'),
    ('Old TV Stand', 'Wooden TV stand, could use some work but free', 0.00, 'Rochester, NY', 'seller9@example.com');
