# Edit and Delete Post Features

## Overview
Users can now edit and delete their own posts. The system tracks post ownership via `user_id` and only allows modifications by the original poster.

## Database Changes

### Schema Updates (`schema-structure.sql`)
- Added `last_edited_at DATETIME` column to all 14 listing tables
- This timestamp is updated when a user edits their post
- Original `created_at` timestamp remains unchanged

## Backend API Changes (`server.pl`)

### New Functions

1. **`update_post($dbh, $category, $post_id, $data, $user)`**
   - Updates a post's content
   - Verifies user owns the post
   - Sets `last_edited_at` to current timestamp
   - Returns error if user doesn't own the post

2. **`delete_own_post($dbh, $category, $post_id, $user)`**
   - Deletes a post permanently
   - Verifies user owns the post
   - Returns error if user doesn't own the post

### New API Endpoints

1. **PUT `/api/posts/:category/:id`**
   - Update a post
   - Requires authentication
   - Only owner can update
   - Request body: `{ title, description, price, location, contact_email, contact_phone }`

2. **DELETE `/api/posts/:category/:id`**
   - Delete a post
   - Requires authentication
   - Only owner can delete
   - Shows confirmation dialog before deletion

### Updated CORS Headers
- Added `PUT` and `DELETE` to allowed methods

## Frontend Changes

### New Files

1. **`edit.html`**
   - Edit post form
   - Pre-populated with existing post data
   - Save/Cancel buttons

2. **`edit.js`**
   - Loads post data from API
   - Handles form submission (PUT request)
   - Redirects back to post view on success/cancel

### Updated Files

1. **`item.js`**
   - Shows "Edit Post" and "Delete Post" buttons for post owners
   - Compares `listing.user_id` with logged-in user's ID
   - Delete button shows confirmation dialog
   - Displays "Last edited" timestamp if post was edited

## User Flow

### Editing a Post
1. User views their own post on `item.html`
2. "Edit Post" button appears for owned posts
3. Click "Edit Post" → redirects to `edit.html`
4. Form is pre-populated with current values
5. User makes changes and clicks "Save Changes"
6. PUT request sent to API
7. On success, redirected back to `item.html` with updated content
8. "Last edited" timestamp displayed

### Deleting a Post
1. User views their own post on `item.html`
2. "Delete Post" button appears for owned posts
3. Click "Delete Post" → confirmation dialog appears
4. User confirms deletion
5. DELETE request sent to API
6. Post is permanently removed from database
7. User redirected to category page

## Security Features

✅ Authentication required for edit/delete operations  
✅ Ownership verification (user_id must match)  
✅ Confirmation dialog before deletion  
✅ Separate endpoints from admin moderation  
✅ Original timestamp preserved on edits  

## Testing

To test these features:
1. Initialize the database: `cd backend && ./deploy.sh test`
2. Login as `sam@glitchtech.top` (password: `password123`)
3. View any test post - you should see Edit/Delete buttons
4. Test editing a post
5. Test deleting a post
6. Verify non-owners cannot see these buttons
