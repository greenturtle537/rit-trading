#!/usr/bin/env perl
use strict;
use warnings;
use DBI;

my $DB_PATH = 'rit-trading.db';
my $SCHEMA_FILE = 'schema-structure.sql';
my $TEST_DATA_FILE = 'test-data.sql';

# Parse command line arguments
my $mode = $ARGV[0] || 'prod';  # Default to prod (structure only)

print "Initializing database in $mode mode...\n";

# Function to execute SQL file
sub execute_sql_file {
    my ($file) = @_;
    
    if (! -f $file) {
        die "SQL file not found: $file\n";
    }
    
    # Use sqlite3 command line tool if available
    if (system("which sqlite3 > /dev/null 2>&1") == 0) {
        print "Executing $file using sqlite3...\n";
        system("sqlite3 $DB_PATH < $file");
        if ($? != 0) {
            die "Failed to execute $file with sqlite3\n";
        }
    } else {
        # Fallback to Perl DBI
        print "sqlite3 not found, using Perl DBI for $file...\n";
        
        # Read schema file
        open(my $fh, '<', $file) or die "Cannot open $file: $!";
        my $sql = do { local $/; <$fh> };
        close($fh);
        
        # Connect to database
        my $dbh = DBI->connect("dbi:SQLite:dbname=$DB_PATH", "", "", {
            RaiseError => 0,
            PrintError => 0,
            AutoCommit => 1,
            sqlite_unicode => 1,
        }) or die "Cannot connect to database: $DBI::errstr";
        
        # Execute SQL
        $dbh->do($sql) or warn "Some statements may have failed: " . $dbh->errstr;
        
        $dbh->disconnect();
    }
}

# Always execute structure file (safe for both test and prod)
print "\n[1/", ($mode eq 'test' ? '2' : '1'), "] Creating database structure...\n";
execute_sql_file($SCHEMA_FILE);
print "Database structure initialized successfully!\n";

# Execute test data only in test mode
if ($mode eq 'test') {
    print "\n[2/2] Loading test data...\n";
    execute_sql_file($TEST_DATA_FILE);
    print "Test data loaded successfully!\n";
} else {
    print "\nProduction mode: Skipping test data.\n";
}

# Verify setup - list categories and their tables
my $dbh = DBI->connect("dbi:SQLite:dbname=$DB_PATH", "", "", {
    RaiseError => 1,
    AutoCommit => 1,
    sqlite_unicode => 1,
}) or die "Cannot connect to database: $DBI::errstr";

print "\nCategories:\n";
my $sth = $dbh->prepare("SELECT name, table_name FROM categories ORDER BY name");
$sth->execute();

while (my ($name, $table_name) = $sth->fetchrow_array) {
    my ($count) = $dbh->selectrow_array("SELECT COUNT(*) FROM $table_name");
    $count //= 0;
    printf("  - %-20s (table: %-15s) %d items\n", $name, $table_name, $count);
}

$dbh->disconnect();
print "\nDatabase initialization complete!\n";
