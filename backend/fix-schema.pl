#!/usr/bin/env perl
use strict;
use warnings;
use DBI;

# Database path
my $DB_PATH = $ENV{'DB_PATH'} || 'rit-trading.db';

print "Checking and fixing database schema...\n";
print "Database: $DB_PATH\n\n";

# Connect to database
my $dbh = DBI->connect("dbi:SQLite:dbname=$DB_PATH", "", "", {
    RaiseError => 1,
    AutoCommit => 1,
    sqlite_unicode => 1,
}) || die "Cannot connect to database: $DBI::errstr";

# Get all category tables from categories table
my $categories_sth = $dbh->prepare("SELECT table_name FROM categories");
$categories_sth->execute();

my @tables;
while (my ($table) = $categories_sth->fetchrow_array) {
    push @tables, $table;
}

# Check each table for required columns
my @required_columns = qw(id user_id title description price location contact_email contact_phone created_at last_edited_at);

foreach my $table (@tables) {
    print "Checking table: $table\n";
    
    # Get existing columns
    my $pragma_sth = $dbh->prepare("PRAGMA table_info($table)");
    eval {
        $pragma_sth->execute();
    };
    
    if ($@) {
        print "  [ERROR] Could not get table info: $@\n";
        next;
    }
    
    my %existing_columns;
    while (my $row = $pragma_sth->fetchrow_hashref) {
        $existing_columns{$row->{name}} = 1;
    }
    
    # Check for missing columns
    my @missing;
    foreach my $col (@required_columns) {
        unless ($existing_columns{$col}) {
            push @missing, $col;
        }
    }
    
    if (@missing) {
        print "  [WARN] Missing columns: " . join(", ", @missing) . "\n";
        print "  [FIX] Recreating table with correct schema...\n";
        
        # Get existing data
        my $data_sth = $dbh->prepare("SELECT * FROM $table");
        $data_sth->execute();
        my @existing_data;
        while (my $row = $data_sth->fetchrow_hashref) {
            push @existing_data, $row;
        }
        
        # Drop and recreate table
        $dbh->do("DROP TABLE $table");
        
        $dbh->do(qq{
            CREATE TABLE $table (
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
            )
        });
        
        # Restore data
        if (@existing_data) {
            print "  [INFO] Restoring " . scalar(@existing_data) . " existing records...\n";
            
            my $insert_sth = $dbh->prepare(qq{
                INSERT INTO $table (id, user_id, title, description, price, location, contact_email, contact_phone, created_at, last_edited_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            });
            
            foreach my $row (@existing_data) {
                # Set default user_id to 1 if missing
                my $user_id = $row->{user_id} || 1;
                
                $insert_sth->execute(
                    $row->{id},
                    $user_id,
                    $row->{title} || '',
                    $row->{description},
                    $row->{price},
                    $row->{location},
                    $row->{contact_email},
                    $row->{contact_phone},
                    $row->{created_at},
                    $row->{last_edited_at}
                );
            }
        }
        
        print "  [OK] Table fixed!\n";
    } else {
        print "  [OK] All columns present\n";
    }
}

$dbh->disconnect();

print "\nSchema check complete!\n";
print "\nTo apply this fix on production server:\n";
print "  cd /glitchtech/rit-trading/backend\n";
print "  perl fix-schema.pl\n";
print "\nOr to specify a different database:\n";
print "  DB_PATH=/path/to/database.db perl fix-schema.pl\n";
