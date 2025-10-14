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
        const response = await fetch(`${API_URL}/${category}/${id}`);
        if (!response.ok) {
            throw new Error('Failed to fetch listing');
        }
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
    
    document.getElementById('listingDetails').style.display = 'block';
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
    document.getElementById('backToListings').href = '/trading/category?category=' + params.category;
    
    try {
        const listing = await fetchListing(params.category, params.id);
        document.getElementById('loadingMessage').style.display = 'none';
        renderListing(listing, params.category);
        document.title = listing.title + ' - RIT Trading';
    } catch (error) {
        document.getElementById('loadingMessage').style.display = 'none';
        document.getElementById('errorMessage').textContent = 'error loading listing. make sure the backend server is running.';
        document.getElementById('errorMessage').style.display = 'block';
    }
}

// Run initialization when DOM is loaded
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}
