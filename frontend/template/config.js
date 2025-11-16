// Configuration file for API endpoints and other settings
window.APP_CONFIG = {
    // Razorpay configuration
    RAZORPAY_KEY: '${RAZORPAY_KEY}',
    
    // Other configurable settings
    COMPANY_NAME: '${COMPANY_NAME}',
    CURRENCY: '${CURRENCY}'
};

// Helper function to get API URL
window.getApiUrl = function(service, endpoint) {
    return `${window.location.origin}${endpoint}`;
};

// Helper function to get config value
window.getConfig = function(key) {
    return window.APP_CONFIG[key];
};
