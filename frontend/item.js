// Backend API configuration
// Auto-detects environment: Live Server (dev), Apache (prod), or direct Perl server
function getApiUrl() {
    const hostname = window.location.hostname;
    const port = window.location.port;
    
    // Check if backend is accessible (for Live Server or file:// protocol)
    // Live Server typically runs on port 5500, 5501, etc.
    if (port && port !== '80' && port !== '443') {
        // Development with Live Server or direct file access
        return 'http://localhost:3000/api';
    }
    
    // Production with Apache (standard HTTP/HTTPS ports or no port)
    return '/trading/api';
}

const API_URL = getApiUrl();

// Utility function to fetch with retry logic
async function fetchWithRetry(url, options = {}, maxRetries = 5) {
    let lastError;
    
    for (let attempt = 1; attempt <= maxRetries; attempt++) {
        try {
            const response = await fetch(url, options);
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            return response;
        } catch (error) {
            lastError = error;
            console.warn(`Fetch attempt ${attempt} failed:`, error.message);
            
            if (attempt < maxRetries) {
                // Wait before retrying (exponential backoff)
                const delay = Math.min(1000 * Math.pow(2, attempt - 1), 5000);
                await new Promise(resolve => setTimeout(resolve, delay));
            }
        }
    }
    
    throw lastError;
}

// Get parameters from URL
function getURLParams() {
    const urlParams = new URLSearchParams(window.location.search);
    return {
        category: urlParams.get('category'),
        id: urlParams.get('id')
    };
}

// Format category name for display
function formatCategoryName(name) {
    return name.replace(/_/g, ' & ');
}

// Format price
function formatPrice(price) {
    if (price == 0) {
        return 'FREE';
    }
    return '$' + parseFloat(price).toFixed(2);
}

// Format date
function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
}

// Fetch listing from backend
async function fetchListing(category, id) {
    try {
        const response = await fetchWithRetry(`${API_URL}/${category}/${id}`);
        const listing = await response.json();
        return listing;
    } catch (error) {
        console.error('Error fetching listing:', error);
        throw error;
    }
}

// Render listing details
function renderListing(listing, category) {
    document.getElementById('listingTitle').textContent = listing.title;
    document.getElementById('listingPrice').textContent = formatPrice(listing.price);
    document.getElementById('listingLocation').textContent = listing.location || 'not specified';
    document.getElementById('listingDate').textContent = formatDate(listing.created_at);
    document.getElementById('listingDescription').textContent = listing.description || 'no description provided';
    document.getElementById('listingEmail').textContent = listing.contact_email || 'not provided';
    
    if (listing.contact_phone) {
        document.getElementById('listingPhone').textContent = listing.contact_phone;
        document.getElementById('listingPhoneContainer').style.display = 'block';
    }
    
    // Show last edited time if available
    if (listing.last_edited_at) {
        const editedDiv = document.createElement('p');
        editedDiv.innerHTML = `<small><i>Last edited: ${formatDate(listing.last_edited_at)}</i></small>`;
        document.getElementById('listingDetails').appendChild(editedDiv);
    }
    
    // Check if current user owns this post
    const user = localStorage.getItem('user');
    if (user) {
        try {
            const userData = JSON.parse(user);
            if (listing.user_id && userData.id && listing.user_id === userData.id) {
                // User owns this post, show edit/delete buttons
                showOwnerButtons(category, listing.id);
            }
        } catch (e) {
            console.error('Error parsing user data:', e);
        }
    }
    
    document.getElementById('listingDetails').style.display = 'block';
}

// Show edit/delete buttons for post owner
function showOwnerButtons(category, postId) {
    const buttonsDiv = document.createElement('div');
    buttonsDiv.style.marginTop = '20px';
    buttonsDiv.innerHTML = `
        <button type="button" id="editButton" onclick="editPost('${category}', ${postId})">Edit Post</button>
        <button type="button" id="deleteButton" onclick="deletePost('${category}', ${postId})">Delete Post</button>
    `;
    document.getElementById('listingDetails').appendChild(buttonsDiv);
}

// Edit post
function editPost(category, postId) {
    window.location.replace(`edit.html?category=${category}&id=${postId}`);
}

// Delete post
async function deletePost(category, postId) {
    if (!confirm('Are you sure you want to delete this post? This action cannot be undone.')) {
        return;
    }
    
    const token = localStorage.getItem('token');
    if (!token) {
        alert('You must be logged in to delete posts');
        window.location.replace('login.html');
        return;
    }

    const deleteButton = document.getElementById('deleteButton');
    
    // Disable delete button and show loading state
    if (deleteButton) {
        deleteButton.disabled = true;
        deleteButton.style.opacity = '0.5';
        deleteButton.style.cursor = 'not-allowed';
        const originalText = deleteButton.textContent;
        deleteButton.textContent = 'Deleting...';
        deleteButton.dataset.originalText = originalText;
    }

    try {
        const response = await fetch(`${API_URL}/posts/${category}/${postId}`, {
            method: 'DELETE',
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        const result = await response.json();

        if (response.ok && result.success) {
            alert('Post deleted successfully!');
            // Redirect to homepage
            window.location.replace('index.html');
        } else {
            alert('Error: ' + (result.error || 'Failed to delete post'));
            
            // Re-enable delete button
            if (deleteButton) {
                deleteButton.disabled = false;
                deleteButton.style.opacity = '1';
                deleteButton.style.cursor = 'pointer';
                deleteButton.textContent = deleteButton.dataset.originalText || 'Delete Post';
            }
        }
    } catch (error) {
        console.error('Error deleting post:', error);
        alert('Error deleting post. Please try again.');
        
        // Re-enable delete button
        if (deleteButton) {
            deleteButton.disabled = false;
            deleteButton.style.opacity = '1';
            deleteButton.style.cursor = 'pointer';
            deleteButton.textContent = deleteButton.dataset.originalText || 'Delete Post';
        }
    }
}

// Initialize page
async function init() {
    const params = getURLParams();
    
    if (!params.category || !params.id) {
        document.getElementById('errorMessage').textContent = 'invalid listing';
        document.getElementById('errorMessage').style.display = 'block';
        document.getElementById('loadingMessage').style.display = 'none';
        return;
    }
    
    // Set category name in header
    document.getElementById('categoryName').textContent = formatCategoryName(params.category);
    
    // Set back to listings link
    document.getElementById('backToListings').href = 'category.html?category=' + params.category;
    
    try {
        const listing = await fetchListing(params.category, params.id);
        document.getElementById('loadingMessage').style.display = 'none';
        renderListing(listing, params.category);
        document.title = listing.title + ' - RIT Trading';
    } catch (error) {
        document.getElementById('loadingMessage').style.display = 'none';
        document.getElementById('errorMessage').textContent = 'Error loading listing after multiple attempts. Please refresh the page to try again.';
        document.getElementById('errorMessage').style.display = 'block';
    }
}

// Run initialization when DOM is loaded
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}
