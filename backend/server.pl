#!/usr/bin/env perl
use strict;
use warnings;
use DBI;
use HTTP::Daemon;
use HTTP::Status;
use JSON;
use URI;
use Digest::SHA qw(sha256_hex);
use POSIX qw(strftime);

# Configuration
my $PORT = 3000;
my $DB_PATH = 'rit-trading.db';
my $LOG_FILE = 'rit-trading.log';
my $LOG_FH;

# Ensure log directory exists and create log file if needed
my $log_dir = '/var/log';
unless (-d $log_dir) {
    mkdir $log_dir or warn "Could not create log directory $log_dir: $!";
}

# Open log file for appending, create if doesn't exist
unless (open($LOG_FH, '>>', $LOG_FILE)) {
    warn "Cannot open log file $LOG_FILE: $! - Logging to STDERR instead";
    # Fall back to STDERR if we can't write to log file
    open($LOG_FH, '>&', \*STDERR) or die "Cannot redirect to STDERR: $!";
}
# Autoflush log file
select((select($LOG_FH), $| = 1)[0]);

# Logging function
sub log_message {
    my ($level, $message) = @_;
    my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime);
    my $log_line = "[$timestamp] [$level] $message\n";
    print $LOG_FH $log_line;
    print STDERR $log_line if $level eq 'ERROR';
}

# Log request
sub log_request {
    my ($method, $path, $status, $client_ip) = @_;
    my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime);
    my $log_line = sprintf("[%s] %s %s - %s - %s\n", 
        $timestamp, $client_ip || 'unknown', $method, $path, $status);
    print $LOG_FH $log_line;
}

# Create HTTP daemon
my $daemon = HTTP::Daemon->new(
    LocalPort => $PORT,
    ReuseAddr => 1,
) || die "Failed to create HTTP daemon: $!";

log_message('INFO', "Server starting on port $PORT");
print "Server running at: ", $daemon->url, "\n";
print "API endpoints:\n";
print "  POST /api/auth/signup - Create new user account\n";
print "  POST /api/auth/login - Login user\n";
print "  GET  /api/categories - Get all categories with counts\n";
print "  GET  /api/listings/:category - Get listings for a category\n";
print "  GET  /api/:category/:id - Get single listing from category\n";
print "  POST /api/listings/:category - Create new listing in category\n";
print "  GET  /api/admin/users - Get all users and their posts (admin/moderator)\n";
print "  POST /api/admin/posts/delete - Delete/redact a post (admin/moderator)\n";
log_message('INFO', "Server started successfully at " . $daemon->url);

# Database connection
sub get_db {
    my $dbh = DBI->connect("dbi:SQLite:dbname=$DB_PATH", "", "", {
        RaiseError => 1,
        AutoCommit => 1,
        sqlite_unicode => 1,
    }) || die "Cannot connect to database: $DBI::errstr";
    return $dbh;
}

# Generate random authentication token
sub generate_token {
    my $random = join('', map { sprintf("%02x", int(rand(256))) } 1..32);
    return sha256_hex($random . time() . rand());
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
    my ($dbh, $category, $data, $user) = @_;
    
    my $table = get_table_for_category($dbh, $category);
    return undef unless $table;
    
    # Default contact_email to user's email if not provided
    my $contact_email = $data->{contact_email} || $user->{email};
    
    my $sth = $dbh->prepare(qq{
        INSERT INTO $table (user_id, title, description, price, location, contact_email, contact_phone)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    });
    
    $sth->execute(
        $user->{id},
        $data->{title},
        $data->{description},
        $data->{price},
        $data->{location},
        $contact_email,
        $data->{contact_phone}
    );
    
    return { id => $dbh->last_insert_id(undef, undef, $table, undef) };
}

# User signup
sub create_user {
    my ($dbh, $data) = @_;
    
    # Validate required fields
    return { error => 'Email is required' } unless $data->{email};
    return { error => 'Password is required' } unless $data->{password};
    return { error => 'Name is required' } unless $data->{name};
    
    # Check if email already exists
    my ($existing) = $dbh->selectrow_array(
        "SELECT id FROM users WHERE email = ?",
        {},
        $data->{email}
    );
    
    if ($existing) {
        return { error => 'Email already registered' };
    }
    
    # Generate authentication token
    my $token = generate_token();
    
    # Default role is 'user', but can be overridden for initial admin setup
    my $role = $data->{user_role} || 'user';
    
    # Validate role
    unless ($role =~ /^(user|moderator|admin)$/) {
        return { error => 'Invalid user role' };
    }
    
    # Insert new user (plaintext password for now)
    my $sth = $dbh->prepare(qq{
        INSERT INTO users (email, password, name, auth_token, user_role)
        VALUES (?, ?, ?, ?, ?)
    });
    
    eval {
        $sth->execute(
            $data->{email},
            $data->{password},  # Storing plaintext password
            $data->{name},
            $token,
            $role
        );
    };
    
    if ($@) {
        return { error => "Failed to create user: $@" };
    }
    
    my $user_id = $dbh->last_insert_id(undef, undef, 'users', undef);
    
    return {
        success => 1,
        user => {
            id => $user_id,
            email => $data->{email},
            name => $data->{name},
            role => $role
        },
        token => $token
    };
}

# User login
sub login_user {
    my ($dbh, $data) = @_;
    
    # Validate required fields
    return { error => 'Email is required' } unless $data->{email};
    return { error => 'Password is required' } unless $data->{password};
    
    # Find user by email
    my $sth = $dbh->prepare("SELECT id, email, password, name, user_role FROM users WHERE email = ?");
    $sth->execute($data->{email});
    my $user = $sth->fetchrow_hashref;
    
    unless ($user) {
        return { error => 'Invalid email or password' };
    }
    
    # Check password (plaintext comparison for now)
    unless ($user->{password} eq $data->{password}) {
        return { error => 'Invalid email or password' };
    }
    
    # Generate new authentication token
    my $token = generate_token();
    
    # Update user's token in database
    $dbh->do("UPDATE users SET auth_token = ? WHERE id = ?", {}, $token, $user->{id});
    
    # Return user info (without password) and token
    return {
        success => 1,
        user => {
            id => $user->{id},
            email => $user->{email},
            name => $user->{name},
            role => $user->{user_role}
        },
        token => $token
    };
}

# Verify authentication token
sub verify_token {
    my ($dbh, $token) = @_;
    
    return undef unless $token;
    
    # Look up user by token
    my $sth = $dbh->prepare("SELECT id, email, name, user_role FROM users WHERE auth_token = ?");
    $sth->execute($token);
    my $user = $sth->fetchrow_hashref;
    
    return $user;
}

# Extract token from Authorization header
sub get_token_from_header {
    my ($request) = @_;
    
    my $auth_header = $request->header('Authorization');
    return undef unless $auth_header;
    
    # Support both "Bearer TOKEN" and just "TOKEN"
    if ($auth_header =~ /^Bearer\s+(.+)$/i) {
        return $1;
    }
    
    return $auth_header;
}

# Get all users with their posts (admin only)
sub get_all_users_with_posts {
    my ($dbh) = @_;
    
    # Get all users
    my $users_sth = $dbh->prepare("SELECT id, email, name, user_role, created_at FROM users ORDER BY created_at DESC");
    $users_sth->execute();
    
    my @users;
    while (my $user = $users_sth->fetchrow_hashref) {
        my @posts;
        
        # Get all category tables
        my $cat_sth = $dbh->prepare("SELECT table_name FROM categories");
        $cat_sth->execute();
        
        # Search for posts by this user in all category tables
        while (my ($table_name) = $cat_sth->fetchrow_array) {
            # Find posts by user_id
            my $posts_sth = $dbh->prepare("SELECT * FROM $table_name WHERE user_id = ? ORDER BY created_at DESC");
            eval {
                $posts_sth->execute($user->{id});
                
                while (my $post = $posts_sth->fetchrow_hashref) {
                    # Add category information to the post
                    $post->{category} = $table_name;
                    push @posts, $post;
                }
            };
            # Silently continue if there's an error
        }
        
        # Add posts to user object
        $user->{posts} = \@posts;
        push @users, $user;
    }
    
    return \@users;
}

# Delete/redact a post (admin only)
sub delete_post {
    my ($dbh, $category, $post_id) = @_;
    
    my $table = get_table_for_category($dbh, $category);
    return { error => 'Category not found' } unless $table;
    
    # Check if post exists
    my $sth = $dbh->prepare("SELECT id FROM $table WHERE id = ?");
    $sth->execute($post_id);
    my $post = $sth->fetchrow_hashref;
    
    unless ($post) {
        return { error => 'Post not found' };
    }
    
    # Redact the post content
    my $update_sth = $dbh->prepare(qq{
        UPDATE $table 
        SET title = '[DELETED]',
            description = 'This post was deleted by moderation',
            price = 0,
            contact_email = '',
            contact_phone = ''
        WHERE id = ?
    });
    
    eval {
        $update_sth->execute($post_id);
    };
    
    if ($@) {
        return { error => "Failed to delete post: $@" };
    }
    
    return { 
        success => 1, 
        message => 'Post has been deleted and redacted',
        post_id => $post_id,
        category => $category
    };
}

# Update a post (user owner only)
sub update_post {
    my ($dbh, $category, $post_id, $data, $user) = @_;
    
    my $table = get_table_for_category($dbh, $category);
    return { error => 'Category not found' } unless $table;
    
    # Check if post exists and belongs to user
    my $sth = $dbh->prepare("SELECT id, user_id FROM $table WHERE id = ?");
    $sth->execute($post_id);
    my $post = $sth->fetchrow_hashref;
    
    unless ($post) {
        return { error => 'Post not found' };
    }
    
    # Verify ownership
    unless ($post->{user_id} == $user->{id}) {
        return { error => 'You can only edit your own posts' };
    }
    
    # Update the post
    my $update_sth = $dbh->prepare(qq{
        UPDATE $table 
        SET title = ?,
            description = ?,
            price = ?,
            location = ?,
            contact_email = ?,
            contact_phone = ?,
            last_edited_at = CURRENT_TIMESTAMP
        WHERE id = ?
    });
    
    eval {
        $update_sth->execute(
            $data->{title},
            $data->{description},
            $data->{price},
            $data->{location},
            $data->{contact_email},
            $data->{contact_phone},
            $post_id
        );
    };
    
    if ($@) {
        return { error => "Failed to update post: $@" };
    }
    
    return { 
        success => 1, 
        message => 'Post updated successfully',
        post_id => $post_id,
        category => $category
    };
}

# Delete a post as owner (user only)
sub delete_own_post {
    my ($dbh, $category, $post_id, $user) = @_;
    
    my $table = get_table_for_category($dbh, $category);
    return { error => 'Category not found' } unless $table;
    
    # Check if post exists and belongs to user
    my $sth = $dbh->prepare("SELECT id, user_id FROM $table WHERE id = ?");
    $sth->execute($post_id);
    my $post = $sth->fetchrow_hashref;
    
    unless ($post) {
        return { error => 'Post not found' };
    }
    
    # Verify ownership
    unless ($post->{user_id} == $user->{id}) {
        return { error => 'You can only delete your own posts' };
    }
    
    # Delete the post
    my $delete_sth = $dbh->prepare("DELETE FROM $table WHERE id = ?");
    
    eval {
        $delete_sth->execute($post_id);
    };
    
    if ($@) {
        return { error => "Failed to delete post: $@" };
    }
    
    return { 
        success => 1, 
        message => 'Post deleted successfully',
        post_id => $post_id,
        category => $category
    };
}

# Send JSON response
sub send_json {
    my ($conn, $status, $data) = @_;
    my $json = encode_json($data);
    my $response = HTTP::Response->new($status);
    $response->header('Content-Type' => 'application/json');
    $response->header('Access-Control-Allow-Origin' => '*');
    $response->header('Access-Control-Allow-Methods' => 'GET, POST, PUT, DELETE, OPTIONS');
    $response->header('Access-Control-Allow-Headers' => 'Content-Type, Authorization');
    $response->content($json);
    $conn->send_response($response);
}

# Handle requests
while (my $conn = $daemon->accept) {
    my $client_ip = $conn->peerhost();
    
    while (my $request = $conn->get_request) {
        my $method = $request->method;
        my $path = $request->uri->path;
        my $uri = URI->new($request->uri);
        my %query = $uri->query_form;
        my $response_status = RC_OK;

        # Handle CORS preflight
        if ($method eq 'OPTIONS') {
            my $response = HTTP::Response->new(RC_OK);
            $response->header('Access-Control-Allow-Origin' => '*');
            $response->header('Access-Control-Allow-Methods' => 'GET, POST, PUT, DELETE, OPTIONS');
            $response->header('Access-Control-Allow-Headers' => 'Content-Type, Authorization');
            $conn->send_response($response);
            log_request($method, $path, RC_OK, $client_ip);
            next;
        }

        eval {
            my $dbh = get_db();

            # Route: POST /api/auth/signup
            if ($method eq 'POST' && $path eq '/api/auth/signup') {
                my $content = $request->content;
                my $data = decode_json($content);
                log_message('INFO', "Signup attempt for email: " . ($data->{email} || 'unknown'));
                my $result = create_user($dbh, $data);
                if ($result->{error}) {
                    log_message('WARN', "Signup failed: " . $result->{error});
                    $response_status = RC_BAD_REQUEST;
                    send_json($conn, RC_BAD_REQUEST, $result);
                } else {
                    log_message('INFO', "User created successfully: " . $data->{email});
                    $response_status = RC_CREATED;
                    send_json($conn, RC_CREATED, $result);
                }
            }
            # Route: POST /api/auth/login
            elsif ($method eq 'POST' && $path eq '/api/auth/login') {
                my $content = $request->content;
                my $data = decode_json($content);
                log_message('INFO', "Login attempt for email: " . ($data->{email} || 'unknown'));
                my $result = login_user($dbh, $data);
                if ($result->{error}) {
                    log_message('WARN', "Login failed for " . ($data->{email} || 'unknown') . ": " . $result->{error});
                    $response_status = RC_UNAUTHORIZED;
                    send_json($conn, RC_UNAUTHORIZED, $result);
                } else {
                    log_message('INFO', "Login successful for: " . $data->{email});
                    $response_status = RC_OK;
                    send_json($conn, RC_OK, $result);
                }
            }
            # Route: GET /api/categories
            elsif ($method eq 'GET' && $path eq '/api/categories') {
                my $categories = get_categories($dbh);
                $response_status = RC_OK;
                send_json($conn, RC_OK, $categories);
            }
            # Route: GET /api/listings/:category
            elsif ($method eq 'GET' && $path =~ m{^/api/listings/(\w+)$}) {
                my $category = $1;
                my $listings = get_listings_by_category($dbh, $category);
                if (defined $listings) {
                    $response_status = RC_OK;
                    send_json($conn, RC_OK, $listings);
                } else {
                    log_message('WARN', "Category not found: $category");
                    $response_status = RC_NOT_FOUND;
                    send_json($conn, RC_NOT_FOUND, { error => 'Category not found' });
                }
            }
            # Route: GET /api/:category/:id
            elsif ($method eq 'GET' && $path =~ m{^/api/(\w+)/(\d+)$}) {
                my ($category, $id) = ($1, $2);
                my $listing = get_listing_by_id($dbh, $category, $id);
                if ($listing) {
                    $response_status = RC_OK;
                    send_json($conn, RC_OK, $listing);
                } else {
                    log_message('WARN', "Listing not found: $category/$id");
                    $response_status = RC_NOT_FOUND;
                    send_json($conn, RC_NOT_FOUND, { error => 'Listing not found' });
                }
            }
            # Route: POST /api/listings/:category
            elsif ($method eq 'POST' && $path =~ m{^/api/listings/(\w+)$}) {
                # Verify authentication token
                my $token = get_token_from_header($request);
                my $user = verify_token($dbh, $token);
                
                unless ($user) {
                    log_message('WARN', "Unauthorized listing creation attempt for category: $1");
                    $response_status = RC_UNAUTHORIZED;
                    send_json($conn, RC_UNAUTHORIZED, { error => 'Authentication required. Please log in.' });
                    next;
                }
                
                my $category = $1;
                my $content = $request->content;
                my $data = decode_json($content);
                log_message('INFO', "User " . $user->{email} . " creating listing in: $category");
                my $result = create_listing($dbh, $category, $data, $user);
                if (defined $result) {
                    log_message('INFO', "Listing created in $category by " . $user->{email});
                    $response_status = RC_CREATED;
                    send_json($conn, RC_CREATED, $result);
                } else {
                    log_message('WARN', "Failed to create listing in $category - category not found");
                    $response_status = RC_NOT_FOUND;
                    send_json($conn, RC_NOT_FOUND, { error => 'Category not found' });
                }
            }
            # Route: PUT /api/posts/:category/:id - Update a post (user owner)
            elsif ($method eq 'PUT' && $path =~ m{^/api/posts/(\w+)/(\d+)$}) {
                # Verify authentication token
                my $token = get_token_from_header($request);
                my $user = verify_token($dbh, $token);
                
                unless ($user) {
                    log_message('WARN', "Unauthorized update attempt for $1/$2");
                    $response_status = RC_UNAUTHORIZED;
                    send_json($conn, RC_UNAUTHORIZED, { error => 'Authentication required. Please log in.' });
                    next;
                }
                
                my ($category, $post_id) = ($1, $2);
                my $content = $request->content;
                my $data = decode_json($content);
                
                log_message('INFO', "User " . $user->{email} . " updating post: $category/$post_id");
                my $result = update_post($dbh, $category, $post_id, $data, $user);
                
                if ($result->{error}) {
                    log_message('WARN', "Update failed for $category/$post_id: " . $result->{error});
                    $response_status = RC_BAD_REQUEST;
                    send_json($conn, RC_BAD_REQUEST, $result);
                } else {
                    log_message('INFO', "Post updated successfully: $category/$post_id");
                    $response_status = RC_OK;
                    send_json($conn, RC_OK, $result);
                }
            }
            # Route: DELETE /api/posts/:category/:id - Delete own post (user owner)
            elsif ($method eq 'DELETE' && $path =~ m{^/api/posts/(\w+)/(\d+)$}) {
                # Verify authentication token
                my $token = get_token_from_header($request);
                my $user = verify_token($dbh, $token);
                
                unless ($user) {
                    log_message('WARN', "Unauthorized delete attempt for $1/$2");
                    $response_status = RC_UNAUTHORIZED;
                    send_json($conn, RC_UNAUTHORIZED, { error => 'Authentication required. Please log in.' });
                    next;
                }
                
                my ($category, $post_id) = ($1, $2);
                
                log_message('INFO', "User " . $user->{email} . " deleting post: $category/$post_id");
                my $result = delete_own_post($dbh, $category, $post_id, $user);
                
                if ($result->{error}) {
                    log_message('WARN', "Delete failed for $category/$post_id: " . $result->{error});
                    $response_status = RC_BAD_REQUEST;
                    send_json($conn, RC_BAD_REQUEST, $result);
                } else {
                    log_message('INFO', "Post deleted successfully: $category/$post_id");
                    $response_status = RC_OK;
                    send_json($conn, RC_OK, $result);
                }
            }
            # Route: GET /api/admin/users - Get all users and their posts (admin/moderator)
            elsif ($method eq 'GET' && $path eq '/api/admin/users') {
                # Verify authentication token
                my $token = get_token_from_header($request);
                my $user = verify_token($dbh, $token);
                
                unless ($user) {
                    log_message('WARN', "Unauthorized admin access attempt");
                    $response_status = RC_UNAUTHORIZED;
                    send_json($conn, RC_UNAUTHORIZED, { error => 'Authentication required. Please log in.' });
                    next;
                }
                
                # Verify user has admin or moderator role
                unless ($user->{user_role} && ($user->{user_role} eq 'admin' || $user->{user_role} eq 'moderator')) {
                    log_message('WARN', "Forbidden admin access attempt by " . $user->{email});
                    $response_status = RC_FORBIDDEN;
                    send_json($conn, RC_FORBIDDEN, { error => 'Access denied. Administrator or moderator privileges required.' });
                    next;
                }
                
                # Get all users with their posts
                log_message('INFO', "Admin " . $user->{email} . " viewing all users");
                my $users = get_all_users_with_posts($dbh);
                $response_status = RC_OK;
                send_json($conn, RC_OK, $users);
            }
            # Route: POST /api/admin/posts/delete - Delete/redact a post (admin/moderator)
            elsif ($method eq 'POST' && $path eq '/api/admin/posts/delete') {
                # Verify authentication token
                my $token = get_token_from_header($request);
                my $user = verify_token($dbh, $token);
                
                unless ($user) {
                    log_message('WARN', "Unauthorized admin delete attempt");
                    $response_status = RC_UNAUTHORIZED;
                    send_json($conn, RC_UNAUTHORIZED, { error => 'Authentication required. Please log in.' });
                    next;
                }
                
                # Verify user has admin or moderator role
                unless ($user->{user_role} && ($user->{user_role} eq 'admin' || $user->{user_role} eq 'moderator')) {
                    log_message('WARN', "Forbidden admin delete attempt by " . $user->{email});
                    $response_status = RC_FORBIDDEN;
                    send_json($conn, RC_FORBIDDEN, { error => 'Access denied. Administrator or moderator privileges required.' });
                    next;
                }
                
                # Parse request body
                my $content = $request->content;
                my $data = decode_json($content);
                
                unless ($data->{category} && $data->{post_id}) {
                    log_message('WARN', "Admin delete missing parameters");
                    $response_status = RC_BAD_REQUEST;
                    send_json($conn, RC_BAD_REQUEST, { error => 'Category and post_id are required' });
                    next;
                }
                
                # Delete/redact the post
                log_message('INFO', "Admin " . $user->{email} . " deleting post: " . $data->{category} . "/" . $data->{post_id});
                my $result = delete_post($dbh, $data->{category}, $data->{post_id});
                
                if ($result->{error}) {
                    log_message('WARN', "Admin delete failed: " . $result->{error});
                    $response_status = RC_BAD_REQUEST;
                    send_json($conn, RC_BAD_REQUEST, $result);
                } else {
                    log_message('INFO', "Post deleted by admin: " . $data->{category} . "/" . $data->{post_id});
                    $response_status = RC_OK;
                    send_json($conn, RC_OK, $result);
                }
            }
            # 404 Not Found
            else {
                log_message('WARN', "404 Not Found: $method $path");
                $response_status = RC_NOT_FOUND;
                send_json($conn, RC_NOT_FOUND, { error => 'Not found' });
            }

            $dbh->disconnect();
        };
        if ($@) {
            log_message('ERROR', "Exception in $method $path: $@");
            $response_status = RC_INTERNAL_SERVER_ERROR;
            send_json($conn, RC_INTERNAL_SERVER_ERROR, { error => 'Internal server error' });
        }
        
        # Log the request
        log_request($method, $path, $response_status, $client_ip);
    }
    $conn->close;
    undef($conn);
}
