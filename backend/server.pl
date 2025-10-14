#!/usr/bin/env perl
use strict;
use warnings;
use DBI;
use HTTP::Daemon;
use HTTP::Status;
use JSON;
use URI;

# Configuration
my $PORT = 3000;
my $DB_PATH = 'rit-trading.db';

# Create HTTP daemon
my $daemon = HTTP::Daemon->new(
    LocalPort => $PORT,
    ReuseAddr => 1,
) || die "Failed to create HTTP daemon: $!";

print "Server running at: ", $daemon->url, "\n";
print "API endpoints:\n";
print "  GET  /api/categories - Get all categories with counts\n";
print "  GET  /api/listings/:category - Get listings for a category\n";
print "  GET  /api/:category/:id - Get single listing from category\n";
print "  POST /api/listings/:category - Create new listing in category\n";

# Database connection
sub get_db {
    my $dbh = DBI->connect("dbi:SQLite:dbname=$DB_PATH", "", "", {
        RaiseError => 1,
        AutoCommit => 1,
        sqlite_unicode => 1,
    }) || die "Cannot connect to database: $DBI::errstr";
    return $dbh;
}

# Get all categories with counts
sub get_categories {
    my $dbh = shift;
    
    # Get all categories from categories table
    my $sth = $dbh->prepare("SELECT id, name, table_name, description FROM categories ORDER BY name");
    $sth->execute();
    
    my @categories;
    while (my $row = $sth->fetchrow_hashref) {
        my $table = $row->{table_name};
        
        # Get count for this category's table
        my ($count) = $dbh->selectrow_array("SELECT COUNT(*) FROM $table");
        
        push @categories, {
            id => $row->{id},
            name => $row->{name},
            table_name => $table,
            description => $row->{description},
            listing_count => $count + 0,
        };
    }
    
    return \@categories;
}

# Get table name for a category
sub get_table_for_category {
    my ($dbh, $category) = @_;
    
    # Look up table name in categories table
    my ($table_name) = $dbh->selectrow_array(
        "SELECT table_name FROM categories WHERE table_name = ? OR name = ?",
        {},
        $category, $category
    );
    
    return $table_name;
}

# Get all listings from a category
sub get_listings_by_category {
    my ($dbh, $category) = @_;
    
    my $table = get_table_for_category($dbh, $category);
    return undef unless $table;
    
    my $sth = $dbh->prepare("SELECT * FROM $table ORDER BY created_at DESC");
    $sth->execute();
    
    my @listings;
    while (my $row = $sth->fetchrow_hashref) {
        push @listings, $row;
    }
    
    return \@listings;
}

# Get listing by ID from a category
sub get_listing_by_id {
    my ($dbh, $category, $id) = @_;
    
    my $table = get_table_for_category($dbh, $category);
    return undef unless $table;
    
    my $sth = $dbh->prepare("SELECT * FROM $table WHERE id = ?");
    $sth->execute($id);
    
    return $sth->fetchrow_hashref;
}

# Create new listing in a category
sub create_listing {
    my ($dbh, $category, $data) = @_;
    
    my $table = get_table_for_category($dbh, $category);
    return undef unless $table;
    
    my $sth = $dbh->prepare(qq{
        INSERT INTO $table (title, description, price, location, contact_email, contact_phone)
        VALUES (?, ?, ?, ?, ?, ?)
    });
    
    $sth->execute(
        $data->{title},
        $data->{description},
        $data->{price},
        $data->{location},
        $data->{contact_email},
        $data->{contact_phone}
    );
    
    return { id => $dbh->last_insert_id(undef, undef, $table, undef) };
}

# Send JSON response
sub send_json {
    my ($conn, $status, $data) = @_;
    my $json = encode_json($data);
    my $response = HTTP::Response->new($status);
    $response->header('Content-Type' => 'application/json');
    $response->header('Access-Control-Allow-Origin' => '*');
    $response->header('Access-Control-Allow-Methods' => 'GET, POST, OPTIONS');
    $response->header('Access-Control-Allow-Headers' => 'Content-Type');
    $response->content($json);
    $conn->send_response($response);
}

# Handle requests
while (my $conn = $daemon->accept) {
    while (my $request = $conn->get_request) {
        my $method = $request->method;
        my $path = $request->uri->path;
        my $uri = URI->new($request->uri);
        my %query = $uri->query_form;

        # Handle CORS preflight
        if ($method eq 'OPTIONS') {
            my $response = HTTP::Response->new(RC_OK);
            $response->header('Access-Control-Allow-Origin' => '*');
            $response->header('Access-Control-Allow-Methods' => 'GET, POST, OPTIONS');
            $response->header('Access-Control-Allow-Headers' => 'Content-Type');
            $conn->send_response($response);
            next;
        }

        eval {
            my $dbh = get_db();

            # Route: GET /api/categories
            if ($method eq 'GET' && $path eq '/api/categories') {
                my $categories = get_categories($dbh);
                send_json($conn, RC_OK, $categories);
            }
            # Route: GET /api/listings/:category
            elsif ($method eq 'GET' && $path =~ m{^/api/listings/(\w+)$}) {
                my $category = $1;
                my $listings = get_listings_by_category($dbh, $category);
                if (defined $listings) {
                    send_json($conn, RC_OK, $listings);
                } else {
                    send_json($conn, RC_NOT_FOUND, { error => 'Category not found' });
                }
            }
            # Route: GET /api/:category/:id
            elsif ($method eq 'GET' && $path =~ m{^/api/(\w+)/(\d+)$}) {
                my ($category, $id) = ($1, $2);
                my $listing = get_listing_by_id($dbh, $category, $id);
                if ($listing) {
                    send_json($conn, RC_OK, $listing);
                } else {
                    send_json($conn, RC_NOT_FOUND, { error => 'Listing not found' });
                }
            }
            # Route: POST /api/listings/:category
            elsif ($method eq 'POST' && $path =~ m{^/api/listings/(\w+)$}) {
                my $category = $1;
                my $content = $request->content;
                my $data = decode_json($content);
                my $result = create_listing($dbh, $category, $data);
                if (defined $result) {
                    send_json($conn, RC_CREATED, $result);
                } else {
                    send_json($conn, RC_NOT_FOUND, { error => 'Category not found' });
                }
            }
            # 404 Not Found
            else {
                send_json($conn, RC_NOT_FOUND, { error => 'Not found' });
            }

            $dbh->disconnect();
        };
        if ($@) {
            print STDERR "Error: $@\n";
            send_json($conn, RC_INTERNAL_SERVER_ERROR, { error => 'Internal server error' });
        }
    }
    $conn->close;
    undef($conn);
}
