// Backend API configuration
function getApiUrl() {
    const hostname = window.location.hostname;
    const port = window.location.port;
    
    if (port && port !== '80' && port !== '443') {
        return 'http://localhost:3000/api';
    }
    
    return '/trading/api';
}

const API_URL = getApiUrl();

// Check authentication and admin access on page load
async function checkAdminAccess() {
    const user = localStorage.getItem('user');
    const token = localStorage.getItem('token');
    
    if (!user || !token) {
        showError('You must be logged in to access this page.');
        setTimeout(() => {
            window.location.href = 'login.html';
        }, 2000);
        return false;
    }
    
    const userData = JSON.parse(user);
    
    // Check if user has admin or moderator role
    if (userData.role !== 'admin' && userData.role !== 'moderator') {
        showError('Access denied. You must be an administrator or moderator to view this page.');
        setTimeout(() => {
            window.location.href = 'index.html';
        }, 2000);
        return false;
    }
    
    // Display admin name with role
    const roleDisplay = userData.role === 'admin' ? 'Admin' : 'Moderator';
    document.getElementById('adminName').textContent = `Logged in as: ${userData.name} (${roleDisplay})`;
    
    return true;
}

// Show error message
function showError(message) {
    const errorDiv = document.getElementById('errorMessage');
    errorDiv.textContent = message;
    errorDiv.style.display = 'block';
    document.getElementById('loadingMessage').style.display = 'none';
}

// Fetch all users and their posts
async function fetchAllUsersAndPosts() {
    const token = localStorage.getItem('token');
    
    try {
        const response = await fetch(`${API_URL}/admin/users`, {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            }
        });
        
        if (!response.ok) {
            const error = await response.json();
            throw new Error(error.error || 'Failed to fetch users');
        }
        
        const users = await response.json();
        displayUsers(users);
        
    } catch (error) {
        console.error('Error fetching users:', error);
        showError(`Error: ${error.message}. Make sure the backend server is running.`);
    }
}

// Display users and their posts
function displayUsers(users) {
    document.getElementById('loadingMessage').style.display = 'none';
    const container = document.getElementById('usersContainer');
    container.innerHTML = '';
    
    if (!users || users.length === 0) {
        container.innerHTML = '<p class="no-posts">No users found in the system.</p>';
        return;
    }
    
    users.forEach(user => {
        const userCard = document.createElement('div');
        userCard.className = 'user-card';
        
        // User header
        const userHeader = document.createElement('div');
        userHeader.className = 'user-header';
        userHeader.textContent = `User #${user.id} - ${user.name}`;
        userCard.appendChild(userHeader);
        
        // User information
        const userInfo = document.createElement('div');
        userInfo.className = 'user-info';
        userInfo.innerHTML = `
            <div><strong>Email:</strong> ${user.email}</div>
            <div><strong>Role:</strong> ${user.user_role}</div>
            <div><strong>Joined:</strong> ${formatDate(user.created_at)}</div>
        `;
        userCard.appendChild(userInfo);
        
        // Posts section
        const postsSection = document.createElement('div');
        postsSection.className = 'posts-section';
        
        const postsHeader = document.createElement('h3');
        postsHeader.textContent = `Posts (${user.posts ? user.posts.length : 0})`;
        postsSection.appendChild(postsHeader);
        
        if (user.posts && user.posts.length > 0) {
            user.posts.forEach(post => {
                const postItem = document.createElement('div');
                postItem.className = 'post-item';
                postItem.id = `post-${post.category}-${post.id}`;
                
                // Check if post is deleted
                const isDeleted = post.title === '[DELETED]' || post.description === 'This post was deleted by moderation';
                if (isDeleted) {
                    postItem.classList.add('deleted');
                }
                
                const deletedBadge = isDeleted ? '<span class="deleted-badge">DELETED</span>' : '';
                
                postItem.innerHTML = `
                    ${!isDeleted ? `<button class="delete-post-btn" onclick="deletePost('${post.category}', ${post.id})">Delete Post</button>` : ''}
                    <div>
                        <span class="post-category">${formatCategoryName(post.category)}</span>
                        <strong>${post.title}</strong>
                        ${deletedBadge}
                    </div>
                    <div style="margin-top: 5px; color: #666;">${post.description || 'No description'}</div>
                    <div style="margin-top: 5px; font-size: 14px;">
                        <strong>Price:</strong> $${post.price || 'N/A'} | 
                        <strong>Location:</strong> ${post.location || 'N/A'} | 
                        <strong>Posted:</strong> ${formatDate(post.created_at)}
                    </div>
                    <div style="margin-top: 5px; font-size: 14px;">
                        <strong>Contact:</strong> ${post.contact_email || 'N/A'}
                        ${post.contact_phone ? ` | ${post.contact_phone}` : ''}
                    </div>
                `;
                
                postsSection.appendChild(postItem);
            });
        } else {
            const noPosts = document.createElement('p');
            noPosts.className = 'no-posts';
            noPosts.textContent = 'This user has not created any posts yet.';
            postsSection.appendChild(noPosts);
        }
        
        userCard.appendChild(postsSection);
        container.appendChild(userCard);
    });
}

// Format category name for display
function formatCategoryName(tableName) {
    if (!tableName) return 'Unknown';
    
    // Convert table_name to display name
    const nameMap = {
        'electronics': 'Electronics',
        'furniture': 'Furniture',
        'cars_trucks': 'Cars & Trucks',
        'books': 'Books',
        'free_stuff': 'Free Stuff'
    };
    
    return nameMap[tableName] || tableName.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
}

// Format date for display
function formatDate(dateString) {
    if (!dateString) return 'N/A';
    
    const date = new Date(dateString);
    const options = { 
        year: 'numeric', 
        month: 'short', 
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    };
    
    return date.toLocaleDateString('en-US', options);
}

// Logout function
function logout() {
    localStorage.removeItem('user');
    localStorage.removeItem('token');
    window.location.href = 'index.html';
}

// Delete a post (admin only)
async function deletePost(category, postId) {
    // Confirm deletion
    if (!confirm('Are you sure you want to delete this post? This will redact all post content and mark it as deleted by moderation.')) {
        return;
    }
    
    const token = localStorage.getItem('token');
    
    try {
        // Disable the delete button
        const postElement = document.getElementById(`post-${category}-${postId}`);
        const deleteBtn = postElement.querySelector('.delete-post-btn');
        if (deleteBtn) {
            deleteBtn.disabled = true;
            deleteBtn.textContent = 'Deleting...';
        }
        
        const response = await fetch(`${API_URL}/admin/posts/delete`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                category: category,
                post_id: postId
            })
        });
        
        const result = await response.json();
        
        if (response.ok) {
            // Successfully deleted - update the UI
            if (postElement) {
                postElement.classList.add('deleted');
                
                // Update the post content to show it's deleted
                const titleElement = postElement.querySelector('strong');
                const descElement = postElement.querySelector('div[style*="color: #666"]');
                const priceElement = postElement.querySelector('div[style*="font-size: 14px"]');
                
                if (titleElement) {
                    titleElement.textContent = '[DELETED]';
                    titleElement.insertAdjacentHTML('afterend', '<span class="deleted-badge">DELETED</span>');
                }
                if (descElement) {
                    descElement.textContent = 'This post was deleted by moderation';
                }
                if (priceElement) {
                    priceElement.innerHTML = '<strong>Price:</strong> $0 | <strong>Location:</strong> N/A | <strong>Posted:</strong> ' + 
                        priceElement.innerHTML.split('Posted:</strong> ')[1];
                }
                
                // Remove the delete button
                if (deleteBtn) {
                    deleteBtn.remove();
                }
            }
            
            alert('Post has been successfully deleted and redacted.');
        } else {
            // Error deleting
            alert(`Failed to delete post: ${result.error || 'Unknown error'}`);
            
            // Re-enable the button
            if (deleteBtn) {
                deleteBtn.disabled = false;
                deleteBtn.textContent = 'Delete Post';
            }
        }
    } catch (error) {
        console.error('Error deleting post:', error);
        alert('Error: Could not connect to server. Make sure the backend is running.');
        
        // Re-enable the button
        const postElement = document.getElementById(`post-${category}-${postId}`);
        const deleteBtn = postElement?.querySelector('.delete-post-btn');
        if (deleteBtn) {
            deleteBtn.disabled = false;
            deleteBtn.textContent = 'Delete Post';
        }
    }
}

// Initialize page
async function init() {
    const hasAccess = await checkAdminAccess();
    if (hasAccess) {
        await fetchAllUsersAndPosts();
    }
}

// Run initialization when DOM is loaded
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}
