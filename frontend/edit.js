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
        const response = await fetchWithRetry(`${API_URL}/${category}/${postId}`);
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
        document.getElementById('message').innerHTML = '<p style="color: red;">Error loading post after multiple attempts. Please try again.</p>';
    }
}

// Handle form submission
document.getElementById('postForm').addEventListener('submit', async function(e) {
    e.preventDefault();
    
    const token = localStorage.getItem('token');
    if (!token) {
        alert('You must be logged in to edit posts');
        window.location.replace('login.html');
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

    const submitButton = e.target.querySelector('button[type="submit"]');
    const messageDiv = document.getElementById('message');
    
    // Disable submit button and show loading state
    if (submitButton) {
        submitButton.disabled = true;
        submitButton.style.opacity = '0.5';
        submitButton.style.cursor = 'not-allowed';
        const originalText = submitButton.textContent;
        submitButton.textContent = 'Saving...';
        submitButton.dataset.originalText = originalText;
    }
    
    messageDiv.innerHTML = '<p style="color: blue;">Saving changes...</p>';

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
            messageDiv.innerHTML = '<p style="color: green;">Changes saved! Redirecting...</p>';
            // Redirect back to the post view immediately to show updates
            setTimeout(() => {
                window.location.replace(`item.html?category=${category}&id=${postId}`);
            }, 1000);
        } else {
            messageDiv.innerHTML = `<p style="color: red;">Error: ${result.error || 'Failed to update post'}</p>`;
            
            // Re-enable submit button
            if (submitButton) {
                submitButton.disabled = false;
                submitButton.style.opacity = '1';
                submitButton.style.cursor = 'pointer';
                submitButton.textContent = submitButton.dataset.originalText || 'Save Changes';
            }
        }
    } catch (error) {
        console.error('Error updating post:', error);
        messageDiv.innerHTML = '<p style="color: red;">Error updating post. Please try again.</p>';
        
        // Re-enable submit button
        if (submitButton) {
            submitButton.disabled = false;
            submitButton.style.opacity = '1';
            submitButton.style.cursor = 'pointer';
            submitButton.textContent = submitButton.dataset.originalText || 'Save Changes';
        }
    }
});

// Handle cancel button
document.getElementById('cancelButton').addEventListener('click', function() {
    // Go back to the post view without saving
    window.location.replace(`item.html?category=${category}&id=${postId}`);
});

// Load post data when page loads
loadPost();
