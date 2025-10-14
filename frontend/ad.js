// API Base URL
const API_BASE_URL = 'http://localhost:3000';

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
    
    // Clear previous messages
    messageDiv.innerHTML = '';
    
    // Validate category selection
    if (!category) {
        messageDiv.innerHTML = '<p style="color: red;">Please select a category!</p>';
        return;
    }
    
    try {
        const token = localStorage.getItem('token');
        
        if (!token) {
            messageDiv.innerHTML = '<p style="color: red;">You must be logged in to post an ad. <a href="login.html">Login here</a></p>';
            return;
        }
        
        const response = await fetch(`${API_BASE_URL}/api/listings/${category}`, {
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
            // Ad posted successfully
            messageDiv.innerHTML = '<p style="color: green;"><b>Ad posted successfully!</b> Redirecting to category page...</p>';
            
            // Clear the form
            document.getElementById('adForm').reset();
            
            // Redirect to the category page after 2 seconds
            setTimeout(() => {
                window.location.href = `category.html?category=${category}`;
            }, 2000);
        } else {
            // Failed to post ad
            messageDiv.innerHTML = `<p style="color: red;">Failed to post ad: ${data.error || 'Unknown error'}</p>`;
        }
    } catch (error) {
        console.error('Error posting ad:', error);
        messageDiv.innerHTML = `<p style="color: red;">Error: Could not connect to server. Make sure the backend is running.</p>`;
    }
});

// Initialize page
window.addEventListener('DOMContentLoaded', () => {
    populateUserInfo();
});
