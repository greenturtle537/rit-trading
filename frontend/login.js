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

// Handle Login Form Submission
document.getElementById('loginForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const email = document.getElementById('loginEmail').value;
    const password = document.getElementById('loginPassword').value;
    const messageDiv = document.getElementById('loginMessage');
    
    // Clear previous messages
    messageDiv.innerHTML = '';
    
    try {
        const response = await fetch(`${API_URL}/auth/login`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                email: email,
                password: password
            })
        });
        
        const data = await response.json();
        
        if (response.ok) {
            // Login successful
            messageDiv.innerHTML = '<p style="color: green;">Login successful! Redirecting...</p>';
            
            // Store user info (you might want to use sessionStorage or localStorage)
            if (data.user) {
                localStorage.setItem('user', JSON.stringify(data.user));
            }
            if (data.token) {
                localStorage.setItem('token', data.token);
            }
            
            // Redirect to home page after 1 second
            setTimeout(() => {
                window.location.href = 'index.html';
            }, 1000);
        } else {
            // Login failed
            messageDiv.innerHTML = `<p style="color: red;">Login failed: ${data.error || 'Unknown error'}</p>`;
        }
    } catch (error) {
        console.error('Login error:', error);
        messageDiv.innerHTML = `<p style="color: red;">Error: Could not connect to server. Make sure the backend is running.</p>`;
    }
});

// Handle Signup Form Submission
document.getElementById('signupForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const email = document.getElementById('signupEmail').value;
    const password = document.getElementById('signupPassword').value;
    const confirmPassword = document.getElementById('signupConfirmPassword').value;
    const name = document.getElementById('signupName').value;
    const messageDiv = document.getElementById('signupMessage');
    
    // Clear previous messages
    messageDiv.innerHTML = '';
    
    // Validate passwords match
    if (password !== confirmPassword) {
        messageDiv.innerHTML = '<p style="color: red;">Passwords do not match!</p>';
        return;
    }
    
    // Validate password length
    if (password.length < 6) {
        messageDiv.innerHTML = '<p style="color: red;">Password must be at least 6 characters long!</p>';
        return;
    }
    
    try {
        const response = await fetch(`${API_URL}/auth/signup`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                email: email,
                password: password,
                name: name
            })
        });
        
        const data = await response.json();
        
        if (response.ok) {
            // Signup successful
            messageDiv.innerHTML = '<p style="color: green;">Account created successfully! Redirecting to login...</p>';
            
            // Clear the form
            document.getElementById('signupForm').reset();
            
            // Optionally auto-login or redirect after a delay
            setTimeout(() => {
                // You could either auto-login here or just clear the message
                messageDiv.innerHTML = '<p style="color: green;">Please login with your new account.</p>';
                // Or redirect: window.location.href = 'index.html';
            }, 2000);
        } else {
            // Signup failed
            messageDiv.innerHTML = `<p style="color: red;">Signup failed: ${data.error || 'Unknown error'}</p>`;
        }
    } catch (error) {
        console.error('Signup error:', error);
        messageDiv.innerHTML = `<p style="color: red;">Error: Could not connect to server. Make sure the backend is running.</p>`;
    }
});

// Check if user is already logged in
window.addEventListener('DOMContentLoaded', () => {
    const user = localStorage.getItem('user');
    if (user) {
        const userData = JSON.parse(user);
        document.body.insertAdjacentHTML('afterbegin', 
            `<p style="background-color: #ffffcc; padding: 10px;">You are already logged in as ${userData.email}. <a href="#" onclick="logout(); return false;">Logout</a></p>`
        );
    }
});

// Logout function
function logout() {
    localStorage.removeItem('user');
    localStorage.removeItem('token');
    window.location.reload();
}
