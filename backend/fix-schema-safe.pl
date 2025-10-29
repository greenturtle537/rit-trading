#!/usr/bin/env perl
use strict;
use warnings;
use DBI;
use File::Copy;
use POSIX qw(strftime);

# Configuration
my $DB_PATH = $ENV{'DB_PATH'} || 'rit-trading.db';
my $DRY_RUN = $ENV{'DRY_RUN'} || 0;
my $AUTO_BACKUP = $ENV{'AUTO_BACKUP'} // 1;  # Default to creating backup

print "=" x 70 . "\n";
print "DATABASE SCHEMA MIGRATION TOOL\n";
print "=" x 70 . "\n";
print "Database: $DB_PATH\n";
print "Mode: " . ($DRY_RUN ? "DRY-RUN (no changes will be made)" : "LIVE (will modify database)") . "\n";
print "Auto-backup: " . ($AUTO_BACKUP ? "ENABLED" : "DISABLED") . "\n";
print "=" x 70 . "\n\n";

# Check if database exists
unless (-f $DB_PATH) {
    die "ERROR: Database file not found: $DB_PATH\n";
}

# Create backup if enabled
if ($AUTO_BACKUP && !$DRY_RUN) {
    my $timestamp = strftime("%Y%m%d_%H%M%S", localtime);
    my $backup_path = "$DB_PATH.migration-backup.$timestamp";
    
    print "Creating backup...\n";
    copy($DB_PATH, $backup_path) or die "FATAL: Could not create backup: $!\n";
    print "  [OK] Backup created: $backup_path\n\n";
}

# Connect to database with transactions disabled for inspection
my $dbh = DBI->connect("dbi:SQLite:dbname=$DB_PATH", "", "", {
    RaiseError => 1,
    AutoCommit => 1,
    sqlite_unicode => 1,
}) || die "Cannot connect to database: $DBI::errstr";

# Get all category tables from categories table
print "Reading category tables...\n";
my $categories_sth = $dbh->prepare("SELECT table_name FROM categories");
$categories_sth->execute();

my @tables;
while (my ($table) = $categories_sth->fetchrow_array) {
    push @tables, $table;
}
print "  Found " . scalar(@tables) . " category tables\n\n";

if (!@tables) {
    print "No tables to check. Exiting.\n";
    exit 0;
}

# Define required columns
my @required_columns = qw(id user_id title description price location contact_email contact_phone created_at last_edited_at);

# First pass: Check what needs to be done
my %tables_to_fix;
my $total_records = 0;

print "Analyzing tables...\n";
print "-" x 70 . "\n";

foreach my $table (@tables) {
    print "Checking: $table\n";
    
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
    
    # Get record count
    my $count_sth = $dbh->prepare("SELECT COUNT(*) FROM $table");
    $count_sth->execute();
    my ($count) = $count_sth->fetchrow_array();
    
    if (@missing) {
        print "  [WARN] Missing columns: " . join(", ", @missing) . "\n";
        print "  [INFO] Contains $count records\n";
        $tables_to_fix{$table} = {
            missing => \@missing,
            count => $count,
        };
        $total_records += $count;
    } else {
        print "  [OK] All required columns present ($count records)\n";
    }
}

print "-" x 70 . "\n\n";

# Summary
my $tables_needing_fix = scalar(keys %tables_to_fix);
if ($tables_needing_fix == 0) {
    print "✓ All tables have correct schema. No migration needed.\n";
    $dbh->disconnect();
    exit 0;
}

print "MIGRATION SUMMARY:\n";
print "  Tables needing fix: $tables_needing_fix\n";
print "  Total records to migrate: $total_records\n";
print "\n";

if ($DRY_RUN) {
    print "DRY-RUN MODE: The following changes would be made:\n\n";
    foreach my $table (sort keys %tables_to_fix) {
        print "  • $table:\n";
        print "    - Drop existing table\n";
        print "    - Create new table with all required columns\n";
        print "    - Restore " . $tables_to_fix{$table}{count} . " records\n";
        print "    - Missing columns will be set to defaults (user_id=1)\n";
    }
    print "\nTo execute this migration, run without DRY_RUN:\n";
    print "  perl fix-schema-safe.pl\n\n";
    $dbh->disconnect();
    exit 0;
}

# Confirm before proceeding
print "⚠️  WARNING: This will modify your database!\n";
print "⚠️  Make sure you have a backup before proceeding.\n\n";
print "Do you want to continue? (yes/no): ";
my $confirm = <STDIN>;
chomp($confirm);

unless ($confirm eq 'yes') {
    print "Migration cancelled by user.\n";
    $dbh->disconnect();
    exit 0;
}

print "\n" . "=" x 70 . "\n";
print "STARTING MIGRATION\n";
print "=" x 70 . "\n\n";

# Second pass: Fix tables
my $fixed_count = 0;
my $error_count = 0;

foreach my $table (sort keys %tables_to_fix) {
    print "Migrating table: $table\n";
    
    # Use transaction for each table
    eval {
        $dbh->begin_work;
        
        # Get existing data
        my $data_sth = $dbh->prepare("SELECT * FROM $table");
        $data_sth->execute();
        my @existing_data;
        while (my $row = $data_sth->fetchrow_hashref) {
            push @existing_data, $row;
        }
        print "  [1/4] Loaded " . scalar(@existing_data) . " existing records into memory\n";
        
        # Drop old table
        $dbh->do("DROP TABLE $table");
        print "  [2/4] Dropped old table\n";
        
        # Create new table with correct schema
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
        print "  [3/4] Created new table with correct schema\n";
        
        # Restore data
        if (@existing_data) {
            my $insert_sth = $dbh->prepare(qq{
                INSERT INTO $table (id, user_id, title, description, price, location, contact_email, contact_phone, created_at, last_edited_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            });
            
            my $default_count = 0;
            foreach my $row (@existing_data) {
                # Set default user_id to 1 if missing
                my $user_id = $row->{user_id} || 1;
                if (!$row->{user_id}) {
                    $default_count++;
                }
                
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
            
            print "  [4/4] Restored " . scalar(@existing_data) . " records";
            if ($default_count > 0) {
                print " ($default_count had user_id set to default value 1)";
            }
            print "\n";
        } else {
            print "  [4/4] No data to restore (table was empty)\n";
        }
        
        # Reset autoincrement sequence
        if (@existing_data) {
            my $max_id = $existing_data[-1]{id} || 0;
            $dbh->do("UPDATE sqlite_sequence SET seq = $max_id WHERE name = '$table'");
        }
        
        $dbh->commit;
        print "  [OK] Migration successful!\n\n";
        $fixed_count++;
        
    };
    
    if ($@) {
        print "  [ERROR] Migration failed: $@\n";
        print "  [INFO] Rolling back changes for this table...\n";
        eval { $dbh->rollback; };
        print "  [WARN] Table may be in inconsistent state!\n\n";
        $error_count++;
    }
}

$dbh->disconnect();

print "=" x 70 . "\n";
print "MIGRATION COMPLETE\n";
print "=" x 70 . "\n";
print "Tables fixed: $fixed_count\n";
print "Errors: $error_count\n";

if ($error_count > 0) {
    print "\n⚠️  WARNING: Some tables failed to migrate!\n";
    print "Check the output above for details.\n";
    print "You may need to restore from backup.\n";
    exit 1;
} else {
    print "\n✓ All tables successfully migrated!\n";
    print "\nNext steps:\n";
    print "  1. Verify schema: ./monitor.sh schema\n";
    print "  2. Check data: ./monitor.sh stats\n";
    print "  3. Restart server: sudo systemctl restart rit-trading\n";
    print "  4. Test functionality\n";
    exit 0;
}
