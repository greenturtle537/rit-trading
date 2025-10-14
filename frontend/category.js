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

// Get category from URL parameter
function getCategoryFromURL() {
    const urlParams = new URLSearchParams(window.location.search);
    return urlParams.get('category');
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
    const now = new Date();
    const diffDays = Math.floor((now - date) / (1000 * 60 * 60 * 24));
    
    if (diffDays === 0) return 'today';
    if (diffDays === 1) return 'yesterday';
    if (diffDays < 7) return diffDays + ' days ago';
    
    return date.toLocaleDateString();
}

// Fetch listings from backend
async function fetchListings(category) {
    try {
        const response = await fetch(`${API_URL}/listings/${category}`);
        if (!response.ok) {
            throw new Error('Failed to fetch listings');
        }
        const listings = await response.json();
        return listings;
    } catch (error) {
        console.error('Error fetching listings:', error);
        throw error;
    }
}

// Render listings
function renderListings(listings) {
    const table = document.getElementById('listingsTable');
    table.innerHTML = '';
    
    if (listings.length === 0) {
        const row = document.createElement('tr');
        const cell = document.createElement('td');
        cell.textContent = 'no listings found in this category';
        row.appendChild(cell);
        table.appendChild(row);
        return;
    }
    
    listings.forEach(listing => {
        const row = document.createElement('tr');
        
        const cell = document.createElement('td');
        cell.style.borderBottom = '1px solid #ccc';
        cell.style.paddingBottom = '10px';
        cell.style.paddingTop = '10px';
        
        // Title and price
        const titleLine = document.createElement('div');
        const titleLink = document.createElement('a');
        titleLink.href = 'item.html?category=' + getCategoryFromURL() + '&id=' + listing.id;
        titleLink.innerHTML = '<b>' + listing.title + '</b>';
        titleLine.appendChild(titleLink);
        titleLine.innerHTML += ' - ' + formatPrice(listing.price);
        
        // Description (truncated)
        const descLine = document.createElement('div');
        const desc = listing.description || '';
        const truncDesc = desc.length > 100 ? desc.substring(0, 100) + '...' : desc;
        descLine.textContent = truncDesc;
        descLine.style.color = '#666';
        descLine.style.fontSize = '0.9em';
        descLine.style.marginTop = '5px';
        
        // Location and date
        const metaLine = document.createElement('div');
        metaLine.style.fontSize = '0.85em';
        metaLine.style.color = '#999';
        metaLine.style.marginTop = '5px';
        metaLine.innerHTML = '<i>' + (listing.location || 'location not specified') + ' - ' + formatDate(listing.created_at) + '</i>';
        
        cell.appendChild(titleLine);
        cell.appendChild(descLine);
        cell.appendChild(metaLine);
        
        row.appendChild(cell);
        table.appendChild(row);
    });
}

// Initialize page
async function init() {
    const category = getCategoryFromURL();
    
    if (!category) {
        document.getElementById('errorMessage').textContent = 'no category specified';
        document.getElementById('errorMessage').style.display = 'block';
        document.getElementById('loadingMessage').style.display = 'none';
        return;
    }
    
    // Set category name in header
    document.getElementById('categoryName').textContent = formatCategoryName(category);
    document.title = 'RIT Trading - ' + formatCategoryName(category);
    
    try {
        const listings = await fetchListings(category);
        document.getElementById('loadingMessage').style.display = 'none';
        renderListings(listings);
    } catch (error) {
        document.getElementById('loadingMessage').style.display = 'none';
        document.getElementById('errorMessage').textContent = 'error loading listings. make sure the backend server is running.';
        document.getElementById('errorMessage').style.display = 'block';
    }
}

// Run initialization when DOM is loaded
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
} else {
    init();
}
