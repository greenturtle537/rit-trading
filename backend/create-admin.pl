#!/usr/bin/env perl
use strict;
use warnings;
use DBI;
use Digest::SHA qw(sha256_hex);

# Configuration
my $DB_PATH = 'rit-trading.db';

# Admin user details
my $email = 'admin@rit.edu';
my $password = 'admin123';
my $name = 'Admin User';
my $role = 'admin';

# Generate authentication token
sub generate_token {
    my $random = join('', map { sprintf("%02x", int(rand(256))) } 1..32);
    return sha256_hex($random . time() . rand());
}

# Connect to database
my $dbh = DBI->connect("dbi:SQLite:dbname=$DB_PATH", "", "", {
    RaiseError => 1,
    AutoCommit => 1,
}) || die "Cannot connect to database: $DBI::errstr";

# Check if admin user already exists
my ($existing_id) = $dbh->selectrow_array(
    "SELECT id FROM users WHERE email = ?",
    {},
    $email
);

if ($existing_id) {
    print "Admin user already exists!\n";
    print "Email: $email\n";
    print "Updating to admin role...\n";
    
    $dbh->do(
        "UPDATE users SET user_role = ? WHERE email = ?",
        {},
        $role,
        $email
    );
    
    print "User updated successfully!\n";
} else {
    # Generate authentication token
    my $token = generate_token();
    
    # Insert new admin user
    my $sth = $dbh->prepare(qq{
        INSERT INTO users (email, password, name, auth_token, user_role)
        VALUES (?, ?, ?, ?, ?)
    });
    
    $sth->execute($email, $password, $name, $token, $role);
    
    print "Admin user created successfully!\n";
    print "Email: $email\n";
    print "Password: $password\n";
    print "Role: $role\n";
    print "\nYou can now login with these credentials.\n";
}

$dbh->disconnect();
