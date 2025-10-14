-- RIT Trading Test Data
-- This file contains sample/dummy data for testing purposes only
-- DO NOT run this in production

-- Create test user (sam@glitchtech.top)
INSERT OR IGNORE INTO users (email, password, name, user_role) VALUES
    ('sam@glitchtech.top', 'password123', 'Sam Test User', 'admin');

-- Insert sample electronics data
INSERT OR IGNORE INTO electronics (user_id, title, description, price, location, contact_email) 
SELECT id, 'iPhone 12 Pro - Excellent Condition', 'Barely used iPhone 12 Pro, 256GB, includes charger and case', 599.99, 'Rochester, NY', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

INSERT OR IGNORE INTO electronics (user_id, title, description, price, location, contact_email)
SELECT id, 'Gaming Laptop - RTX 3070', 'High-performance gaming laptop, perfect for students', 1200.00, 'Rochester, NY', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

INSERT OR IGNORE INTO electronics (user_id, title, description, price, location, contact_email)
SELECT id, 'Sony Headphones WH-1000XM4', 'Noise cancelling, like new condition', 249.99, 'Rochester, NY', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

-- Insert sample furniture data
INSERT OR IGNORE INTO furniture (user_id, title, description, price, location, contact_email)
SELECT id, 'Comfortable Couch - Must Go!', 'Moving sale, great condition L-shaped couch', 150.00, 'Rochester, NY', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

INSERT OR IGNORE INTO furniture (user_id, title, description, price, location, contact_email)
SELECT id, 'Oak Dining Table', 'Solid oak table, seats 6, excellent condition', 300.00, 'Rochester, NY', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

-- Insert sample cars & trucks data
INSERT OR IGNORE INTO cars_trucks (user_id, title, description, price, location, contact_email)
SELECT id, 'Honda Civic 2018', 'Well maintained, low mileage, one owner', 14500.00, 'Rochester, NY', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

INSERT OR IGNORE INTO cars_trucks (user_id, title, description, price, location, contact_email)
SELECT id, 'Ford F-150 2015', 'Reliable work truck, new tires', 18000.00, 'Rochester, NY', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

-- Insert sample books data
INSERT OR IGNORE INTO books (user_id, title, description, price, location, contact_email)
SELECT id, 'Calculus Textbook', 'Like new, latest edition', 45.00, 'RIT Campus', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

INSERT OR IGNORE INTO books (user_id, title, description, price, location, contact_email)
SELECT id, 'Computer Science Textbooks', 'Bundle of 5 CS textbooks from various courses', 120.00, 'RIT Campus', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

-- Insert sample free stuff data
INSERT OR IGNORE INTO free_stuff (user_id, title, description, price, location, contact_email)
SELECT id, 'Free Moving Boxes', 'About 20 sturdy moving boxes, free to pick up', 0.00, 'Rochester, NY', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

INSERT OR IGNORE INTO free_stuff (user_id, title, description, price, location, contact_email)
SELECT id, 'Old TV Stand', 'Wooden TV stand, could use some work but free', 0.00, 'Rochester, NY', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

-- Insert sample clothing data
INSERT OR IGNORE INTO clothing (user_id, title, description, price, location, contact_email)
SELECT id, 'Winter Jacket - North Face', 'Mens size L, barely worn, perfect for Rochester winters', 80.00, 'RIT Campus', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

INSERT OR IGNORE INTO clothing (user_id, title, description, price, location, contact_email)
SELECT id, 'Nike Sneakers Size 10', 'Gently used running shoes, great condition', 45.00, 'Rochester, NY', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

-- Insert sample tutoring services data
INSERT OR IGNORE INTO tutoring_services (user_id, title, description, price, location, contact_email)
SELECT id, 'Calculus Tutoring', 'Experienced tutor for Calc I, II, and III. $25/hour', 25.00, 'RIT Campus', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

INSERT OR IGNORE INTO tutoring_services (user_id, title, description, price, location, contact_email)
SELECT id, 'Programming Help - Python/Java', 'CS major offering programming tutoring, all levels welcome', 20.00, 'RIT Campus', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

INSERT OR IGNORE INTO tutoring_services (user_id, title, description, price, location, contact_email)
SELECT id, 'Physics Tutoring', 'PhD student offering physics tutoring for undergrads', 30.00, 'RIT Campus', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

-- Insert sample tech services data
INSERT OR IGNORE INTO tech_services (user_id, title, description, price, location, contact_email)
SELECT id, 'Computer Repair & Upgrades', 'Fast and affordable PC/Mac repair, RAM/SSD upgrades', 50.00, 'Rochester, NY', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

INSERT OR IGNORE INTO tech_services (user_id, title, description, price, location, contact_email)
SELECT id, 'Website Development', 'Custom websites for small businesses and portfolios', 200.00, 'Remote/Rochester', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

-- Insert sample creative services data
INSERT OR IGNORE INTO creative_services (user_id, title, description, price, location, contact_email)
SELECT id, 'Photography Services', 'Headshots, events, portraits - professional quality', 100.00, 'Rochester, NY', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

INSERT OR IGNORE INTO creative_services (user_id, title, description, price, location, contact_email)
SELECT id, 'Graphic Design', 'Logos, flyers, social media graphics', 75.00, 'Remote/Rochester', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

-- Insert sample moving & labor data
INSERT OR IGNORE INTO moving_labor (user_id, title, description, price, location, contact_email)
SELECT id, 'Moving Help Available', 'Strong college student available for moving jobs. $20/hour', 20.00, 'Rochester, NY', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

INSERT OR IGNORE INTO moving_labor (user_id, title, description, price, location, contact_email)
SELECT id, 'Furniture Assembly', 'IKEA assembly expert, fast and reliable', 40.00, 'Rochester, NY', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

-- Insert sample looking for items data
INSERT OR IGNORE INTO looking_for_items (user_id, title, description, price, location, contact_email)
SELECT id, 'Looking for: Mini Fridge', 'Need a mini fridge for dorm room, willing to pay up to $50', 50.00, 'RIT Campus', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

INSERT OR IGNORE INTO looking_for_items (user_id, title, description, price, location, contact_email)
SELECT id, 'Wanted: Bicycle', 'Looking for a used bike in good condition for commuting', 150.00, 'Rochester, NY', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

-- Insert sample looking for services data
INSERT OR IGNORE INTO looking_for_services (user_id, title, description, price, location, contact_email)
SELECT id, 'Need Moving Help - 11/15', 'Moving to new apartment, need 2 people for a few hours', 100.00, 'Rochester, NY', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

INSERT OR IGNORE INTO looking_for_services (user_id, title, description, price, location, contact_email)
SELECT id, 'Looking for Math Tutor', 'Need help with Statistics, flexible schedule', 25.00, 'RIT Campus', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

-- Insert sample looking for housing data
INSERT OR IGNORE INTO looking_for_housing (user_id, title, description, price, location, contact_email)
SELECT id, 'Looking for Roommate', 'Need roommate for 2BR apartment near RIT, $600/month', 600.00, 'Near RIT', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

INSERT OR IGNORE INTO looking_for_housing (user_id, title, description, price, location, contact_email)
SELECT id, 'Seeking Sublet for Spring', 'Looking for sublet Jan-May 2026, budget $500-700/month', 700.00, 'Rochester, NY', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

-- Insert sample job opportunities data
INSERT OR IGNORE INTO job_opportunities (user_id, title, description, price, location, contact_email)
SELECT id, 'Part-time Research Assistant', 'CS department seeking undergrad research assistant, $15/hr', 15.00, 'RIT Campus', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';

INSERT OR IGNORE INTO job_opportunities (user_id, title, description, price, location, contact_email)
SELECT id, 'Looking for Freelance Web Work', 'Full-stack developer seeking freelance projects', 50.00, 'Remote', 'sam@glitchtech.top'
FROM users WHERE email = 'sam@glitchtech.top';
