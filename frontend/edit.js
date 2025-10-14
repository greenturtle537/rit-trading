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

// Get URL parameters
const urlParams = new URLSearchParams(window.location.search);
const category = urlParams.get('category');
const postId = urlParams.get('id');

// Load post data
async function loadPost() {
    if (!category || !postId) {
        document.getElementById('message').innerHTML = '<p style="color: red;">Error: Missing category or post ID</p>';
        return;
    }

    try {
        const response = await fetch(`${API_URL}/${category}/${postId}`);
        if (!response.ok) {
            throw new Error('Failed to load post');
        }

        const post = await response.json();
        
        // Populate form fields
        document.getElementById('title').value = post.title || '';
        document.getElementById('description').value = post.description || '';
        document.getElementById('price').value = post.price || '';
        document.getElementById('location').value = post.location || '';
        document.getElementById('contact_email').value = post.contact_email || '';
        document.getElementById('contact_phone').value = post.contact_phone || '';
        
    } catch (error) {
        console.error('Error loading post:', error);
        document.getElementById('message').innerHTML = '<p style="color: red;">Error loading post. Please try again.</p>';
    }
}

// Handle form submission
document.getElementById('postForm').addEventListener('submit', async function(e) {
    e.preventDefault();
    
    const token = localStorage.getItem('token');
    if (!token) {
        alert('You must be logged in to edit posts');
        window.location.href = 'login.html';
        return;
    }

    const formData = {
        title: document.getElementById('title').value,
        description: document.getElementById('description').value,
        price: parseFloat(document.getElementById('price').value) || 0,
        location: document.getElementById('location').value,
        contact_email: document.getElementById('contact_email').value,
        contact_phone: document.getElementById('contact_phone').value
    };

    try {
        const response = await fetch(`${API_URL}/posts/${category}/${postId}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify(formData)
        });

        const result = await response.json();

        if (response.ok && result.success) {
            // Redirect back to the post view immediately to show updates
            window.location.href = `item.html?category=${category}&id=${postId}`;
        } else {
            document.getElementById('message').innerHTML = `<p style="color: red;">Error: ${result.error || 'Failed to update post'}</p>`;
        }
    } catch (error) {
        console.error('Error updating post:', error);
        document.getElementById('message').innerHTML = '<p style="color: red;">Error updating post. Please try again.</p>';
    }
});

// Handle cancel button
document.getElementById('cancelButton').addEventListener('click', function() {
    // Go back to the post view without saving
    window.location.href = `item.html?category=${category}&id=${postId}`;
});

// Load post data when page loads
loadPost();
