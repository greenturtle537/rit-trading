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

// Check if user is logged in
function checkLogin() {
    const user = localStorage.getItem('user');
    if (!user) {
        // User is not logged in, show warning and disable form
        document.getElementById('loginWarning').style.display = 'block';
        document.getElementById('adForm').style.display = 'none';
        return null;
    }
    return JSON.parse(user);
}

// Populate contact email with logged-in user's email
function populateUserInfo() {
    const user = checkLogin();
    if (user) {
        // Pre-fill email with user's email
        document.getElementById('contactEmail').value = user.email;
    }
}

// Handle Ad Form Submission
document.getElementById('adForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const category = document.getElementById('category').value;
    const title = document.getElementById('title').value;
    const description = document.getElementById('description').value;
    const price = document.getElementById('price').value;
    const location = document.getElementById('location').value;
    const contactEmail = document.getElementById('contactEmail').value;
    const contactPhone = document.getElementById('contactPhone').value;
    const messageDiv = document.getElementById('adMessage');
    const submitButton = e.target.querySelector('button[type="submit"]');
    
    // Clear previous messages
    messageDiv.innerHTML = '';
    
    // Validate category selection
    if (!category) {
        messageDiv.innerHTML = '<p style="color: red;">Please select a category!</p>';
        return;
    }
    
    // Disable submit button and show loading state
    if (submitButton) {
        submitButton.disabled = true;
        submitButton.style.opacity = '0.5';
        submitButton.style.cursor = 'not-allowed';
        const originalText = submitButton.textContent;
        submitButton.textContent = 'Posting...';
        submitButton.dataset.originalText = originalText;
    }
    
    messageDiv.innerHTML = '<p style="color: blue;">Posting ad...</p>';
    
    try {
        const token = localStorage.getItem('token');
        
        if (!token) {
            messageDiv.innerHTML = '<p style="color: red;">You must be logged in to post an ad. <a href="login.html">Login here</a></p>';
            return;
        }
        
        const response = await fetch(`${API_URL}/listings/${category}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({
                title: title,
                description: description,
                price: price || 0,  // Default to 0 if empty
                location: location,
                contact_email: contactEmail,
                contact_phone: contactPhone
            })
        });
        
        const data = await response.json();
        
        if (response.ok) {
            // Clear the form first
            document.getElementById('adForm').reset();
            
            // Redirect to the newly posted ad
            if (data.id) {
                window.location.replace(`item.html?category=${category}&id=${data.id}`);
            } else {
                // Fallback to category page if ID is not available
                window.location.replace(`category.html?category=${category}`);
            }
        } else {
            // Failed to post ad
            messageDiv.innerHTML = `<p style="color: red;">Failed to post ad: ${data.error || 'Unknown error'}</p>`;
            
            // Re-enable submit button
            if (submitButton) {
                submitButton.disabled = false;
                submitButton.style.opacity = '1';
                submitButton.style.cursor = 'pointer';
                submitButton.textContent = submitButton.dataset.originalText || 'Post Ad';
            }
        }
    } catch (error) {
        console.error('Error posting ad:', error);
        messageDiv.innerHTML = `<p style="color: red;">Error: Could not connect to server. Please try again.</p>`;
        
        // Re-enable submit button
        if (submitButton) {
            submitButton.disabled = false;
            submitButton.style.opacity = '1';
            submitButton.style.cursor = 'pointer';
            submitButton.textContent = submitButton.dataset.originalText || 'Post Ad';
        }
    }
});

// Initialize page
window.addEventListener('DOMContentLoaded', () => {
    populateUserInfo();
});
