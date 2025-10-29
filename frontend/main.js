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
    // Show loading message
    const loadingDiv = document.getElementById('loadingMessage');
    const errorDiv = document.getElementById('errorMessage');
    
    if (loadingDiv) loadingDiv.style.display = 'block';
    if (errorDiv) errorDiv.style.display = 'none';
    
    checkUserAuth();
    await fetchCategories();
    renderCategories();
    
    // Hide loading message once complete
    if (loadingDiv) loadingDiv.style.display = 'none';
}

// Fetch categories from backend
async function fetchCategories() {
    try {
        const response = await fetchWithRetry(`${API_URL}/categories`);
        categories = await response.json();
        console.log('Categories loaded:', categories);
        
        // Clear any error messages
        const errorDiv = document.getElementById('errorMessage');
        if (errorDiv) errorDiv.style.display = 'none';
    } catch (error) {
        console.error('Error fetching categories:', error);
        
        // Show error message
        const errorDiv = document.getElementById('errorMessage');
        if (errorDiv) {
            errorDiv.textContent = 'Error loading categories. Please refresh the page to try again.';
            errorDiv.style.display = 'block';
        }
        
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

// Render categories in three columns
function renderCategories() {
    // Organize categories into three groups based on their purpose
    const forSale = [];
    const services = [];
    const lookingFor = [];
    
    categories.forEach(category => {
        const name = category.name.toLowerCase();
        const tableName = category.table_name.toLowerCase();
        
        // Categorize based on name patterns
        if (name.includes('looking for') || name.includes('wanted') || tableName.includes('looking') || tableName.includes('wanted')) {
            lookingFor.push(category);
        } else if (name.includes('service') || name.includes('hire') || name.includes('tutor') || tableName.includes('service') || tableName.includes('hire')) {
            services.push(category);
        } else {
            // Default to "for sale"
            forSale.push(category);
        }
    });
    
    populateColumn('forSaleTable', forSale);
    populateColumn('servicesTable', services);
    populateColumn('lookingForTable', lookingFor);
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
