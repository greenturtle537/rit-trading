#!/usr/bin/env perl
use strict;
use warnings;
use DBI;

# Configuration
my $DB_PATH = 'rit-trading.db';

# Get command line arguments
if (@ARGV < 2) {
    print "Usage: perl set-user-role.pl <email> <role>\n";
    print "Roles: user, moderator, admin\n";
    print "\nExample:\n";
    print "  perl set-user-role.pl admin\@rit.edu admin\n";
    exit 1;
}

my ($email, $role) = @ARGV;

# Validate role
unless ($role =~ /^(user|moderator|admin)$/) {
    print "Error: Invalid role '$role'\n";
    print "Valid roles: user, moderator, admin\n";
    exit 1;
}

# Connect to database
my $dbh = DBI->connect("dbi:SQLite:dbname=$DB_PATH", "", "", {
    RaiseError => 1,
    AutoCommit => 1,
}) || die "Cannot connect to database: $DBI::errstr";

# Check if user exists
my ($user_id, $current_name, $current_role) = $dbh->selectrow_array(
    "SELECT id, name, user_role FROM users WHERE email = ?",
    {},
    $email
);

unless ($user_id) {
    print "Error: User with email '$email' not found\n";
    $dbh->disconnect();
    exit 1;
}

# Update user role
$dbh->do(
    "UPDATE users SET user_role = ? WHERE id = ?",
    {},
    $role,
    $user_id
);

print "Successfully updated user role:\n";
print "  Email: $email\n";
print "  Name: $current_name\n";
print "  Previous role: $current_role\n";
print "  New role: $role\n";

$dbh->disconnect();
