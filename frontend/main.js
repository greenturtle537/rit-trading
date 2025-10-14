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

// Category data - will be fetched from backend
let categories = [];

// Check user authentication and role
function checkUserAuth() {
    const user = localStorage.getItem('user');
    
    if (user) {
        try {
            const userData = JSON.parse(user);
            
            // Update login button to show user's name
            const loginButton = document.getElementById('loginButton');
            if (loginButton) {
                loginButton.textContent = 'Logout';
                loginButton.onclick = function() {
                    localStorage.removeItem('user');
                    localStorage.removeItem('token');
                    window.location.reload();
                    return false;
                };
            }
            
            // Show welcome message
            const welcomeSpan = document.getElementById('userWelcome');
            if (welcomeSpan) {
                welcomeSpan.textContent = `Welcome, ${userData.name}!`;
            }
            
            // Show admin button if user is admin or moderator
            if (userData.role === 'admin' || userData.role === 'moderator') {
                const adminButtonLink = document.querySelector('a[href="admin.html"]');
                if (adminButtonLink) {
                    adminButtonLink.style.display = 'inline';
                }
            }
        } catch (e) {
            console.error('Error parsing user data:', e);
        }
    }
}

// Initialize the page
async function init() {
    checkUserAuth();
    await fetchCategories();
    renderCategories();
}

// Fetch categories from backend
async function fetchCategories() {
    try {
        const response = await fetch(`${API_URL}/categories`);
        if (!response.ok) {
            throw new Error('Failed to fetch categories');
        }
        categories = await response.json();
        console.log('Categories loaded:', categories);
    } catch (error) {
        console.error('Error fetching categories:', error);
        // Fallback to hardcoded categories if backend is down
        categories = [
            { name: 'electronics', table_name: 'electronics', listing_count: 0 },
            { name: 'furniture', table_name: 'furniture', listing_count: 0 },
            { name: 'cars & trucks', table_name: 'cars_trucks', listing_count: 0 },
            { name: 'books', table_name: 'books', listing_count: 0 },
            { name: 'free stuff', table_name: 'free_stuff', listing_count: 0 }
        ];
    }
}

// Render categories in one column
function renderCategories() {
    populateColumn('categoryTable', categories);
}

// Populate a table column with categories
function populateColumn(tableId, categoriesForColumn) {
    const table = document.getElementById(tableId);
    table.innerHTML = '';
    
    categoriesForColumn.forEach(category => {
        const row = document.createElement('tr');
        const cell = document.createElement('td');
        
        const link = document.createElement('a');
        // Use table_name for the URL parameter
        link.href = 'category.html?category=' + category.table_name;
        link.textContent = category.name + ' (' + category.listing_count + ')';
        
        cell.appendChild(link);
        row.appendChild(cell);
        table.appendChild(row);
    });
}

// Format category name for display
function formatCategoryName(name) {
    // Already formatted from the database
    return name;
}

// Run initialization when DOM is loaded
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}
